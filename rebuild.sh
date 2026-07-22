#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" ~/.dotfiles

# Guard: .agents/ must hold real skill content, never symlinks into agent skill dirs
# (that recreates the closed loop home-manager projects outward from .agents/).
if [[ -d "$DIR/.agents" ]]; then
  while IFS= read -r -d '' entry; do
    if [[ -L "$entry" ]]; then
      echo "ERROR: $entry is a symlink — refusing rebuild." >&2
      echo "  Skills under .agents/ must be real files/dirs (source of truth)." >&2
      echo "  Fix: git checkout HEAD -- .agents/" >&2
      exit 1
    fi
  done < <(/usr/bin/find "$DIR/.agents" -mindepth 1 -maxdepth 1 -print0)
  if /usr/bin/find "$DIR/.agents" -type l | grep -q .; then
    echo "ERROR: symlink(s) inside .agents/ — refusing rebuild (HM would corrupt source)." >&2
    /usr/bin/find "$DIR/.agents" -type l -print >&2
    exit 1
  fi
fi

# CRITICAL: remove prior ~/.*/skills projections BEFORE home-manager activates.
# If those paths are still out-of-store symlinks into .agents/, HM force+recursive
# follows them and writes store links INTO .agents/ (corrupting the source).
skill_targets=(
  .claude/skills
  .claude-a/skills
  .claude-token/skills
  .codex/skills
  .cursor/skills-cursor
)
for base in "${skill_targets[@]}"; do
  for name in axi cocoindex cocoindex-code plugin.json; do
    target="$HOME/$base/$name"
    if [[ -L "$target" || -e "$target" ]]; then
      echo "==> clearing stale skill target $target"
      /bin/rm -rf "$target"
    fi
  done
done

# Pre-trust Homebrew taps before Nix invokes homebrew-bundle
brew trust felixkratz/formulae 2>/dev/null || true
brew trust nikitabobko/tap 2>/dev/null || true
brew trust daytonaio/cli 2>/dev/null || true

# Apply nix changes
sudo $(command -v darwin-rebuild) switch --flake ~/.dotfiles#mac

# Refresh capability manifest (content hash changed)
if command -v bridge >/dev/null 2>&1; then
  echo "==> refreshing machine capability manifest"
  bridge freeze --write 2>/dev/null || true
  bridge verify-machine
fi

# Restart daemons that may have stale config after rebuild
for svc in com.jwalinshah.tldr-daemon com.jwalinshah.cocoindex-daemon; do
  launchctl kickstart -k "gui/$(id -u)/org.nixos.$svc" 2>/dev/null || true
done

# Prove skills are readable (no symlink loop) AND .agents source stayed real files
if ! head -1 "$HOME/.claude/skills/axi/SKILL.md" >/dev/null 2>&1; then
  echo "ERROR: ~/.claude/skills/axi/SKILL.md unreadable after rebuild (symlink loop?)" >&2
  exit 1
fi
if [[ -L "$DIR/.agents/axi/SKILL.md" || -L "$DIR/.agents/plugin.json" ]]; then
  echo "ERROR: .agents/ source was corrupted into store symlinks during rebuild." >&2
  echo "  HM followed a stale ~/.claude/skills → .agents link. Source restored? Refuse." >&2
  exit 1
fi

echo "==> rebuild complete"
