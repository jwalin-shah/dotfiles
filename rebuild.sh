#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" ~/.dotfiles

# Guard: .agents/ must hold real skill content, never symlinks.
if [[ -d "$DIR/.agents" ]]; then
  while IFS= read -r -d '' entry; do
    if [[ -L "$entry" ]]; then
      echo "ERROR: $entry is a symlink — refusing rebuild." >&2
      echo "  Fix: git checkout HEAD -- .agents/" >&2
      exit 1
    fi
  done < <(/usr/bin/find "$DIR/.agents" -mindepth 1 -maxdepth 1 -print0)
  if /usr/bin/find "$DIR/.agents" -type l | grep -q .; then
    echo "ERROR: symlink(s) inside .agents/ — refusing rebuild." >&2
    /usr/bin/find "$DIR/.agents" -type l -print >&2
    exit 1
  fi
fi

# Ensure skill sources exist (flake copies ./.agents into the store — must be tracked + present).
for req in axi/SKILL.md cocoindex/SKILL.md cocoindex-code/SKILL.md plugin.json; do
  if [[ ! -e "$DIR/.agents/$req" ]]; then
    echo "ERROR: missing $DIR/.agents/$req — refusing rebuild." >&2
    echo "  Fix: git checkout HEAD -- .agents/" >&2
    exit 1
  fi
done

# Remove prior skill projections WITHOUT following links into .agents/.
# If ~/.claude/skills/axi → .agents/axi, a naive rm -rf would wipe the source.
clear_skill_target() {
  local target="$1"
  if [[ -L "$target" ]]; then
    local dest
    dest=$(readlink "$target" || true)
    # Absolute or relative — resolve
    local resolved
    resolved=$(realpath "$target" 2>/dev/null || true)
    if [[ -n "$resolved" && "$resolved" == "$DIR/.agents"* ]]; then
      echo "==> unlinking $target (-> .agents; link only, keep source)"
      /bin/rm -f "$target"
      return
    fi
    echo "==> unlinking $target"
    /bin/rm -f "$target"
    return
  fi
  if [[ -e "$target" ]]; then
    local resolved
    resolved=$(realpath "$target" 2>/dev/null || true)
    if [[ -n "$resolved" && "$resolved" == "$DIR/.agents"* ]]; then
      echo "ERROR: $target resolves into .agents but is not a symlink — refuse to delete." >&2
      exit 1
    fi
    echo "==> clearing stale skill target $target"
    /bin/rm -rf "$target"
  fi
}

skill_targets=(
  .claude/skills
  .claude-a/skills
  .claude-token/skills
  .codex/skills
  .cursor/skills-cursor
)
for base in "${skill_targets[@]}"; do
  for name in axi cocoindex cocoindex-code plugin.json; do
    clear_skill_target "$HOME/$base/$name"
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

# Prove skills readable AND .agents source stayed real files
if ! head -1 "$HOME/.claude/skills/axi/SKILL.md" >/dev/null 2>&1; then
  echo "ERROR: ~/.claude/skills/axi/SKILL.md unreadable after rebuild." >&2
  exit 1
fi
if [[ -L "$DIR/.agents/axi/SKILL.md" || -L "$DIR/.agents/plugin.json" ]]; then
  echo "ERROR: .agents/ source was corrupted into store symlinks during rebuild." >&2
  exit 1
fi
if [[ ! -f "$DIR/.agents/axi/SKILL.md" ]]; then
  echo "ERROR: .agents/axi/SKILL.md missing after rebuild." >&2
  exit 1
fi

echo "==> rebuild complete"
