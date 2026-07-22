#!/usr/bin/env bash
# cursor-after-file-edit.sh — Cursor afterFileEdit → fmt-on-edit (+ Neo4j fan-in).
set -u
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

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
print(d.get("file_path") or "")
PY
)
[ -z "${FILE:-}" ] && exit 0

export CLAUDE_TOOL_INPUT_FILE_PATH="$FILE"
export FILE_PATH="$FILE"

FMT="${HOME}/.dotfiles/bin/fmt-on-edit.sh"
[ -x "$FMT" ] || FMT="${HOME}/projects/dotfiles/bin/fmt-on-edit.sh"
[ -x "$FMT" ] || exit 0
"$FMT" || true
exit 0
