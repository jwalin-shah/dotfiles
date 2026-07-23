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

# Chicken-egg: Write of task markers is always allowed (no prior marker)
run_case "write-bridge-task-no-task-allow" \
  "{\"tool_input\":{\"path\":\"$TARGET/.bridge-task\"}}" 0
run_case "write-orbit-task-no-task-allow" \
  "{\"tool_input\":{\"path\":\"$TARGET/ORBIT_TASK.md\"}}" 0

run_case "shell-readonly-allow" \
  "{\"tool_input\":{\"command\":\"ls $TARGET\",\"working_directory\":\"$TARGET\"}}" 0

run_case "shell-heredoc-deny" \
  "{\"command\":\"cat > $TARGET/evil.py <<'E'\\nx\\nE\",\"cwd\":\"$TARGET\"}" 2

# Narrow shell: marker-only mutation allowed without prior task
run_case "shell-write-bridge-task-allow" \
  "{\"command\":\"echo ticket > $TARGET/.bridge-task\",\"cwd\":\"$TARGET\"}" 0
run_case "shell-write-orbit-task-allow" \
  "{\"command\":\"echo ticket > $TARGET/ORBIT_TASK.md\",\"cwd\":\"$TARGET\"}" 0

echo "ticket: prove-gate" > "$TARGET/.bridge-task"
run_case "write-with-task-allow" \
  "{\"tool_input\":{\"path\":\"$TARGET/extract.py\"}}" 0
run_case "shell-heredoc-with-task-allow" \
  "{\"command\":\"cat > $TARGET/evil.py <<'E'\\nx\\nE\",\"cwd\":\"$TARGET\"}" 0
rm -f "$TARGET/.bridge-task"

# Exit-code contract: deny must be 2 (Claude/Cursor treat exit 1 as allow).
# Document that exit 1 must never be used for policy deny.
run_case "empty-stdin-allow" "{}" 0
python3 - <<'PY'
# Codex shell waiver note — vendor has no shell pre-hook; prove documents it.
print("OK: WAIVER codex-shell-bypass until vendor adds shell pre-hook")
PY

# Post-edit smoke: check-on-edit stdout empty
CHECK="${HOME}/.dotfiles/bin/check-on-edit.sh"
tmpf="$(mktemp /tmp/prove-check-XXXX.go)"
echo 'package p; func F() {}' > "$tmpf"
set +e
stdout=$(CLAUDE_TOOL_INPUT_FILE_PATH="$tmpf" "$CHECK" 2>/dev/null)
ec=$?
set -e
rm -f "$tmpf"
if [[ "$ec" -eq 0 && -z "$stdout" ]]; then
  echo "OK: check-on-edit-stdout-empty (exit $ec)"; PASS=$((PASS+1))
else
  echo "FAIL: check-on-edit-stdout-empty exit=$ec stdout=${stdout:0:60}" >&2
  FAIL=$((FAIL+1))
fi

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
post = json.dumps(cl["hooks"].get("PostToolUse", []))
assert "check-on-edit" in post, "check-on-edit must be wired in Claude PostToolUse"
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
