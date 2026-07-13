#!/usr/bin/env bash
# ── mlx-chat health check ───────────────────────────────────────────
# Called by launchd every 5 minutes. Reports status, cleans up
# orphaned zombie processes if the daemon silently died.
set -euo pipefail

NAME="mlx-chat-health"
PIDFILE="/tmp/mlx-chat-daemon.pid"
PORT=8080

# Check 1: Is a daemon process alive?
DAEMON_PID=""
if [ -f "$PIDFILE" ]; then
    DAEMON_PID=$(cat "$PIDFILE" 2>/dev/null || echo "")
fi

if [ -n "$DAEMON_PID" ] && kill -0 "$DAEMON_PID" 2>/dev/null; then
    # Check 2: Does it respond on the HTTP port?
    HTTP_OK=$(curl --max-time 2 -s -o /dev/null -w "%{http_code}" http://127.0.0.1:"$PORT"/health 2>/dev/null || \
              curl --max-time 2 -s -o /dev/null -w "%{http_code}" http://127.0.0.1:"$PORT"/ 2>/dev/null || echo "000")
    if [ "$HTTP_OK" != "000" ]; then
        echo "[$NAME] OK — daemon PID $DAEMON_PID, HTTP $HTTP_OK on port $PORT"
        exit 0
    else
        echo "[$NAME] DEGRADED — daemon PID $DAEMON_PID running but port $PORT not responding"
        # Don't kill — might be loading a model
        exit 1
    fi
fi

# Daemon is dead. Clean up any orphans.
echo "[$NAME] DAEMON DEAD — cleaning up orphans..."
ORPHANS=$(pgrep -f "mlx_lm.server" 2>/dev/null || true)
if [ -n "$ORPHANS" ]; then
    echo "[$NAME] killing $ORPHANS orphaned processes"
    kill "$ORPHANS" 2>/dev/null || true
fi

# launchd will restart it via KeepAlive, but let's log the gap.
echo "[$NAME] daemon will be restarted by launchd"
rm -f "$PIDFILE"
exit 1
