#!/usr/bin/env bash
# cocoindex health check — pgrep-based, daemon-wrapper compatible.
# Called by launchd every 5 minutes.
set -euo pipefail

NAME="cocoindex-health"
SOCKET="$HOME/.cocoindex_code/daemon.sock"

# Find the daemon process — daemon-wrapper uses exec -a, not PID files.
DAEMON_PID=$(pgrep -f "ccc run-daemon" 2>/dev/null | head -1 || true)

if [ -n "$DAEMON_PID" ] && kill -0 "$DAEMON_PID" 2>/dev/null; then
    if [ -S "$SOCKET" ]; then
        echo "[$NAME] OK — PID $DAEMON_PID, socket present"
        exit 0
    else
        echo "[$NAME] DEGRADED — PID $DAEMON_PID running but no socket"
        exit 1
    fi
fi

echo "[$NAME] DEGRADED — no daemon process"
exit 1
