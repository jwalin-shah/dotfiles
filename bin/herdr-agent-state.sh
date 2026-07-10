#!/usr/bin/env bash
# herdr-agent-state.sh - neutral, repo-owned SessionStart hook for ANY agent
# harness (Claude, Codex, Cursor, ...). Registers this pane as an AI agent with
# herdr so the multiplexer can natively track busy/idle/blocked state.
#
# Harness-neutral by design: the caller passes --source and --label, so there is
# no hardcoded harness identity to copy per harness. One script, deployed once,
# owned declaratively by home-manager. Silent no-op outside a herdr pane, and
# always exit 0 - this is advisory and must never block a session from starting.
#
# Usage: herdr-agent-state.sh [phase] --source <id> --label <name>
#   phase   positional, defaults to "session" (e.g. session/startup)
#   --source herdr agent source id (required in practice; falls back to --label)
#   --label  human-readable agent label (falls back to --source)
set -euo pipefail

phase="session"
source=""
label=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --source) source="${2:-}"; shift 2 ;;
    --label)  label="${2:-}";  shift 2 ;;
    --source=*) source="${1#*=}"; shift ;;
    --label=*)  label="${1#*=}";  shift ;;
    --) shift ;;
    *)  phase="$1"; shift ;;
  esac
done

# Only active inside a herdr pane with a resolvable pane id.
[ -n "${HERDR_ENV:-}" ] || exit 0
PANE_ID="${HERDR_PANE_ID:-}"
[ -n "$PANE_ID" ] || exit 0

# A misconfigured caller (no source/label) still reports something generic
# rather than falling back to a hardcoded harness identity.
source="${source:-${label:-agent}}"
label="${label:-$source}"

herdr pane report-agent "$PANE_ID" \
  --source "$source" \
  --agent "$label" \
  --state "idle" \
  --message "$label session starting ($phase)" \
  2>/dev/null || true

exit 0
