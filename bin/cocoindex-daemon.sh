#!/usr/bin/env bash
# ── Deterministic shell for cocoindex daemon ──────────────────────────
# Single-instance enforcement, startup validation, health checks, and
# crash-circuit-breaker. Prevents the zombie-process leak we had (19
# orphaned daemon processes, ~4GB RAM).
set -euo pipefail

NAME="cocoindex-daemon"
SOCKET="$HOME/.cocoindex_code/daemon.sock"
PIDFILE="/tmp/${NAME}.pid"
LOCKDIR="/tmp/${NAME}.lockdir"
EXTENSIONS_DIR="$HOME/.cocoindex_code/extensions"
UV_PYTHON="$HOME/.local/share/uv/tools/cocoindex-code/bin/python"
CCC_BIN="$HOME/.local/share/uv/tools/cocoindex-code/bin/ccc"
UV_SITE="$HOME/.local/share/uv/tools/cocoindex-code/lib/python3.13/site-packages"

# ── Phase 1: Single-instance enforcement ────────────────────────────
# Use mkdir as atomic lock (works on macOS, flock is not available).
# If lockdir exists, check if the locking process is still alive.
if ! mkdir "$LOCKDIR" 2>/dev/null; then
    # Stale lock recovery: read the locker PID, clean up if dead
    LOCKER_PID=""
    [ -f "$LOCKDIR/pid" ] && LOCKER_PID=$(cat "$LOCKDIR/pid" 2>/dev/null || echo "")
    if [ -n "$LOCKER_PID" ] && kill -0 "$LOCKER_PID" 2>/dev/null; then
        echo "[$NAME] already running (PID $LOCKER_PID). Exiting." >&2
        exit 0
    fi
    # Locker is dead — reclaim the lock
    rm -rf "$LOCKDIR"
    if ! mkdir "$LOCKDIR" 2>/dev/null; then
        echo "[$NAME] FATAL: cannot acquire lockdir $LOCKDIR even after stale cleanup" >&2
        exit 1
    fi
fi
# Write our PID into the lockdir so recovery works
echo $$ > "$LOCKDIR/pid"
trap 'rm -rf "$LOCKDIR"' EXIT

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

# ── Phase 2: Startup validation (check imports before running) ──────
echo "[$NAME] verifying tldr_chunker import..." >&2
IMPORT_CHECK=$(PYTHONPATH="$EXTENSIONS_DIR:$UV_SITE" "$UV_PYTHON" -c "
import sys
sys.path.insert(0, '$EXTENSIONS_DIR')
sys.path.insert(0, '$UV_SITE')
try:
    mod = __import__('tldr_chunker', fromlist=['chunk'])
    print('OK: tldr_chunker.chunk loaded')
except Exception as e:
    print(f'FAIL: {e}')
    sys.exit(1)
" 2>&1)

if [ $? -ne 0 ]; then
    echo "[$NAME] STARTUP VALIDATION FAILED: $IMPORT_CHECK" >&2
    echo "[$NAME] Daemon will NOT start. Fix the module issue first." >&2
    echo "[$NAME] Check: $EXTENSIONS_DIR/tldr_chunker.py" >&2
    exit 1
fi
echo "[$NAME] $IMPORT_CHECK" >&2

# ── Phase 3: Launch the daemon ──────────────────────────────────────
echo "[$NAME] PID $$ — starting daemon..." >&2
echo $$ > "$PIDFILE"

PYTHONPATH="$EXTENSIONS_DIR:$UV_SITE" \
    exec "$CCC_BIN" run-daemon
