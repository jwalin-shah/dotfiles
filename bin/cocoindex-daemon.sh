#!/usr/bin/env bash
# ── Deterministic shell for cocoindex daemon ──────────────────────────
# Single-instance enforcement, startup validation, health checks, and
# crash-circuit-breaker. Prevents the zombie-process leak we had (19
# orphaned daemon processes, ~4GB RAM).
#
# Includes structured event logging for trace refinement against TLA+
# model DaemonGenerations.tla. Every lifecycle event is logged to
# LIFE_LOG as JSON with {gen_id, event, timestamp, detail}.
set -euo pipefail

NAME="cocoindex-daemon"
SOCKET="$HOME/.cocoindex_code/daemon.sock"
PIDFILE="/tmp/${NAME}.pid"
LOCKDIR="/tmp/${NAME}.lockdir"
EXTENSIONS_DIR="$HOME/.cocoindex_code/extensions"
UV_PYTHON="$HOME/.local/share/uv/tools/cocoindex-code/bin/python"
CCC_BIN="$HOME/.local/share/uv/tools/cocoindex-code/bin/ccc"
UV_SITE="$HOME/.local/share/uv/tools/cocoindex-code/lib/python3.13/site-packages"

# ── Event log (structured, JSONL, for trace refinement) ────────────
LIFECYCLE_LOG_DIR="$HOME/.local/share/cocoindex"
LIFECYCLE_LOG="$LIFECYCLE_LOG_DIR/lifecycle.jsonl"
mkdir -p "$LIFECYCLE_LOG_DIR"

# Generation ID: timestamp + PID. Unique enough for a single machine.
GEN_ID="$(date +%s)-$$"

log_event() {
    local event="$1"
    local detail="${2:-}"
    local gen_id="${3:-$GEN_ID}"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S%z")
    printf '{"gen_id":"%s","event":"%s","timestamp":"%s","pid":%d,"detail":"%s"}\n' \
        "$gen_id" "$event" "$timestamp" "$$" "$detail" >> "$LIFECYCLE_LOG"
}

# ── Phase 0: Process group setup (DL-004: descendant containment) ──
# Set the process group so all children are part of it. Kill the group
# on exit to avoid orphaned children.
if [[ -t 0 ]]; then
    # Interactive shell — set PGID manually
    set -m  # job control (creates new process group for background jobs)
fi
log_event "wrapper_started" "PID=$$, GEN_ID=$GEN_ID"

# ── Phase 1: Single-instance enforcement ────────────────────────────
# Use mkdir as atomic lock (works on macOS, flock is not available).
# If lockdir exists, check if the locking process is still alive.
# The lockdir now stores {gen_id, pid} for generation tracking (DL-001).
if ! mkdir "$LOCKDIR" 2>/dev/null; then
    # Stale lock recovery: read the locker PID and gen_id, clean up if dead
    LOCKER_PID=""
    LOCKER_GEN_ID=""
    [ -f "$LOCKDIR/pid" ] && LOCKER_PID=$(cat "$LOCKDIR/pid" 2>/dev/null || echo "")
    [ -f "$LOCKDIR/gen_id" ] && LOCKER_GEN_ID=$(cat "$LOCKDIR/gen_id" 2>/dev/null || echo "")

    if [ -n "$LOCKER_PID" ] && kill -0 "$LOCKER_PID" 2>/dev/null; then
        log_event "lock_deferred" "holder PID=$LOCKER_PID (gen=$LOCKER_GEN_ID) still alive"
        echo "[$NAME] already running (PID $LOCKER_PID, gen=$LOCKER_GEN_ID). Exiting." >&2
        exit 0
    fi

    # Locker is dead — reclaim the lock
    log_event "stale_lock_found" "PID=$LOCKER_PID (gen=$LOCKER_GEN_ID) dead, reclaiming"
    rm -rf "$LOCKDIR"
    if ! mkdir "$LOCKDIR" 2>/dev/null; then
        log_event "lock_fatal" "cannot acquire lockdir even after stale cleanup"
        echo "[$NAME] FATAL: cannot acquire lockdir $LOCKDIR even after stale cleanup" >&2
        exit 1
    fi
    log_event "stale_lock_reclaimed" "lockdir reclaimed from gen=$LOCKER_GEN_ID"
fi

# Write generation ID and PID into the lockdir for generation tracking (DL-001)
echo "$GEN_ID" > "$LOCKDIR/gen_id"
echo "$$" > "$LOCKDIR/pid"
log_event "lock_acquired" "GEN_ID=$GEN_ID, PID=$$"

# Clean up lockdir on exit (DL-003), including process group kill (DL-004)
trap 'log_event "lock_released" "EXIT trap cleaning up"; rm -rf "$LOCKDIR"' EXIT

# ── Phase 2: Startup validation (check imports before running) ──────
echo "[$NAME] verifying tldr_chunker import..." >&2
log_event "validation_started" "checking tldr_chunker import"
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
    log_event "validation_failed" "$IMPORT_CHECK"
    echo "[$NAME] STARTUP VALIDATION FAILED: $IMPORT_CHECK" >&2
    echo "[$NAME] Daemon will NOT start. Fix the module issue first." >&2
    echo "[$NAME] Check: $EXTENSIONS_DIR/tldr_chunker.py" >&2
    exit 1
fi
log_event "validation_passed" "imports OK"
echo "[$NAME] $IMPORT_CHECK" >&2

# ── Phase 3: Launch the daemon ──────────────────────────────────────
echo "[$NAME] PID $$ — starting daemon..." >&2
echo $$ > "$PIDFILE"
log_event "daemon_spawning" "exec: $CCC_BIN run-daemon"

PYTHONPATH="$EXTENSIONS_DIR:$UV_SITE" \
    exec "$CCC_BIN" run-daemon
# exec replaces process — log_event after this never runs.
# The daemon process inherits our PID and lockdir ownership.
