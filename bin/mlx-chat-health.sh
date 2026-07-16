#!/usr/bin/env bash
# mlx-chat health check — pgrep-based, daemon-wrapper compatible.
# Called by launchd every 5 minutes.
set -euo pipefail

NAME="mlx-chat-health"
PORT=8080

# Find the daemon process — daemon-wrapper uses exec -a, not PID files.
DAEMON_PID=$(pgrep -f "mlx_lm.server.*port $PORT" 2>/dev/null | head -1 || true)

if [ -n "$DAEMON_PID" ] && kill -0 "$DAEMON_PID" 2>/dev/null; then
    HTTP_CODE=$(curl --max-time 3 -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:$PORT/" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" != "000" ]; then
        echo "[$NAME] OK — PID $DAEMON_PID, HTTP $HTTP_CODE"
        exit 0
    fi
    echo "[$NAME] DEGRADED — PID $DAEMON_PID running but port $PORT not responding"
    exit 1
fi

echo "[$NAME] DEGRADED — no daemon process on port $PORT"
exit 1
