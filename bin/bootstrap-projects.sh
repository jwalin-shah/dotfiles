#!/usr/bin/env bash
# fm-bootstrap-projects.sh — initialize all project repos with skills + docs.
# Run once after fresh clone or when adding a new project.
# Each project gets: setup-matt-pocock-skills + openwiki doc generation.
set -euo pipefail

PROJECTS_DIR="${PROJECTS_DIR:-$HOME/projects}"
FIRSTMATE="$PROJECTS_DIR/firstmate"
GH_OWNER="jwalin-shah"

# ── Project list ─────────────────────────────────────────────────
# Add new projects here. Order: most critical first.
PROJECTS=(
  "$HOME/dotfiles"
  "$PROJECTS_DIR/firstmate"
  "$PROJECTS_DIR/bridge"           # hard dep: ~/bin/bridge-ca symlinks into this repo
  "$PROJECTS_DIR/mintmux"
  "$PROJECTS_DIR/m5tools"
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

# ── Step -1: clone missing repos ──────────────────────────────────
# Repos referenced above but not present on disk get cloned from
# github.com/$GH_OWNER/<name> via gh-axi (per ~/CLAUDE.md tool policy:
# gh-axi for all GitHub operations, never bare gh).
log "=== Phase -1: clone missing repos ==="
for project in "${PROJECTS[@]}"; do
  name=$(basename "$project")
  [ -d "$project" ] && continue
  [ "$name" = "dotfiles" ] || [ "$name" = "firstmate" ] && continue
  dim "  → $name — not on disk, cloning from $GH_OWNER/$name"
  (cd "$PROJECTS_DIR" && gh-axi repo clone "$GH_OWNER/$name") \
    && green "  ✓ $name — cloned" \
    || red "  ✗ $name — clone failed (does the repo exist under $GH_OWNER?)"
done

skill_ready() {
  # Check if setup-matt-pocock-skills has been run on this project
  local dir="$1"
  [ -f "$dir/docs/agents/issue-tracker.md" ] && \
    [ -f "$dir/docs/agents/triage-labels.md" ] && \
    [ -f "$dir/docs/agents/domain.md" ]
}

# ── Step 0: build binaries into ~/.local/bin ─────────────────────
# mintmux and m5tools binaries are hand-copied into ~/.local/bin with no
# build trace back to source. This step makes them reproducible from git.
log "=== Phase 0: build binaries ==="

if [ -d "$PROJECTS_DIR/mintmux" ]; then
  dim "  → mintmux — go build ./..."
  (cd "$PROJECTS_DIR/mintmux" && go build -o "$HOME/.local/bin/" ./cmd/...) \
    && green "  ✓ mintmux — built to ~/.local/bin" \
    || red "  ✗ mintmux — build failed"
else
  dim "  → mintmux — not found, skipping"
fi

if [ -d "$PROJECTS_DIR/m5tools" ]; then
  dim "  → m5tools — make install (installs straight to ~/.local/bin)"
  (cd "$PROJECTS_DIR/m5tools" && make install) \
    && green "  ✓ m5tools — built and installed" \
    || red "  ✗ m5tools — build failed"
else
  dim "  → m5tools — not found, skipping"
fi
if [ -d "$PROJECTS_DIR/bridge" ]; then
  dim "  → bridge — go build ./cmd/bridge"
  (cd "$PROJECTS_DIR/bridge" && go build -o "$HOME/.local/bin/bridge" ./cmd/bridge) \
    && green "  ✓ bridge — built to ~/.local/bin/bridge" \
    || red "  ✗ bridge — build failed"
else
  dim "  → bridge — not found, skipping"
fi


if [ -d "$HOME/dotfiles/tools/smc" ]; then
  dim "  → smc — make"
  (cd "$HOME/dotfiles/tools/smc" && make && cp smc "$HOME/.local/bin/smc") \
    && green "  ✓ smc — built to ~/.local/bin/smc" \
    || red "  ✗ smc — build failed"
else
  dim "  → smc — not found in dotfiles/tools, skipping"
fi



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
echo "Example: cd ~/projects/firstmate && fm-spawn.sh scout 'run /setup-matt-pocock-skills on dotfiles'"
