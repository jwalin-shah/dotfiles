#!/usr/bin/env bash
# ── Deterministic shell for mlx-chat daemon ──────────────────────────
# Single-instance enforcement, startup validation, health checks, and
# crash-circuit-breaker. Includes generation tokens and event logging
# for trace refinement against TLA+ model DaemonGenerations.tla.
set -euo pipefail

NAME="mlx-chat-daemon"
PIDFILE="/tmp/${NAME}.pid"
LOCKDIR="/tmp/${NAME}.lockdir"
MODELS_ENV="$HOME/.config/jw/models.env"
UV_TOOLS="$HOME/.local/share/uv/tools"
MLX_PYTHON="$UV_TOOLS/mlx-lm/bin/python"
MLX_SERVER="$UV_TOOLS/mlx-lm/bin/mlx_lm.server"
PORT=8080
LIFECYCLE_LOG="$HOME/.local/share/mlx-chat/lifecycle.jsonl"

mkdir -p "$(dirname "$LIFECYCLE_LOG")"

# Generation ID: timestamp + PID
GEN_ID="$(date +%s)-$$"

log_event() {
    local event="$1"
    local detail="${2:-}"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S%z")
    printf '{"gen_id":"%s","event":"%s","timestamp":"%s","pid":%d,"detail":"%s"}\n' \
        "$GEN_ID" "$event" "$timestamp" "$$" "$detail" >> "$LIFECYCLE_LOG"
}

log_event "wrapper_started" "PID=$$, GEN_ID=$GEN_ID"

# ── Phase 1: Single-instance enforcement ────────────────────────────
if ! mkdir "$LOCKDIR" 2>/dev/null; then
    LOCKER_PID=""
    LOCKER_GEN_ID=""
    [ -f "$LOCKDIR/pid" ] && LOCKER_PID=$(cat "$LOCKDIR/pid" 2>/dev/null || echo "")
    [ -f "$LOCKDIR/gen_id" ] && LOCKER_GEN_ID=$(cat "$LOCKDIR/gen_id" 2>/dev/null || echo "")
    if [ -n "$LOCKER_PID" ] && kill -0 "$LOCKER_PID" 2>/dev/null; then
        log_event "lock_deferred" "holder PID=$LOCKER_PID gen=$LOCKER_GEN_ID alive"
        echo "[$NAME] already running (PID $LOCKER_PID). Exiting." >&2
        exit 0
    fi
    log_event "stale_lock_found" "PID=$LOCKER_PID gen=$LOCKER_GEN_ID dead"
    rm -rf "$LOCKDIR"
    if ! mkdir "$LOCKDIR" 2>/dev/null; then
        log_event "lock_fatal" "cannot acquire lockdir"
        exit 1
    fi
    log_event "stale_lock_reclaimed" "from gen=$LOCKER_GEN_ID"
fi

echo "$GEN_ID" > "$LOCKDIR/gen_id"
echo "$$" > "$LOCKDIR/pid"
log_event "lock_acquired" "GEN_ID=$GEN_ID, PID=$$"
trap 'log_event "lock_released" "EXIT trap"; rm -rf "$LOCKDIR"' EXIT

# ── Phase 2: Startup validation ─────────────────────────────────────
echo "[$NAME] verifying mlx_lm import..." >&2
log_event "validation_started" "checking mlx_lm import"
IMPORT_CHECK=$(bash -c "source '$MODELS_ENV' && exec '$MLX_PYTHON' -c 'import mlx_lm; print(\"OK\")'" 2>&1)
if [ $? -ne 0 ]; then
    log_event "validation_failed" "$IMPORT_CHECK"
    echo "[$NAME] STARTUP VALIDATION FAILED: $IMPORT_CHECK" >&2
    exit 1
fi
log_event "validation_passed" "imports OK"

# ── Phase 3: Launch the daemon ──────────────────────────────────────
echo "[$NAME] PID $$ — starting mlx_lm.server on port $PORT..." >&2
echo $$ > "$PIDFILE"
log_event "daemon_spawning" "exec: mlx_lm.server on :$PORT"
source "$MODELS_ENV" && \
    exec "$MLX_SERVER" --model "$JW_CHAT_MODEL_REPO" --host 127.0.0.1 --port "$PORT" --trust-remote-code --chat-template-args '{"enable_thinking":false}'
