#!/usr/bin/env bash
# fm-bootstrap-projects.sh — initialize all project repos with skills + docs.
# Run once after fresh clone or when adding a new project.
# Each project gets: setup-matt-pocock-skills + openwiki doc generation.
set -euo pipefail

PROJECTS_DIR="${PROJECTS_DIR:-$HOME/projects}"
FIRSTMATE="$HOME/firstmate"

# ── Project list ─────────────────────────────────────────────────
# Add new projects here. Order: most critical first.
PROJECTS=(
  "$HOME/dotfiles"
  "$HOME/firstmate"
  "$PROJECTS_DIR/mintmux"
  "$PROJECTS_DIR/treehouse"
  "$PROJECTS_DIR/quota-core"
  "$PROJECTS_DIR/no-mistakes"
  "$PROJECTS_DIR/voice-engine-swift"
)

# ── Helpers ──────────────────────────────────────────────────────
green() { printf '\033[32m%s\033[0m\n' "$*"; }
red()   { printf '\033[31m%s\033[0m\n' "$*"; }
dim()   { printf '\033[2m%s\033[0m\n' "$*"; }

log()   { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }

skill_ready() {
  # Check if setup-matt-pocock-skills has been run on this project
  local dir="$1"
  [ -f "$dir/docs/agents/issue-tracker.md" ] && \
    [ -f "$dir/docs/agents/triage-labels.md" ] && \
    [ -f "$dir/docs/agents/domain.md" ]
}

# ── Step 1: setup-matt-pocock-skills ─────────────────────────────
log "=== Phase 1: setup-matt-pocock-skills ==="
for project in "${PROJECTS[@]}"; do
  name=$(basename "$project")
  [ -d "$project" ] || { dim "  $name — not found, skipping"; continue; }

  if skill_ready "$project"; then
    green "  ✓ $name — skills already configured"
    continue
  fi

  dim "  → $name — needs setup. Run this inside a Claude session:"
  echo "      cd $project && ct"
  echo "      then type: /setup-matt-pocock-skills"
  echo
done

# ── Step 2: openwiki ─────────────────────────────────────────────
log "=== Phase 2: openwiki ==="
for project in "${PROJECTS[@]}"; do
  name=$(basename "$project")
  [ -d "$project" ] || continue

  if [ -f "$project/.openwiki/state.json" ] 2>/dev/null; then
    green "  ✓ $name — openwiki already initialized"
    continue
  fi

  dim "  → $name — needs docs. Run this inside a Claude session:"
  echo "      cd $project && openwiki"
  echo "      then describe the project, ask it to generate docs"
  echo
done

# ── Step 3: Summary ──────────────────────────────────────────────
log "=== Done ==="
need_skills=0
need_docs=0
for project in "${PROJECTS[@]}"; do
  [ -d "$project" ] || continue
  name=$(basename "$project")
  skill_ready "$project" || { red "  ✗ $name — skills"; need_skills=$((need_skills+1)); }
  [ -f "$project/.openwiki/state.json" ] 2>/dev/null || { red "  ✗ $name — docs"; need_docs=$((need_docs+1)); }
done

echo
echo "Projects needing skills: $need_skills"
echo "Projects needing docs:   $need_docs"
echo
echo "To automate: use firstmate scouts. One scout per project."
echo "Example: cd ~/firstmate && fm-spawn.sh scout 'run /setup-matt-pocock-skills on dotfiles'"
