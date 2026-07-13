#!/usr/bin/env bash
# ── cocoindex health check ──────────────────────────────────────────
# Called by launchd every 5 minutes. Reports status, cleans up
# orphaned zombie processes if the daemon silently died.
# Logs structured events for trace refinement against TLA+ model.
set -euo pipefail

NAME="cocoindex-health"
SOCKET="$HOME/.cocoindex_code/daemon.sock"
PIDFILE="/tmp/cocoindex-daemon.pid"
LOCKDIR="/tmp/cocoindex-daemon.lockdir"
LIFECYCLE_LOG="$HOME/.local/share/cocoindex/lifecycle.jsonl"

log_event() {
    local event="$1"
    local detail="${2:-}"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S%z")
    printf '{"gen_id":"health","event":"%s","timestamp":"%s","pid":%d,"detail":"%s"}\n' \
        "$event" "$timestamp" "$$" "$detail" >> "$LIFECYCLE_LOG"
}

log_event "health_check_started" "beginning periodic check"

# Read generation ID from lockdir (if it exists) for generation-aware checks
LOCKER_GEN_ID=""
LOCKER_PID=""
if [ -f "$LOCKDIR/gen_id" ]; then
    LOCKER_GEN_ID=$(cat "$LOCKDIR/gen_id" 2>/dev/null || echo "")
fi
if [ -f "$LOCKDIR/pid" ]; then
    LOCKER_PID=$(cat "$LOCKDIR/pid" 2>/dev/null || echo "")
fi

# Check 1: Is a daemon process alive?
DAEMON_PID=""
if [ -f "$PIDFILE" ]; then
    DAEMON_PID=$(cat "$PIDFILE" 2>/dev/null || echo "")
fi

if [ -n "$DAEMON_PID" ] && kill -0 "$DAEMON_PID" 2>/dev/null; then
    # Daemon PID is alive — check generation consistency
    if [ -n "$LOCKER_PID" ] && [ "$LOCKER_PID" != "$DAEMON_PID" ]; then
        # Lockdir PID doesn't match daemon PID — generation mismatch
        log_event "generation_mismatch" "lockdir PID=$LOCKER_PID, daemon PID=$DAEMON_PID"
    fi

    # Check 2: Does it respond on the socket (if socket exists)?
    if [ -S "$SOCKET" ]; then
        log_event "health_check_ok" "daemon PID $DAEMON_PID, gen=$LOCKER_GEN_ID, socket present"
        echo "[$NAME] OK — daemon PID $DAEMON_PID, socket present"
        exit 0
    else
        log_event "health_check_degraded" "daemon PID $DAEMON_PID, gen=$LOCKER_GEN_ID, no socket"
        echo "[$NAME] DEGRADED — daemon PID $DAEMON_PID running but no socket"
        # Don't kill — might be between index operations
        exit 1
    fi
fi

# Daemon is dead. Read the lockdir generation for trace continuity.
log_event "daemon_dead_detected" "gen=$LOCKER_GEN_ID, PID=$DAEMON_PID"

# Check for orphaned processes (DL-004 violation detection)
ORPHAN_COUNT=0
ORPHANS=$(pgrep -f "ccc run-daemon" 2>/dev/null || true)
if [ -n "$ORPHANS" ]; then
    ORPHAN_COUNT=$(echo "$ORPHANS" | wc -l | tr -d ' ')
    log_event "orphans_found" "$ORPHAN_COUNT orphaned processes: $ORPHANS"
    echo "[$NAME] killing $ORPHAN_COUNT orphaned processes"
    kill "$ORPHANS" 2>/dev/null || true
fi

if [ -d "$LOCKDIR" ]; then
    # Clean stale lockdir (DL-003: ownership-safe cleanup)
    log_event "stale_lock_cleaned" "gen=$LOCKER_GEN_ID, PID=$LOCKER_PID, orphans=$ORPHAN_COUNT"
    rm -rf "$LOCKDIR"
fi

# launchd will restart it via KeepAlive
log_event "health_check_completed" "daemon dead, cleanup done, awaiting launchd restart"
echo "[$NAME] daemon will be restarted by launchd"
rm -f "$PIDFILE"
exit 1
