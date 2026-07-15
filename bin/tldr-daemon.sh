#!/usr/bin/env bash
# ── Deterministic shell for tldr daemon ────────────────────────────────
# Watches ~/projects for file changes and auto-refreshes the tldr
# call-graph index. Index lives at ~/projects/.tldr/cache/.
#
# Daemon contract v2:
#   - Single-instance via flock, not lockdir (kernel-released on crash)
#   - Crash-loop detection: state file with start timestamps
#   - llm-tldr daemon start daemonizes internally, so wrapper runs it as
#     a child, verifies it started, then blocks until SIGTERM
#   - Clean shutdown: llm-tldr daemon stop on SIGTERM
#   - Named in ps via exec -a (set by caller or default argv[0])
set -euo pipefail

NAME="tldr-daemon"
TLDR_BIN="$HOME/.local/share/uv/tools/llm-tldr/bin/llm-tldr"
WATCH_DIR="$HOME/projects"
STATE_DIR="$HOME/.local/share/jw"
STATE_FILE="$STATE_DIR/tldr-daemon-state.json"
LOCK_FILE="$STATE_DIR/tldr-daemon.lock"
LIFECYCLE_LOG="$STATE_DIR/tldr-daemon-lifecycle.jsonl"

mkdir -p "$STATE_DIR"

# ── Helpers ──────────────────────────────────────────────────────────

GEN_ID="$(date +%s)-$$"

log_event() {
    local event="$1" detail="${2:-}" timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S%z")
    printf '{"gen_id":"%s","event":"%s","timestamp":"%s","pid":%d,"detail":"%s"}\n' \
        "$GEN_ID" "$event" "$timestamp" "$$" "$detail" >> "$LIFECYCLE_LOG"
}

now_epoch() { date +%s; }

# ── Crash-loop detection ─────────────────────────────────────────────
# Format: {"starts": [epoch, ...], "active": bool}
# If ≥3 starts within 2 minutes while previous was "active" → crash loop.

read_state() {
    [ -f "$STATE_FILE" ] && python3 -c "
import json,sys
try:
    d=json.load(open('$STATE_FILE'))
    print(json.dumps(d))
except: print('{}')
" 2>/dev/null || echo '{}'
}

write_state() {
    python3 -c "
import json
json.dump($1, open('$STATE_FILE','w'))
"
}

check_crash_loop() {
    local state now cutoff count
    state=$(read_state)
    now=$(now_epoch)
    cutoff=$((now - 120))  # 2 minute window

    count=$(echo "$state" | python3 -c "
import json,sys
d=json.loads(sys.stdin.read())
starts=[t for t in d.get('starts',[]) if t > $cutoff]
d['starts'] = starts + [$now]
d['active'] = True
json.dump(d, open('$STATE_FILE','w'))
print(len(starts))
")
    echo "$count"
}

clear_crash_state() {
    printf '{"starts":[],"active":false}' > "$STATE_FILE"
    log_event "crash_state_cleared" "clean shutdown"
}

# ── Phase 1: Single-instance enforcement via flock ───────────────────
# flock on an FD survives process crashes — kernel releases the lock.
# No EXIT trap needed, no race condition.

exec {LOCK_FD}>"$LOCK_FILE"

if ! flock -n "$LOCK_FD" 2>/dev/null; then
    # flock -n is not standard on macOS, use fallback
    if ! python3 -c "
import fcntl, sys
fd = $LOCK_FD
try:
    fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
except BlockingIOError:
    sys.exit(1)
" 2>/dev/null; then
        log_event "lock_deferred" "another instance holds the lock"
        echo "[$NAME] already running (lock held). Exiting." >&2
        exit 0  # SuccessfulExit — launchd won't restart
    fi
fi

log_event "lock_acquired" "GEN_ID=$GEN_ID, PID=$$"

# ── Phase 2: Crash-loop detection ────────────────────────────────────
CRASH_COUNT=$(check_crash_loop)
if [ "$CRASH_COUNT" -ge 3 ]; then
    log_event "crash_loop_detected" "$CRASH_COUNT starts in 2min window"
    echo "[$NAME] CRASH LOOP DETECTED: $CRASH_COUNT starts in 2 minutes. Giving up." >&2
    exit 0  # SuccessfulExit — launchd stops restarting
fi

# ── Phase 3: Startup validation ──────────────────────────────────────
if [ ! -x "$TLDR_BIN" ]; then
    log_event "validation_failed" "tldr binary not found at $TLDR_BIN"
    echo "[$NAME] STARTUP VALIDATION FAILED: tldr binary not found at $TLDR_BIN" >&2
    exit 1
fi

# ── Phase 4: Launch daemon (as child, not exec — it daemonizes) ─────
log_event "daemon_spawning" "running: $TLDR_BIN daemon start --project $WATCH_DIR"

"$TLDR_BIN" daemon start --project "$WATCH_DIR"
SPAWN_EXIT=$?

if [ "$SPAWN_EXIT" -ne 0 ]; then
    log_event "daemon_spawn_failed" "exit code $SPAWN_EXIT"
    echo "[$NAME] FATAL: tldr daemon start failed (exit $SPAWN_EXIT)" >&2
    exit 1
fi

# ── Phase 5: Verify daemon is actually running ───────────────────────
sleep 1  # Give daemon time to daemonize and bind
if ! "$TLDR_BIN" daemon status --project "$WATCH_DIR" >/dev/null 2>&1; then
    log_event "daemon_verify_failed" "status check returned non-zero"
    echo "[$NAME] FATAL: daemon started but status check failed" >&2
    exit 1
fi

log_event "daemon_running" "daemon verified via status check"
echo "[$NAME] PID $$ — daemon running, watching $WATCH_DIR" >&2

# ── Phase 6: Block until signal ──────────────────────────────────────
# The daemon runs independently. This wrapper stays alive so launchd
# sees a running process. On SIGTERM/SIGINT, stop the daemon and exit
# clean so the crash state is cleared.

cleanup() {
    log_event "signal_received" "stopping daemon"
    echo "[$NAME] stopping daemon..." >&2
    "$TLDR_BIN" daemon stop --project "$WATCH_DIR" 2>/dev/null || true
    clear_crash_state
    log_event "lock_released" "clean shutdown complete"
    exit 0
}

trap cleanup SIGTERM SIGINT SIGHUP

# Block forever. launchd sends SIGTERM to stop.
while true; do
    # Periodically verify daemon is still alive
    sleep 60
    if ! "$TLDR_BIN" daemon status --project "$WATCH_DIR" >/dev/null 2>&1; then
        log_event "daemon_died" "status check failed, exiting for restart"
        echo "[$NAME] daemon died — exiting for restart" >&2
        exit 1  # Non-zero exit → launchd restarts (crash-loop detection gates this)
    fi
done
