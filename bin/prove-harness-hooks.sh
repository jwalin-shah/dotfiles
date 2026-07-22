#!/usr/bin/env bash
# prove-harness-hooks.sh — docs-backed event names must match live configs.
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

ROOT="${HOME}/projects/dotfiles"
FAIL=0
ok() { echo "OK: $*"; }
warn() { echo "WARN: $*" >&2; }
fail() { echo "FAIL: $*" >&2; FAIL=1; }

"$ROOT/bin/prove-cursor-hooks.sh" \
  "$ROOT/home/.cursor/hooks.json" \
  "${HOME}/.cursor/hooks.json" || FAIL=1

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
  case "$(readlink "${HOME}/.codex/hooks.json" 2>/dev/null || true)" in
    /nix/store/*) warn "codex-live nix-store backed — force symlink + rebuild recommended" ;;
  esac
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
print(f"OK: {label}: PreToolUse+PostToolUse with enforce+fmt")
PY
}

for pair in \
  "claude-live:${HOME}/.claude/settings.json" \
  "claude-a-live:${HOME}/.claude-a/settings.json" \
  "claude-token-live:${HOME}/.claude-token/settings.json"
do
  label="${pair%%:*}"; path="${pair#*:}"
  [[ -f "$path" ]] || { warn "$label missing"; continue; }
  check_claude "$label" "$path" || FAIL=1
  case "$(readlink "$path" 2>/dev/null || true)" in
    /nix/store/*) warn "$label nix-store backed — force symlink + rebuild recommended" ;;
  esac
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
if "enforce-bridge" not in blob and "PreToolUse" not in hooks:
    print("WARN: gemini-settings: fmt only — no PreToolUse gate (agy gap)", file=sys.stderr)
print("OK: gemini-settings: PostToolUse+fmt present")
PY
fi

if [[ -f "${HOME}/.gemini/antigravity-cli/settings.json" ]]; then
  python3 - <<'PY'
import json
from pathlib import Path
d = json.loads((Path.home()/".gemini"/"antigravity-cli"/"settings.json").read_text())
if d.get("hooks"):
    print("OK: antigravity-cli has hooks object")
else:
    print("WARN: antigravity-cli settings have no hooks — do not claim ✅ wired", file=__import__("sys").stderr)
PY
fi

if [[ ! -x "$ROOT/bin/audit-hook-ownership.sh" ]]; then
  warn "HOOKS.md cites audit-hook-ownership.sh but it is missing — use prove-harness-hooks.sh"
fi

if [[ "$FAIL" -ne 0 ]]; then
  echo "prove-harness-hooks: FAILED" >&2
  exit 1
fi
echo "prove-harness-hooks: ALL CHECKS PASSED (see WARNs)"
exit 0
