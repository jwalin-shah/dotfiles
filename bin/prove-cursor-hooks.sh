#!/usr/bin/env bash
# prove-cursor-hooks.sh — fail if Cursor hooks.json uses invalid event names.
# Proves declaration matches Cursor schema (not Claude PostToolUse).
set -euo pipefail

HOOKS="${1:-$HOME/projects/dotfiles/home/.cursor/hooks.json}"
LIVE="${HOME}/.cursor/hooks.json"

python3 - "$HOOKS" "$LIVE" <<'PY'
import json, sys
from pathlib import Path

valid = {
    "sessionStart", "sessionEnd", "preToolUse", "postToolUse", "postToolUseFailure",
    "subagentStart", "subagentStop", "beforeShellExecution", "afterShellExecution",
    "beforeMCPExecution", "afterMCPExecution", "beforeReadFile", "afterFileEdit",
    "beforeSubmitPrompt", "preCompact", "stop", "afterAgentResponse", "afterAgentThought",
    "beforeTabFileRead", "afterTabFileEdit", "workspaceOpen",
}

src = Path(sys.argv[1])
live = Path(sys.argv[2])
data = json.loads(src.read_text())
keys = set(data.get("hooks", {}))
bad = sorted(keys - valid)
if bad:
    print(f"FAIL: invalid Cursor hook events in {src}: {bad}", file=sys.stderr)
    print("  Cursor uses camelCase (afterFileEdit, preToolUse). Claude uses PostToolUse.", file=sys.stderr)
    sys.exit(1)
print(f"OK: source hooks events valid: {sorted(keys)}")

if live.exists():
    try:
        live_data = json.loads(live.read_text())
    except Exception as e:
        print(f"WARN: cannot read live {live}: {e}")
        sys.exit(0)
    live_keys = set(live_data.get("hooks", {}))
    live_bad = sorted(live_keys - valid)
    if live_bad:
        print(f"FAIL: live ~/.cursor/hooks.json still has invalid events: {live_bad}", file=sys.stderr)
        print("  Run ./rebuild.sh (hooks.json needs force symlink) or fix live file.", file=sys.stderr)
        sys.exit(1)
    if live_keys != keys:
        print(f"WARN: live events {sorted(live_keys)} != source {sorted(keys)} — rebuild may be needed")
    else:
        print("OK: live ~/.cursor/hooks.json matches source event set")
else:
    print("WARN: no live ~/.cursor/hooks.json")
PY
