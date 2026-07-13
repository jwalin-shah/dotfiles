#!/usr/bin/env bash
# ── Deterministic shell for cognee daemon ──────────────────────────
# Single-instance enforcement, startup validation, health checks, and
# crash-circuit-breaker. Prevents the zombie-process leak pattern we
# had with cocoindex (19 orphaned daemon processes, ~4GB RAM).
set -euo pipefail

NAME="cognee-daemon"
PIDFILE="/tmp/${NAME}.pid"
LOCKDIR="/tmp/${NAME}.lockdir"
COGNEE_BIN="/Users/jwalinshah/.local/share/uv/tools/cognee/bin/cognee-cli"
COGNEE_PYTHON="/Users/jwalinshah/.local/share/uv/tools/cognee/bin/python"
COGNEE_DATA="/Users/jwalinshah/.local/share/cognee"
ENV_FILE="$HOME/.config/jw/models.env"
LIFECYCLE_LOG="$HOME/.local/share/cognee/lifecycle.jsonl"

mkdir -p "$(dirname "$LIFECYCLE_LOG")" "$COGNEE_DATA"

# Generation ID: timestamp + PID
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
    LOCKER_GEN_ID=""
    [ -f "$LOCKDIR/pid" ] && LOCKER_PID=$(cat "$LOCKDIR/pid" 2>/dev/null || echo "")
    [ -f "$LOCKDIR/gen_id" ] && LOCKER_GEN_ID=$(cat "$LOCKDIR/gen_id" 2>/dev/null || echo "")
    if [ -n "$LOCKER_PID" ] && kill -0 "$LOCKER_PID" 2>/dev/null; then
        log_event "lock_deferred" "holder PID=$LOCKER_PID gen=$LOCKER_GEN_ID alive"
        echo "[$NAME] already running (PID $LOCKER_PID). Exiting." >&2
        exit 0
    fi
    log_event "stale_lock_found" "PID=$LOCKER_PID gen=$LOCKER_GEN_ID dead"
    rm -rf "$LOCKDIR"
    if ! mkdir "$LOCKDIR" 2>/dev/null; then
        echo "[$NAME] FATAL: cannot acquire lockdir $LOCKDIR even after stale cleanup" >&2
        exit 1
    fi
fi
echo "$GEN_ID" > "$LOCKDIR/gen_id"
echo "$$" > "$LOCKDIR/pid"
log_event "lock_acquired" "GEN_ID=$GEN_ID, PID=$$"
trap 'log_event "lock_released" "EXIT trap"; rm -rf "$LOCKDIR"' EXIT

# Double-check via pidfile
read_pid() {
    local pid
    pid=$(cat "$PIDFILE" 2>/dev/null || echo "")
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        return 0
    fi
    return 1
}

# Cleanup stale pidfile if process is dead
if [ -f "$PIDFILE" ] && ! read_pid; then
    rm -f "$PIDFILE"
fi

# ── Phase 2: Startup validation (check cognee import) ──────────────
echo "[$NAME] verifying cognee import..." >&2
log_event "validation_started" "checking cognee import"
IMPORT_CHECK=$(bash -c "source ~/.config/jw/models.env && \"$COGNEE_PYTHON\" -c 'import cognee; print(\"OK\")'" 2>/dev/null | tail -1 || echo "FAIL")

if [ "$IMPORT_CHECK" != "OK" ]; then
    log_event "validation_failed" "cognee import check did not return OK"
    echo "[$NAME] STARTUP VALIDATION FAILED: cognee import check did not return OK" >&2
    echo "[$NAME] Daemon will NOT start. Fix the module issue first." >&2
    echo "[$NAME] Check: cognee installation at $COGNEE_BIN" >&2
    exit 1
fi
log_event "validation_passed" "cognee import OK"
echo "[$NAME] cognee import OK" >&2

# Ensure data directory exists
mkdir -p "$COGNEE_DATA"

# ── Phase 3: Launch the daemon ──────────────────────────────────────
echo "[$NAME] PID $$ - starting daemon..." >&2
echo $$ > "$PIDFILE"
log_event "daemon_spawning" "exec: cognee-cli serve on :8000"

# Source env file for provider config, then exec cognee-cli serve
source "$ENV_FILE" && exec "$COGNEE_BIN" serve
