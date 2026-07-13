#!/usr/bin/env bash
# ── mlx-chat health check ───────────────────────────────────────────
# Called by launchd every 5 minutes. Reports status, cleans up
# orphaned zombie processes. Logs structured events for trace refinement.
set -euo pipefail

NAME="mlx-chat-health"
PIDFILE="/tmp/mlx-chat-daemon.pid"
LOCKDIR="/tmp/mlx-chat-daemon.lockdir"
PORT=8080
LIFECYCLE_LOG="$HOME/.local/share/mlx-chat/lifecycle.jsonl"

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

if [ -n "$DAEMON_PID" ] && kill -0 "$DAEMON_PID" 2>/dev/null; then
    HTTP_OK=$(curl --max-time 2 -s -o /dev/null -w "%{http_code}" http://127.0.0.1:"$PORT"/health 2>/dev/null || \
              curl --max-time 2 -s -o /dev/null -w "%{http_code}" http://127.0.0.1:"$PORT"/ 2>/dev/null || echo "000")
    if [ "$HTTP_OK" != "000" ]; then
        log_event "health_check_ok" "PID $DAEMON_PID gen=$LOCKER_GEN_ID HTTP $HTTP_OK"
        exit 0
    else
        log_event "health_check_degraded" "PID $DAEMON_PID gen=$LOCKER_GEN_ID port $PORT not responding"
        exit 1
    fi
fi

# Daemon is dead
log_event "daemon_dead_detected" "gen=$LOCKER_GEN_ID PID=$DAEMON_PID"
ORPHANS=$(pgrep -f "mlx_lm.server" 2>/dev/null || true)
if [ -n "$ORPHANS" ]; then
    ORPHAN_COUNT=$(echo "$ORPHANS" | wc -l | tr -d ' ')
    log_event "orphans_found" "$ORPHAN_COUNT orphaned: $ORPHANS"
    echo "[$NAME] killing $ORPHAN_COUNT orphaned processes"
    kill "$ORPHANS" 2>/dev/null || true
fi

if [ -d "$LOCKDIR" ]; then
    log_event "stale_lock_cleaned" "gen=$LOCKER_GEN_ID"
    rm -rf "$LOCKDIR"
fi

log_event "health_check_completed" "awaiting launchd restart"
rm -f "$PIDFILE"
exit 1
