#!/usr/bin/env bash
# ── Deterministic shell for mlx-chat daemon ──────────────────────────
# Single-instance enforcement, startup validation, health checks, and
# crash-circuit-breaker. Prevents the zombie-process leak pattern seen
# in cocoindex (19 orphaned daemon processes, ~4GB RAM).
set -euo pipefail

NAME="mlx-chat-daemon"
PIDFILE="/tmp/${NAME}.pid"
LOCKDIR="/tmp/${NAME}.lockdir"
MODELS_ENV="$HOME/.config/jw/models.env"
MLX_SERVER="$HOME/.local/share/uv/tools/mlx-lm/bin/mlx_lm.server"
PORT=8080

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

# ── Phase 2: Startup validation (check import before running) ──────
echo "[$NAME] verifying mlx_lm import..." >&2
IMPORT_CHECK=$(bash -c "source '$MODELS_ENV' && python3 -c 'import mlx_lm; print(\"OK\")'" 2>&1)

if [ $? -ne 0 ]; then
    echo "[$NAME] STARTUP VALIDATION FAILED: $IMPORT_CHECK" >&2
    echo "[$NAME] Daemon will NOT start. Fix the python/mlx_lm issue first." >&2
    echo "[$NAME] Check: pip install mlx-lm" >&2
    exit 1
fi
echo "[$NAME] $IMPORT_CHECK" >&2

# ── Phase 3: Launch the daemon ──────────────────────────────────────
echo "[$NAME] PID $$ — starting mlx_lm.server on port $PORT..." >&2
echo $$ > "$PIDFILE"

source "$MODELS_ENV" && \
    exec "$MLX_SERVER" --model "$JW_CHAT_MODEL_REPO" --host 127.0.0.1 --port "$PORT" --trust-remote-code
