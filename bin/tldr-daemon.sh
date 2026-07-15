#!/usr/bin/env bash
# ── Deterministic shell for tldr daemon ────────────────────────────────
# Watches ~/projects for file changes and auto-refreshes the tldr
# call-graph index. Index lives at ~/projects/.tldr/cache/.
#
# Single-instance enforcement via lockdir, lifecycle event logging.
# Pattern follows cocoindex-daemon.sh.
set -euo pipefail

NAME="tldr-daemon"
LOCKDIR="/tmp/${NAME}.lockdir"
TLDR_BIN="$HOME/.local/share/uv/tools/llm-tldr/bin/llm-tldr"
WATCH_DIR="$HOME/projects"

# ── Event log (structured, JSONL, for trace refinement) ────────────
LIFECYCLE_LOG_DIR="$HOME/.local/share/jw"
LIFECYCLE_LOG="$LIFECYCLE_LOG_DIR/tldr-daemon-lifecycle.jsonl"
mkdir -p "$LIFECYCLE_LOG_DIR"

GEN_ID="$(date +%s)-$$"

log_event() {
    local event="$1"
    local detail="${2:-}"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S%z")
    printf '{"gen_id":"%s","event":"%s","timestamp":"%s","pid":%d,"detail":"%s"}\n' \
        "$GEN_ID" "$event" "$timestamp" "$$" "$detail" >> "$LIFECYCLE_LOG"
}

log_event "wrapper_started" "PID=$$, GEN_ID=$GEN_ID"

# ── Phase 1: Single-instance enforcement ────────────────────────────
if ! mkdir "$LOCKDIR" 2>/dev/null; then
    LOCKER_PID=""
    [ -f "$LOCKDIR/pid" ] && LOCKER_PID=$(cat "$LOCKDIR/pid" 2>/dev/null || echo "")

    if [ -n "$LOCKER_PID" ] && kill -0 "$LOCKER_PID" 2>/dev/null; then
        log_event "lock_deferred" "holder PID=$LOCKER_PID still alive"
        echo "[$NAME] already running (PID $LOCKER_PID). Exiting." >&2
        exit 75
    fi

    log_event "stale_lock_found" "PID=$LOCKER_PID dead, reclaiming"
    rm -rf "$LOCKDIR"
    if ! mkdir "$LOCKDIR" 2>/dev/null; then
        log_event "lock_fatal" "cannot acquire lockdir even after stale cleanup"
        echo "[$NAME] FATAL: cannot acquire lockdir $LOCKDIR even after stale cleanup" >&2
        exit 1
    fi
    log_event "stale_lock_reclaimed" "lockdir reclaimed"
fi

echo "$GEN_ID" > "$LOCKDIR/gen_id"
echo "$$" > "$LOCKDIR/pid"
log_event "lock_acquired" "GEN_ID=$GEN_ID, PID=$$"

trap 'log_event "lock_released" "EXIT trap cleaning up"; rm -rf "$LOCKDIR"' EXIT

# ── Phase 2: Startup validation ──────────────────────────────────────
if [ ! -x "$TLDR_BIN" ]; then
    log_event "validation_failed" "tldr binary not found at $TLDR_BIN"
    echo "[$NAME] STARTUP VALIDATION FAILED: tldr binary not found at $TLDR_BIN" >&2
    exit 1
fi
log_event "validation_passed" "tldr binary found at $TLDR_BIN"

# ── Phase 3: Launch the daemon ───────────────────────────────────────
echo "[$NAME] PID $$ — starting daemon, watching $WATCH_DIR..." >&2
log_event "daemon_spawning" "exec: $TLDR_BIN daemon start --project $WATCH_DIR"

exec "$TLDR_BIN" daemon start --project "$WATCH_DIR"
# exec replaces process — log_event after this never runs.
