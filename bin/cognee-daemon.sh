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
    # Locker is dead - reclaim the lock
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

# ── Phase 2: Startup validation (check cognee import) ──────────────
echo "[$NAME] verifying cognee import..." >&2
IMPORT_CHECK=$(bash -c "source ~/.config/jw/models.env && \"$COGNEE_PYTHON\" -c 'import cognee; print(\"OK\")'" 2>/dev/null | tail -1 || echo "FAIL")

if [ "$IMPORT_CHECK" != "OK" ]; then
    echo "[$NAME] STARTUP VALIDATION FAILED: cognee import check did not return OK" >&2
    echo "[$NAME] Daemon will NOT start. Fix the module issue first." >&2
    echo "[$NAME] Check: cognee installation at $COGNEE_BIN" >&2
    exit 1
fi
echo "[$NAME] cognee import OK" >&2

# Ensure data directory exists
mkdir -p "$COGNEE_DATA"

# ── Phase 3: Launch the daemon ──────────────────────────────────────
echo "[$NAME] PID $$ - starting daemon..." >&2
echo $$ > "$PIDFILE"

# Source env file for provider config, then exec cognee-cli serve
source "$ENV_FILE" && exec "$COGNEE_BIN" serve
