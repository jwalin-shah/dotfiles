#!/usr/bin/env bash
# prove-harness-hooks.sh — docs-backed event names must match live configs.
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

ROOT="${HOME}/projects/dotfiles"
FAIL=0
ok() { echo "OK: $*"; }
warn() { echo "WARN: $*" >&2; }
fail() { echo "FAIL: $*" >&2; FAIL=1; }

# HM mkOutOfStoreSymlink: readlink shows /nix/store/... but resolve→dotfiles.
# Only warn when resolve is still a frozen store path.
hm_link_ok() {
  local label="$1" path="$2"
  python3 - "$label" "$path" <<'PY'
import os, sys
from pathlib import Path
label, path = sys.argv[1], Path(sys.argv[2])
if not path.is_symlink():
    print(f"OK: {label}: not a symlink")
    raise SystemExit(0)
resolved = str(path.resolve())
dotfiles = str(Path.home() / "projects" / "dotfiles")
if resolved.startswith(dotfiles + os.sep) or resolved == dotfiles:
    print(f"OK: {label}: out-of-store via HM (resolve→dotfiles)")
    raise SystemExit(0)
if resolved.startswith("/nix/store/"):
    print(f"WARN: {label}: still frozen in nix store (resolve={resolved})", file=sys.stderr)
    raise SystemExit(0)
print(f"OK: {label}: resolve={resolved}")
PY
}


"$ROOT/bin/prove-cursor-hooks.sh" \
  "$ROOT/home/.cursor/hooks.json" \
  "${HOME}/.cursor/hooks.json" || FAIL=1
hm_link_ok "cursor-live" "${HOME}/.cursor/hooks.json"

# Machine-wide mutation gate canary (file + shell; all ~/projects/*)
if [[ -x "$ROOT/bin/prove-bridge-workflow-gate.sh" ]]; then
  "$ROOT/bin/prove-bridge-workflow-gate.sh" || FAIL=1
else
  fail "missing prove-bridge-workflow-gate.sh"
fi

check_keys() {
  local label="$1" path="$2" expect_csv="$3"
  python3 - "$label" "$path" "$expect_csv" <<'PY' || return 1
import json, sys
from pathlib import Path
label, path, expect_csv = sys.argv[1], Path(sys.argv[2]), sys.argv[3]
expect = set(expect_csv.split(","))
if not path.exists():
    print(f"FAIL: {label}: missing {path}", file=sys.stderr)
    sys.exit(1)
data = json.loads(path.read_text())
hooks = data.get("hooks", data)
if not isinstance(hooks, dict):
    print(f"FAIL: {label}: no hooks object", file=sys.stderr)
    sys.exit(1)
keys = set(hooks)
missing = expect - keys
if missing:
    print(f"FAIL: {label}: missing {sorted(missing)}; have {sorted(keys)}", file=sys.stderr)
    sys.exit(1)
print(f"OK: {label}: events {sorted(keys & expect)}")
PY
}

check_keys "codex-source" "$ROOT/home/.codex/hooks.json" "pre-edit,post-edit" || FAIL=1
if [[ -f "${HOME}/.codex/hooks.json" ]]; then
  check_keys "codex-live" "${HOME}/.codex/hooks.json" "pre-edit,post-edit" || FAIL=1
  hm_link_ok "codex-live" "${HOME}/.codex/hooks.json"
fi

check_claude() {
  local label="$1" path="$2"
  python3 - "$label" "$path" <<'PY' || return 1
import json, sys
from pathlib import Path
label, path = sys.argv[1], Path(sys.argv[2])
if not path.exists():
    print(f"FAIL: {label}: missing {path}", file=sys.stderr); sys.exit(1)
hooks = json.loads(path.read_text()).get("hooks", {})
need = {"PreToolUse", "PostToolUse"}
if not need <= set(hooks):
    print(f"FAIL: {label}: need {need}, have {sorted(hooks)}", file=sys.stderr); sys.exit(1)
blob = json.dumps(hooks)
if "fmt-on-edit" not in blob:
    print(f"FAIL: {label}: fmt-on-edit.sh not referenced", file=sys.stderr); sys.exit(1)
if "enforce-bridge-workflow" not in blob:
    print(f"FAIL: {label}: enforce-bridge-workflow not referenced", file=sys.stderr); sys.exit(1)
if "check-on-edit" not in blob:
    print(f"FAIL: {label}: check-on-edit.sh not referenced", file=sys.stderr); sys.exit(1)
if "check-stale-gate" not in blob:
    print(f"FAIL: {label}: check-stale-gate.py not referenced", file=sys.stderr); sys.exit(1)
print(f"OK: {label}: PreToolUse+PostToolUse with enforce+fmt+check-on-edit+check-stale")
PY
}

