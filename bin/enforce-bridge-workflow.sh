#!/usr/bin/env bash
# enforce-bridge-workflow.sh — PreToolUse hook for all agents.
# Blocks direct file writes in orbit/bridge/portfolio unless a task file exists.
# This forces every change through the bridge spawn pipeline.
#
# Deployed to: Claude Code, Codex, Cursor hooks
# Source: ~/.dotfiles/bin/enforce-bridge-workflow.sh

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────

# Projects that require bridge spawn for any file change.
GATED_PROJECTS=("orbit" "bridge" "portfolio")

# Files that signal an active, valid workflow.
TASK_MARKERS=("ORBIT_TASK.md" "ORBIT_TASK.md" ".bridge-task")

# Files that are always allowed (config, docs, wayfinder maps).
ALWAYS_ALLOWED=(".claude/" "docs/agents/" "wayfinder/" "CLAUDE.md" "AGENTS.md" ".gitignore" "go.mod" "go.sum" "README.md")

# ── Main ──────────────────────────────────────────────────────────────────

# Get the file being edited from the hook input (JSON on stdin).
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""')

if [ -z "$FILE" ]; then
  exit 0  # No file path — allow (not a file edit).
fi

# Resolve to absolute path.
ABS_FILE=$(cd "$(dirname "$FILE")" 2>/dev/null && pwd)/$(basename "$FILE") || ABS_FILE="$FILE"

# Check if this file is in a gated project.
GATED=false
PROJECT_DIR=""
for proj in "${GATED_PROJECTS[@]}"; do
  PROJ_PATH="$HOME/projects/$proj"
  if [[ "$ABS_FILE" == "$PROJ_PATH"* ]]; then
    GATED=true
    PROJECT_DIR="$PROJ_PATH"
    break
  fi
done

if [ "$GATED" = false ]; then
  exit 0  # Not in a gated project — allow.
fi

# Check if this is an always-allowed file.
REL_FILE="${ABS_FILE#$PROJECT_DIR/}"
for allowed in "${ALWAYS_ALLOWED[@]}"; do
  if [[ "$REL_FILE" == "$allowed"* ]]; then
    exit 0  # Always-allowed file — allow.
  fi
done

# Check for an active task marker.
for marker in "${TASK_MARKERS[@]}"; do
  if [ -f "$PROJECT_DIR/$marker" ]; then
    exit 0  # Active task file exists — allow.
  fi
done

# Check for wayfinder map (read-only orientation, not write approval).
if [ -f "$PROJECT_DIR/wayfinder/map.md" ]; then
  echo "[bridge-workflow] WARNING: No active task file in $PROJECT_DIR." >&2
  echo "  The wayfinder map exists but no ORBIT_TASK.md or .bridge-task is active." >&2
  echo "  Changes to $REL_FILE should be routed through bridge spawn." >&2
  echo "  Create a task file or spawn through bridge: bridge spawn <ticket> <brief>" >&2
fi

# BLOCK: no task file, not an allowed file, in a gated project.
echo "[bridge-workflow] BLOCKED: $REL_FILE in $PROJECT_DIR" >&2
echo "  Direct edits to code files in this project require an active task file." >&2
echo "  Run: bridge spawn <ticket.json> <brief.md>" >&2
echo "  Or create: echo 'task: <description>' > $PROJECT_DIR/ORBIT_TASK.md" >&2
exit 1