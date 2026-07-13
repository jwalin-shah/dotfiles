#!/usr/bin/env bash
# ── cocoindex health check ──────────────────────────────────────────
# Called by launchd every 5 minutes. Reports status, cleans up
# orphaned zombie processes if the daemon silently died.
set -euo pipefail

NAME="cocoindex-health"
SOCKET="$HOME/.cocoindex_code/daemon.sock"
PIDFILE="/tmp/cocoindex-daemon.pid"

# Check 1: Is a daemon process alive?
DAEMON_PID=""
if [ -f "$PIDFILE" ]; then
    DAEMON_PID=$(cat "$PIDFILE" 2>/dev/null || echo "")
fi

if [ -n "$DAEMON_PID" ] && kill -0 "$DAEMON_PID" 2>/dev/null; then
    # Check 2: Does it respond on the socket (if socket exists)?
    if [ -S "$SOCKET" ]; then
        echo "[$NAME] OK — daemon PID $DAEMON_PID, socket present"
        exit 0
    else
        echo "[$NAME] DEGRADED — daemon PID $DAEMON_PID running but no socket"
        # Don't kill — might be between index operations
        exit 1
    fi
fi

# Daemon is dead. Clean up any orphans.
echo "[$NAME] DAEMON DEAD — cleaning up orphans..."
ORPHANS=$(pgrep -f "ccc run-daemon" 2>/dev/null || true)
if [ -n "$ORPHANS" ]; then
    echo "[$NAME] killing $ORPHANS orphaned processes"
    kill "$ORPHANS" 2>/dev/null || true
fi

# launchd will restart it via KeepAlive, but let's log the gap.
echo "[$NAME] daemon will be restarted by launchd"
rm -f "$PIDFILE"
exit 1
