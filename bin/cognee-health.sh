#!/usr/bin/env bash
# ── cognee health check ─────────────────────────────────────────────
# Called by launchd every 5 minutes. Reports status, cleans up
# orphaned zombie processes. Logs structured events for trace refinement.
set -euo pipefail

NAME="cognee-health"
PIDFILE="/tmp/cognee-daemon.pid"
LOCKDIR="/tmp/cognee-daemon.lockdir"
COGNEE_DATA="/Users/jwalinshah/.local/share/cognee"
LIFECYCLE_LOG="$COGNEE_DATA/lifecycle.jsonl"

log_event() {
    local event="$1"
    local detail="${2:-}"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S%z")
    printf '{"gen_id":"health","event":"%s","timestamp":"%s","pid":%d,"detail":"%s"}\n' \
        "$event" "$timestamp" "$$" "$detail" >> "$LIFECYCLE_LOG"
}

log_event "health_check_started" "beginning periodic check"

LOCKER_GEN_ID=""
[ -f "$LOCKDIR/gen_id" ] && LOCKER_GEN_ID=$(cat "$LOCKDIR/gen_id" 2>/dev/null || echo "")

# Check 1: Is a daemon process alive?
DAEMON_PID=""
if [ -f "$PIDFILE" ]; then
    DAEMON_PID=$(cat "$PIDFILE" 2>/dev/null || echo "")
fi

if [ -z "$DAEMON_PID" ] || ! kill -0 "$DAEMON_PID" 2>/dev/null; then
    log_event "daemon_dead_detected" "gen=$LOCKER_GEN_ID PID=$DAEMON_PID"
    echo "[$NAME] DAEMON DEAD - cleaning up orphans..."
    ORPHANS=$(pgrep -f "cognee-cli serve" 2>/dev/null || true)
    if [ -n "$ORPHANS" ]; then
        ORPHAN_COUNT=$(echo "$ORPHANS" | wc -l | tr -d ' ')
        log_event "orphans_found" "$ORPHAN_COUNT orphaned: $ORPHANS"
        kill "$ORPHANS" 2>/dev/null || true
    fi
    if [ -d "$LOCKDIR" ]; then
        log_event "stale_lock_cleaned" "gen=$LOCKER_GEN_ID"
        rm -rf "$LOCKDIR"
    fi
    log_event "health_check_completed" "awaiting launchd restart"
    rm -f "$PIDFILE"
    exit 1
fi

# Check 2: Probe the HTTP health endpoint
HEALTH_RESPONSE=$(curl --max-time 2 http://127.0.0.1:8000/health 2>/dev/null || true)

# Check 3: Verify cognee data directory exists
if [ -d "$COGNEE_DATA" ]; then
    DATA_STATUS="data dir present"
else
    DATA_STATUS="data dir MISSING"
fi

if [ -n "$HEALTH_RESPONSE" ]; then
    log_event "health_check_ok" "PID $DAEMON_PID gen=$LOCKER_GEN_ID HTTP ok $DATA_STATUS"
    echo "[$NAME] OK - daemon PID $DAEMON_PID, HTTP responding, $DATA_STATUS"
    exit 0
else
    log_event "health_check_degraded" "PID $DAEMON_PID gen=$LOCKER_GEN_ID HTTP not responding $DATA_STATUS"
    echo "[$NAME] DEGRADED - daemon PID $DAEMON_PID running but HTTP not responding, $DATA_STATUS"
    exit 1
fi
