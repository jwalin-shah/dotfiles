#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" ~/.dotfiles

# Guard: .agents/ must hold real skill content, never symlinks into ~/.claude/skills
# (that recreates the closed loop home-manager projects outward from .agents/).
if [[ -d "$DIR/.agents" ]]; then
  while IFS= read -r -d '' entry; do
    if [[ -L "$entry" ]]; then
      echo "ERROR: $entry is a symlink — refusing rebuild." >&2
      echo "  Skills under .agents/ must be real files/dirs (source of truth)." >&2
      echo "  Fix: git checkout HEAD -- .agents/ && rm -f any leftover *.backup loops" >&2
      exit 1
    fi
  done < <(find "$DIR/.agents" -mindepth 1 -maxdepth 1 -print0)
fi

# Pre-trust Homebrew taps before Nix invokes homebrew-bundle
brew trust felixkratz/formulae 2>/dev/null || true
brew trust nikitabobko/tap 2>/dev/null || true
brew trust daytonaio/cli 2>/dev/null || true

# Apply nix changes
sudo $(command -v darwin-rebuild) switch --flake ~/.dotfiles#mac

# Refresh capability manifest (content hash changed)
if command -v bridge >/dev/null 2>&1; then
  echo "==> refreshing machine capability manifest"
  bridge verify-machine
fi

# Restart daemons that may have stale config after rebuild
for svc in com.jwalinshah.tldr-daemon com.jwalinshah.cocoindex-daemon; do
  launchctl kickstart -k "gui/$(id -u)/org.nixos.$svc" 2>/dev/null || true
done

# Prove skills are readable (no symlink loop)
if ! head -1 "$HOME/.claude/skills/axi/SKILL.md" >/dev/null 2>&1; then
  echo "ERROR: ~/.claude/skills/axi/SKILL.md unreadable after rebuild (symlink loop?)" >&2
  exit 1
fi

echo "==> rebuild complete"
