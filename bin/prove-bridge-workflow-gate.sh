#!/usr/bin/env bash
# Canary: gate denies mutations without task; allows with task; shells can't bypass.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
export ROOT
GATE="${ROOT}/bin/enforce-bridge-workflow.sh"
PASS=0; FAIL=0
FIXTURE="$(mktemp -d "${HOME}/projects/.bridge-gate-fixture.XXXXXX")"
TARGET="${FIXTURE}/repo"
ISOLATED="${FIXTURE}/worktree"
mkdir -p "$TARGET"
git -C "$TARGET" init -q
git -C "$TARGET" config user.email gate-test@example.invalid
git -C "$TARGET" config user.name gate-test
printf 'fixture\n' > "$TARGET/README.md"
printf 'tracked\n' > "$TARGET/tracked.txt"
git -C "$TARGET" add README.md tracked.txt
git -C "$TARGET" commit -qm fixture
git -C "$TARGET" worktree add -q --detach "$ISOLATED" HEAD
restore() {
  git -C "$TARGET" worktree remove --force "$ISOLATED" 2>/dev/null || true
  git -C "$TARGET" worktree remove --force "${FIXTURE}/wt-dirty" 2>/dev/null || true
  git -C "$TARGET" worktree remove --force "${FIXTURE}/wt-clean" 2>/dev/null || true
  rm -rf -- "$FIXTURE"
}
trap restore EXIT

