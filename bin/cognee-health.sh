#!/usr/bin/env bash
# ── cognee health check ─────────────────────────────────────────────
# Called by launchd every 5 minutes. Reports status, cleans up
# orphaned zombie processes if the daemon silently died.
set -euo pipefail

NAME="cognee-health"
PIDFILE="/tmp/cognee-daemon.pid"
COGNEE_DATA="/Users/jwalinshah/.local/share/cognee"

# Check 1: Is a daemon process alive?
DAEMON_PID=""
if [ -f "$PIDFILE" ]; then
    DAEMON_PID=$(cat "$PIDFILE" 2>/dev/null || echo "")
fi

if [ -z "$DAEMON_PID" ] || ! kill -0 "$DAEMON_PID" 2>/dev/null; then
    # Daemon is dead. Clean up any orphans.
    echo "[$NAME] DAEMON DEAD - cleaning up orphans..."
    ORPHANS=$(pgrep -f "cognee-cli serve" 2>/dev/null || true)
    if [ -n "$ORPHANS" ]; then
        echo "[$NAME] killing $ORPHANS orphaned processes"
        kill "$ORPHANS" 2>/dev/null || true
    fi

    # Clean up stale lockdir if present
    if [ -d "/tmp/cognee-daemon.lockdir" ]; then
        rm -rf "/tmp/cognee-daemon.lockdir"
    fi

    # launchd will restart it via KeepAlive, but let's log the gap.
    echo "[$NAME] daemon will be restarted by launchd"
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
    echo "[$NAME] OK - daemon PID $DAEMON_PID, HTTP responding, $DATA_STATUS"
    exit 0
else
    echo "[$NAME] DEGRADED - daemon PID $DAEMON_PID running but HTTP not responding, $DATA_STATUS"
    exit 1
fi
