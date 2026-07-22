#!/usr/bin/env bash
# enforce-bridge-workflow-antigravity.sh — PreToolUse hook for antigravity-cli.
# Same policy as enforce-bridge-workflow.sh (Claude Code / Codex), adapted to
# antigravity's hooks.json contract: JSON on stdin, JSON with a "decision"
# field on stdout (allow/deny), matcher "edit_file".
#
# Deployed to: antigravity-cli via ~/.gemini/config/hooks.json
# Source: ~/.dotfiles/bin/enforce-bridge-workflow-antigravity.sh

set -euo pipefail

GATED_PROJECTS=("orbit" "bridge" "portfolio")
TASK_MARKERS=("ORBIT_TASK.md" ".bridge-task")
ALWAYS_ALLOWED=(".claude/" "docs/agents/" "wayfinder/" "CLAUDE.md" "AGENTS.md" ".gitignore" "go.mod" "go.sum" "README.md")

INPUT=$(cat)

# antigravity's edit_file arg key name isn't stably documented; try the
# common candidates, then fall back to scanning all string arg values for
# one that resolves under a gated project.
FILE=$(echo "$INPUT" | jq -r '
  .toolCall.args.TargetFile // .toolCall.args.target_file //
  .toolCall.args.FilePath // .toolCall.args.file_path //
  .toolCall.args.AbsolutePath // .toolCall.args.path // ""
' 2>/dev/null) || FILE=""

if [ -z "$FILE" ]; then
  # Fallback: scan all string values in args for a path-looking candidate.
  FILE=$(echo "$INPUT" | jq -r '.toolCall.args | to_entries[]? | select(.value|type=="string") | .value' 2>/dev/null \
    | grep -E '^(/|~/)' | head -1) || FILE=""
fi

if [ -z "$FILE" ]; then
  echo '{"decision":"allow"}'
  exit 0
fi

if command -v realpath &>/dev/null; then
  ABS_FILE=$(realpath "$FILE" 2>/dev/null) || ABS_FILE="$FILE"
else
  ABS_FILE=$(python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$FILE" 2>/dev/null) || ABS_FILE="$FILE"
fi

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
  echo '{"decision":"allow"}'
  exit 0
fi

REL_FILE="${ABS_FILE#$PROJECT_DIR/}"
for allowed in "${ALWAYS_ALLOWED[@]}"; do
  if [[ "$REL_FILE" == "$allowed"* ]]; then
    echo '{"decision":"allow"}'
    exit 0
  fi
done

for marker in "${TASK_MARKERS[@]}"; do
  if [ -f "$PROJECT_DIR/$marker" ]; then
    echo '{"decision":"allow"}'
    exit 0
  fi
done

REASON="BLOCKED: $REL_FILE in $PROJECT_DIR — direct edits require an active task file. Run: bridge spawn <ticket.json> <brief.md>, or create $PROJECT_DIR/ORBIT_TASK.md"
printf '{"decision":"deny","reason":%s}' "$(printf '%s' "$REASON" | jq -Rs .)"
exit 0
