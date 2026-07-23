#!/usr/bin/env bash
# Canary: gate denies mutations without task; allows with task; shells can't bypass.
set -euo pipefail
GATE="${HOME}/.dotfiles/bin/enforce-bridge-workflow.sh"
PASS=0; FAIL=0
TARGET="${HOME}/projects/axioms"
# axioms normally has no task; stash if present
STASHED=0
if [[ -f "$TARGET/.bridge-task" || -f "$TARGET/ORBIT_TASK.md" ]]; then
  mkdir -p /tmp/gate-task-stash
  mv "$TARGET/.bridge-task" /tmp/gate-task-stash/ 2>/dev/null || true
  mv "$TARGET/ORBIT_TASK.md" /tmp/gate-task-stash/ 2>/dev/null || true
  STASHED=1
fi
restore() {
  if [[ "$STASHED" -eq 1 ]]; then
    mv /tmp/gate-task-stash/.bridge-task "$TARGET/" 2>/dev/null || true
    mv /tmp/gate-task-stash/ORBIT_TASK.md "$TARGET/" 2>/dev/null || true
  fi
}
trap restore EXIT

run_case() {
  local name="$1" input="$2" expect="$3"
  set +e
  echo "$input" | "$GATE" >/tmp/gate-out.json 2>/tmp/gate-err.txt
  local ec=$?
  set -e
  if [[ "$ec" -eq "$expect" ]]; then
    echo "OK: $name (exit $ec)"; PASS=$((PASS+1))
  else
    echo "FAIL: $name expected $expect got $ec" >&2
    cat /tmp/gate-err.txt >&2 || true
    cat /tmp/gate-out.json >&2 || true
    FAIL=$((FAIL+1))
  fi
}

# README.md is ALWAYS_ALLOWED — use a code path
run_case "write-code-no-task-deny" \
  "{\"tool_input\":{\"path\":\"$TARGET/extract.py\"}}" 2

run_case "shell-readonly-allow" \
  "{\"tool_input\":{\"command\":\"ls $TARGET\",\"working_directory\":\"$TARGET\"}}" 0

run_case "shell-heredoc-deny" \
  "{\"command\":\"cat > $TARGET/evil.py <<'E'\\nx\\nE\",\"cwd\":\"$TARGET\"}" 2

echo "ticket: prove-gate" > "$TARGET/.bridge-task"
run_case "write-with-task-allow" \
  "{\"tool_input\":{\"path\":\"$TARGET/extract.py\"}}" 0
run_case "shell-heredoc-with-task-allow" \
  "{\"command\":\"cat > $TARGET/evil.py <<'E'\\nx\\nE\",\"cwd\":\"$TARGET\"}" 0
rm -f "$TARGET/.bridge-task"

# Cross-harness wiring checks (source files)
python3 - <<'PY'
import json, sys
from pathlib import Path
root = Path.home() / "projects/dotfiles/home"
# Cursor: Shell in matcher, no beforeShellExecution (worker can't nest shell hooks)
c = json.loads((root/".cursor/hooks.json").read_text())
pre = json.dumps(c["hooks"].get("preToolUse", []))
assert "Shell" in pre and "enforce-bridge-workflow" in pre
assert "beforeShellExecution" not in c["hooks"], "beforeShellExecution must stay off in this worker"
assert c["hooks"]["preToolUse"][0].get("failClosed") is False
# Claude: Bash in enforce matcher
cl = json.loads((root/".claude/settings.json").read_text())
blob = json.dumps(cl["hooks"]["PreToolUse"])
assert "Bash" in blob and "enforce-bridge-workflow" in blob
# Codex: pre-edit has enforce (file path); shell gap documented not asserted here
cx = json.loads((root/".codex/hooks.json").read_text())
assert "enforce-bridge-workflow" in json.dumps(cx)
# Gemini antigravity
g = json.loads((root/".gemini/config/hooks.json").read_text())
assert "enforce-bridge-workflow" in json.dumps(g)
print("OK: cursor+claude+codex+gemini source wiring")
PY

echo "PASS=$PASS FAIL=$FAIL"
[[ "$FAIL" -eq 0 ]]
