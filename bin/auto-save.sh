#!/usr/bin/env bash
# auto-save — commit and push uncommitted changes in tracked repos.
# Runs every 5 minutes via launchd. Never lose work.
set -euo pipefail

HOME_DIR="$HOME"
LOG="$HOME_DIR/.local/share/jw/auto-save.log"
mkdir -p "$(dirname "$LOG")"

# Canonical repos to track. ~/projects/ auto-walks all sub-repos.
# firstmate stays at ~/firstmate (orchestrator, not a project).
# dotfiles is tracked separately since it's the config source.
REPOS=(
  "$HOME_DIR/dotfiles"
  "$HOME_DIR/firstmate"
  "$HOME_DIR/projects"
)

log() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*" >> "$LOG"; }

# Walk a directory for git repos one level deep
walk_repos() {
  local dir="$1"
  [ -d "$dir" ] || return
  for d in "$dir"/*/; do
    [ -d "${d}.git" ] || [ -f "${d}.git" ] && echo "$d"
  done
}

log "=== auto-save tick ==="

for repo in "${REPOS[@]}"; do
  # Expand ~/projects/ into individual repos
  if [ "$repo" = "$HOME_DIR/projects" ]; then
    while IFS= read -r sub; do
      [ -n "$sub" ] && REPOS+=("$sub")
    done < <(walk_repos "$repo")
    continue
  fi

  [ -d "$repo/.git" ] || [ -f "$repo/.git" ] || continue

  pushd "$repo" > /dev/null 2>&1 || continue

  # Skip worktrees
  common_dir=$(git rev-parse --git-common-dir 2>/dev/null) || { popd > /dev/null; continue; }
  case "$common_dir" in
    */.claude/worktrees/*|*/.codex/worktrees/*|*/treehouse/worktrees/*)
      popd > /dev/null; continue ;;
  esac

  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || { popd > /dev/null; continue; }
  [ "$branch" != "HEAD" ] || { popd > /dev/null; continue; }

  if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    git add -A 2>/dev/null || true
    git commit -m "auto: save work in progress" 2>/dev/null || true
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    git push origin "$branch" 2>/dev/null || true
    log "saved: $(basename "$repo") ($branch)"
  fi

  popd > /dev/null
done

log "done"