# check-on-edit must emit nothing on stdout (Claude JSON-parses PostToolUse stdout)
if [[ -x "$ROOT/bin/check-on-edit.sh" ]]; then
  tmpgo="$(mktemp /tmp/check-on-edit-XXXX.go)"
  echo 'package main; func main() {}' > "$tmpgo"
  set +e
  out=$(CLAUDE_TOOL_INPUT_FILE_PATH="$tmpgo" "$ROOT/bin/check-on-edit.sh" 2>/dev/null)
  ec=$?
  set -e
  rm -f "$tmpgo"
  if [[ "$ec" -ne 0 ]]; then
    fail "check-on-edit.sh exited $ec (must exit 0)"
  elif [[ -n "$out" ]]; then
    fail "check-on-edit.sh wrote to stdout (must be empty for Claude PostToolUse JSON): ${out:0:80}"
  else
    ok "check-on-edit.sh stdout empty on clean .go file"
  fi
else
  fail "missing check-on-edit.sh"
fi

# Claude source (dotfiles) must match live expectations
check_claude "claude-source" "$ROOT/home/.claude/settings.json" || FAIL=1

for pair in \
  "claude-live:${HOME}/.claude/settings.json" \
  "claude-a-live:${HOME}/.claude-a/settings.json" \
  "claude-token-live:${HOME}/.claude-token/settings.json"
do
  label="${pair%%:*}"; path="${pair#*:}"
  [[ -f "$path" ]] || { warn "$label missing"; continue; }
  check_claude "$label" "$path" || FAIL=1
  hm_link_ok "$label" "$path"
done

if [[ -f "${HOME}/.gemini/settings.json" ]]; then
  python3 - <<'PY' || FAIL=1
import json
from pathlib import Path
import sys
hooks = json.loads((Path.home()/".gemini"/"settings.json").read_text()).get("hooks", {})
blob = json.dumps(hooks)
if "PostToolUse" not in hooks:
    print("FAIL: gemini-settings: no PostToolUse", file=sys.stderr); raise SystemExit(1)
if "fmt-on-edit" not in blob:
    print("FAIL: gemini-settings: no fmt-on-edit", file=sys.stderr); raise SystemExit(1)
if "PreToolUse" not in hooks or "enforce-bridge" not in blob:
    print("FAIL: gemini-settings: missing PreToolUse enforce gate", file=sys.stderr); raise SystemExit(1)
print("OK: gemini-settings: PreToolUse enforce + PostToolUse fmt")
PY
fi

# agy hooks live in ~/.gemini/config/hooks.json (shared), NOT antigravity-cli/settings.json
# (settings is model/permissions only — product contract; changelog 2026 moved /hooks writes here).
if [[ -f "${HOME}/.gemini/config/hooks.json" ]]; then
  python3 - <<'PY' || FAIL=1
import json, sys
from pathlib import Path
path = Path.home()/".gemini"/"config"/"hooks.json"
data = json.loads(path.read_text())
blob = json.dumps(data)
if "PreToolUse" not in blob or "enforce-bridge" not in blob:
    print("FAIL: gemini config/hooks.json missing PreToolUse enforce for agy", file=sys.stderr)
    raise SystemExit(1)
if "edit_file" not in blob and "Edit" not in blob:
    print("WARN: agy hooks.json has enforce but no edit_file/Edit matcher", file=sys.stderr)
print("OK: agy gate via ~/.gemini/config/hooks.json (PreToolUse enforce)")
# settings.json intentionally has no hooks key
settings = Path.home()/".gemini"/"antigravity-cli"/"settings.json"
if settings.exists():
    d = json.loads(settings.read_text())
    if d.get("hooks"):
        print("WARN: antigravity-cli/settings.json unexpectedly has hooks (split brain?)", file=sys.stderr)
    else:
        print("OK: antigravity-cli/settings.json is permissions-only (hooks elsewhere — correct)")
PY
else
  fail "missing ~/.gemini/config/hooks.json (agy gate path)"
fi

# githits auth — capability gate fuel (fail closed)
if ! "$ROOT/bin/prove-githits-auth.sh"; then
  FAIL=1
fi

if [[ "$FAIL" -ne 0 ]]; then
  echo "prove-harness-hooks: FAILED" >&2
  exit 1
fi
echo "prove-harness-hooks: ALL CHECKS PASSED (see WARNs)"
exit 0