run_case() {
  local name="$1" input="$2" expect="$3"
  set +e
  echo "$input" | "$GATE" >/tmp/gate-out.json 2>/tmp/gate-err.txt
  local ec=$?
  set -e
  if [[ "$ec" -eq "$expect" ]]; then
    if [[ "$expect" -eq 2 ]]; then
      python3 - <<'PY'
import json
from pathlib import Path
d = json.loads(Path('/tmp/gate-out.json').read_text())
specific = d.get('hookSpecificOutput', {})
assert specific.get('hookEventName') == 'PreToolUse'
assert specific.get('permissionDecision') == 'deny'
assert isinstance(specific.get('permissionDecisionReason'), str)
assert 'permission' not in d and 'decision' not in d
PY
    fi
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
run_case "write-existing-primary-no-task-deny" \
  "{\"tool_input\":{\"path\":\"$TARGET/tracked.txt\"}}" 2

# Chicken-egg: Write of task markers is always allowed (no prior marker)
run_case "write-bridge-task-no-task-allow" \
  "{\"tool_input\":{\"path\":\"$TARGET/.bridge-task\"}}" 0
run_case "write-orbit-task-no-task-allow" \
  "{\"tool_input\":{\"path\":\"$TARGET/ORBIT_TASK.md\"}}" 0

run_case "shell-readonly-allow" \
  "{\"tool_input\":{\"command\":\"ls $TARGET\",\"working_directory\":\"$TARGET\"}}" 0

run_case "shell-heredoc-deny" \
  "{\"command\":\"cat > $TARGET/evil.py <<'E'\\nx\\nE\",\"cwd\":\"$TARGET\"}" 2

# Marker creation remains the only primary-checkout bootstrap exception.
run_case "shell-write-bridge-task-allow" \
  "{\"command\":\"echo ticket > $TARGET/.bridge-task\",\"cwd\":\"$TARGET\"}" 0
run_case "shell-write-orbit-task-allow" \
  "{\"command\":\"echo ticket > $TARGET/ORBIT_TASK.md\",\"cwd\":\"$TARGET\"}" 0

# A marker never turns the shared primary checkout into an ordinary work area.
echo "ticket: prove-gate" > "$TARGET/.bridge-task"
run_case "write-primary-with-task-still-deny" \
  "{\"tool_input\":{\"path\":\"$TARGET/extract.py\"}}" 2
run_case "shell-primary-with-task-still-deny" \
  "{\"command\":\"cat > $TARGET/evil.py <<'E'\\nx\\nE\",\"cwd\":\"$TARGET\"}" 2
rm -f "$TARGET/.bridge-task" "$TARGET/ORBIT_TASK.md"

# An isolated checkout still needs an explicit task marker.
run_case "write-isolated-without-task-deny" \
  "{\"tool_input\":{\"path\":\"$ISOLATED/extract.py\"}}" 2
echo "ticket: isolated" > "$ISOLATED/.bridge-task"
run_case "write-isolated-with-task-allow" \
  "{\"tool_input\":{\"path\":\"$ISOLATED/extract.py\"}}" 0

# A prototype exception is explicit, bounded, disposable, and scratch-only.
PROTO="$TARGET/.scratch/probe.py"
PROTO_META="\"bridge_workflow\":{\"mode\":\"prototype\",\"purpose\":\"gate canary\",\"allowed_paths\":[\".scratch\"],\"expires_at\":\"2099-01-01T00:00:00Z\",\"disposable\":true,\"no_delivery\":true}"
run_case "prototype-primary-scratch-allow" \
  "{${PROTO_META},\"tool_input\":{\"path\":\"$PROTO\"}}" 0
run_case "prototype-primary-outside-scratch-deny" \
  "{${PROTO_META},\"tool_input\":{\"path\":\"$TARGET/real.py\"}}" 2
run_case "prototype-shell-primary-scratch-allow" \
  "{${PROTO_META},\"command\":\"echo x > $TARGET/.scratch/probe.py\",\"cwd\":\"$TARGET\"}" 0
run_case "prototype-without-purpose-deny" \
  "{\"bridge_workflow\":{\"mode\":\"prototype\",\"allowed_paths\":[\".scratch\"],\"expires_at\":\"2099-01-01T00:00:00Z\",\"disposable\":true},\"tool_input\":{\"path\":\"$PROTO\"}}" 2

# Destructive-git guard: worktree remove / branch delete must fail closed on
# anything with no recoverable git backup (2026-09-03 incident: a batch
# `git worktree remove --force` loop destroyed real untracked content with
# no per-item check — see wayfinder machine-provider-routing-triage map).
BARE="${FIXTURE}/bare.git"
git init -q --bare "$BARE"
git -C "$TARGET" remote add origin "$BARE"
git -C "$TARGET" push -q origin main

WT_DIRTY="${FIXTURE}/wt-dirty"
git -C "$TARGET" worktree add -q "$WT_DIRTY" -b wt-dirty
mkdir -p "$WT_DIRTY/untracked-dir"
printf 'irreplaceable\n' > "$WT_DIRTY/untracked-dir/report.md"
run_case "worktree-remove-dirty-untracked-deny" \
  "{\"tool_input\":{\"command\":\"git worktree remove $WT_DIRTY --force\",\"cwd\":\"$TARGET\"}}" 2

WT_CLEAN="${FIXTURE}/wt-clean"
git -C "$TARGET" worktree add -q "$WT_CLEAN" -b wt-clean
git -C "$TARGET" push -q origin wt-clean
run_case "worktree-remove-clean-pushed-allow" \
  "{\"tool_input\":{\"command\":\"git worktree remove $WT_CLEAN --force\",\"cwd\":\"$TARGET\"}}" 0

git -C "$TARGET" checkout -qb branch-unpushed
printf 'new\n' > "$TARGET/unpushed-file.md"
git -C "$TARGET" add unpushed-file.md
git -C "$TARGET" commit -qm "real unpushed commit"
git -C "$TARGET" checkout -q main
run_case "branch-delete-unpushed-commit-deny" \
  "{\"tool_input\":{\"command\":\"git -C $TARGET branch -D branch-unpushed\",\"cwd\":\"$TARGET\"}}" 2

git -C "$TARGET" branch branch-pushed main
run_case "branch-delete-pushed-content-allow" \
  "{\"tool_input\":{\"command\":\"git -C $TARGET branch -D branch-pushed\",\"cwd\":\"$TARGET\"}}" 0

# Exit-code contract: deny must be 2 (Claude/Cursor treat exit 1 as allow).
# Document that exit 1 must never be used for policy deny.
run_case "empty-stdin-allow" "{}" 0
run_case "invalid-json-deny" "not-json" 2
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
import json, os, sys
from pathlib import Path
root = Path(os.environ["ROOT"]) / "home"
# Cursor: Shell in matcher. A beforeShellExecution entry may be present in a
# user-managed config; this proof does not rewrite or judge that separate hook.
c = json.loads((root/".cursor/hooks.json").read_text())
pre = json.dumps(c["hooks"].get("preToolUse", []))
assert "Shell" in pre and "enforce-bridge-workflow" in pre
assert c["hooks"]["preToolUse"][0].get("failClosed") is False
if "beforeShellExecution" in c["hooks"]:
    print("NOTE: Cursor beforeShellExecution present in user config; left unchanged")
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
