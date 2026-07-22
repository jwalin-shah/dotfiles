#!/usr/bin/env bash
# enforce-bridge-workflow.sh — preToolUse / PreToolUse for agents.
# Blocks direct file writes in orbit/bridge/portfolio unless a task file exists.
set -u

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

GATED_PROJECTS=("orbit" "bridge" "portfolio")
TASK_MARKERS=("ORBIT_TASK.md" ".bridge-task")
ALWAYS_ALLOWED=(".claude/" "docs/agents/" "wayfinder/" "CLAUDE.md" "AGENTS.md" ".gitignore" "go.mod" "go.sum" "README.md" "OPERATING_MODEL.md")

INPUT=$(cat || true)

FILE=$(INPUT="$INPUT" python3 - <<'PY' 2>/dev/null || true
import json, os, sys
raw = os.environ.get("INPUT", "")
if not raw.strip():
    sys.exit(0)
try:
    d = json.loads(raw)
except Exception:
    sys.exit(0)
ti = d.get("tool_input") or {}
for key in ("file_path", "path"):
    if isinstance(ti, dict) and ti.get(key):
        print(ti[key]); sys.exit(0)
if d.get("file_path"):
    print(d["file_path"])
PY
)

if [ -z "${FILE:-}" ]; then
  exit 0
fi

ABS_FILE=$(python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$FILE" 2>/dev/null || echo "$FILE")

GATED=false
PROJECT_DIR=""
for proj in "${GATED_PROJECTS[@]}"; do
  PROJ_PATH="$HOME/projects/$proj"
  case "$ABS_FILE" in
    "$PROJ_PATH"/*|"$PROJ_PATH")
      GATED=true
      PROJECT_DIR="$PROJ_PATH"
      break
      ;;
  esac
done

if [ "$GATED" = false ]; then
  exit 0
fi

REL_FILE="${ABS_FILE#"$PROJECT_DIR"/}"
for allowed in "${ALWAYS_ALLOWED[@]}"; do
  case "$REL_FILE" in
    "$allowed"*) exit 0 ;;
  esac
done

for marker in "${TASK_MARKERS[@]}"; do
  if [ -f "$PROJECT_DIR/$marker" ]; then
    exit 0
  fi
done

MSG="Direct edits to code files in $PROJECT_DIR require ORBIT_TASK.md or bridge spawn. Blocked: $REL_FILE"
echo "[bridge-workflow] BLOCKED: $REL_FILE in $PROJECT_DIR" >&2
echo "  $MSG" >&2
# Cursor preToolUse: JSON deny on stdout; exit 2 also blocks (Claude + Cursor).
python3 -c "import json; print(json.dumps({'permission':'deny','user_message':'''$MSG''','agent_message':'''$MSG'''}))" 2>/dev/null || true
exit 2
