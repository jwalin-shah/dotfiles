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

for req in axi/SKILL.md cocoindex/SKILL.md cocoindex-code/SKILL.md plugin.json; do
  if [[ ! -e "$DIR/.agents/$req" ]]; then
    echo "ERROR: missing $DIR/.agents/$req — refusing rebuild." >&2
    echo "  Fix: git checkout HEAD -- .agents/" >&2
    exit 1
  fi
done

# Hand-made alias (seen 2026-07-18): ~/.claude/skills → dotfiles/.agents
# That makes ~/.claude/skills/axi the SAME inode as .agents/axi. Clearing
# "stale skill targets" under that alias deletes the flake source.
# Unlink the alias first; home-manager will recreate ~/.claude/skills properly.
for skills_dir in \
  "$HOME/.claude/skills" \
  "$HOME/.claude-a/skills" \
  "$HOME/.claude-token/skills" \
  "$HOME/.codex/skills" \
  "$HOME/.cursor/skills-cursor"
do
  if [[ -L "$skills_dir" ]]; then
    resolved=$(realpath "$skills_dir" 2>/dev/null || true)
    if [[ -n "$resolved" && "$resolved" == "$DIR/.agents"* ]]; then
      echo "==> unlinking skills alias $skills_dir -> $resolved"
      /bin/rm -f "$skills_dir"
    fi
  fi
done

# Remove prior per-skill projections (now safe — skills dirs are not .agents).
clear_skill_target() {
  local target="$1"
  if [[ -L "$target" ]]; then
    local resolved
    resolved=$(realpath "$target" 2>/dev/null || true)
    if [[ -n "$resolved" && "$resolved" == "$DIR/.agents"* ]]; then
      echo "==> unlinking $target (-> .agents; link only)"
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
      echo "ERROR: $target resolves into .agents but is not a symlink — refuse." >&2
      exit 1
    fi
    echo "==> clearing stale skill target $target"
    /bin/rm -rf "$target"
  fi
}

for base in .claude/skills .claude-a/skills .claude-token/skills .codex/skills .cursor/skills-cursor; do
  for name in axi cocoindex cocoindex-code plugin.json; do
    clear_skill_target "$HOME/$base/$name"
  done
done

brew trust felixkratz/formulae 2>/dev/null || true
brew trust nikitabobko/tap 2>/dev/null || true
brew trust daytonaio/cli 2>/dev/null || true

sudo $(command -v darwin-rebuild) switch --flake ~/.dotfiles#mac

if command -v bridge >/dev/null 2>&1; then
  echo "==> refreshing machine capability manifest"
  bridge freeze --write 2>/dev/null || true
  bridge verify-machine
  echo "==> proving harness hooks"
  "$DIR/bin/prove-harness-hooks.sh" || exit 1
  echo "==> proving launchers / LaunchAgents"
  "$DIR/bin/prove-launchers.sh" || exit 1
  if [[ -x "${HOME}/projects/bridge/scripts/prove-neo4j-packet.sh" ]]; then
    echo "==> proving live Neo4j spawn packet"
    "${HOME}/projects/bridge/scripts/prove-neo4j-packet.sh" || exit 1
  fi
  if [[ -x "${HOME}/projects/bridge/scripts/prove-worktree-lease.sh" ]]; then
    echo "==> proving CreateWorktreePhase preserves worktree"
    "${HOME}/projects/bridge/scripts/prove-worktree-lease.sh" || exit 1
  fi
fi

# Unload retired cocoindex-daemon if a stale plist remains after nix switch.
launchctl bootout "gui/$(id -u)/org.nixos.com.jwalinshah.cocoindex-daemon" 2>/dev/null || true
pkill -f 'ccc run-daemon' 2>/dev/null || true

for svc in com.jwalinshah.tldr-daemon; do
  launchctl kickstart -k "gui/$(id -u)/org.nixos.$svc" 2>/dev/null || true
done

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
if [[ -L "$HOME/.claude/skills" ]]; then
  echo "ERROR: ~/.claude/skills is still a symlink (should be a HM-managed directory)." >&2
  exit 1
fi

echo "==> rebuild complete"
