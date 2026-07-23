#!/usr/bin/env bash
# overnight-harden-tick.sh — durable wrap worker (LaunchAgent or manual).
# Does NOT depend on a Cursor chat being awake.
#
# Each tick:
#   1) Run prove pack; append Evidence to overnight log
#   2) If a ready ticket pair exists in overnight-queue and no active spawn,
#      bridge-spawn it (one ticket per tick)
#   3) Stop spawning when STOP file present or weekly Claude ≥90% (best-effort)
set -euo pipefail
export PATH="${HOME}/.local/bin:${HOME}/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

ORBIT_DATA="${HOME}/.local/share/orbit"
QUEUE="${HOME}/projects/portfolio/wayfinder/overnight-queue"
LOG="${ORBIT_DATA}/overnight-harden.log"
EVIDENCE="${HOME}/projects/portfolio/wayfinder/overnight-hardening-loop-2026-07-23.md"
STOP="${QUEUE}/STOP"
LOCK="${ORBIT_DATA}/overnight-harden.lock"
mkdir -p "$ORBIT_DATA" "$QUEUE"

# macOS has no flock(1) by default — mkdir lock with dead-pid / stale reclaim.
# Note: an earlier flock attempt left LOCK as a *file*; treat non-dir as reclaimable.
acquire_lock() {
  local stale_s=900
  if [[ -e "$LOCK" && ! -d "$LOCK" ]]; then
    /bin/rm -f "$LOCK"
  fi
  if mkdir "$LOCK" 2>/dev/null; then
    echo $$ >"$LOCK/pid"
    return 0
  fi
  local holder=""
  holder="$(cat "$LOCK/pid" 2>/dev/null || true)"
  if [[ -n "$holder" ]] && ! kill -0 "$holder" 2>/dev/null; then
    /bin/rm -rf "$LOCK"
    mkdir "$LOCK" 2>/dev/null || return 1
    echo $$ >"$LOCK/pid"
    return 0
  fi
  local age=0
  if [[ -d "$LOCK" ]]; then
    age=$(( $(date +%s) - $(stat -f %m "$LOCK" 2>/dev/null || echo 0) ))
  fi
  if [[ "$age" -gt "$stale_s" ]]; then
    /bin/rm -rf "$LOCK"
    mkdir "$LOCK" 2>/dev/null || return 1
    echo $$ >"$LOCK/pid"
    return 0
  fi
  return 1
}
release_lock() { /bin/rm -rf "$LOCK"; }
trap release_lock EXIT

if ! acquire_lock; then
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) skip: another tick holds lock" >>"$LOG"
  trap - EXIT
  exit 0
fi

ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }
log() { echo "$(ts) $*" | tee -a "$LOG"; }

if [[ -f "$STOP" ]]; then
  log "STOP present — prove only, no spawn"
fi

if ! bridge freeze >/dev/null 2>&1; then
  log "capability hash drift detected — auto-running bridge freeze --write"
  bridge freeze --write >>"$LOG" 2>&1 || true
fi

PROVE_OK=1
{
  echo "=== $(ts) prove pack ==="
  ~/projects/dotfiles/bin/prove-harness-hooks.sh
  ~/projects/dotfiles/bin/prove-launchers.sh
  ~/projects/bridge/scripts/prove-neo4j-packet.sh
  ~/projects/bridge/scripts/prove-worktree-lease.sh
  bridge verify-machine
  orbit status | grep 'bridge health' || true
} >>"$LOG" 2>&1 || PROVE_OK=0

# Belt: verify-machine exits 1 on failed gates, but never mark GREEN if a ✗
# gate line landed in this tick's prove section (guards log/redirect races).
if [[ "$PROVE_OK" -eq 1 ]] && tail -60 "$LOG" | rg -q '^  ✗ '; then
  PROVE_OK=0
  log "prove pack RED — verify-machine gate failure seen in log"
fi

if [[ "$PROVE_OK" -eq 1 ]]; then
  log "prove pack GREEN"
else
  log "prove pack RED — see $LOG (no spawn this tick)"
  exit 1
fi

# Best-effort quota brake (do not fail tick if script missing)
if [[ -x "${HOME}/projects/bridge/scripts/quota-recommend.sh" && ! -f "$STOP" ]]; then
  qout="$(~/projects/bridge/scripts/quota-recommend.sh 2>/dev/null || true)"
  if echo "$qout" | rg -q 'anthropic:.*weekly=(9[0-9]|100)\.'; then
    log "anthropic weekly ≥90 — writing STOP"
    echo "quota brake $(ts)" >"$STOP"
  fi
  if echo "$qout" | rg -q 'claude_week=(9[0-9]|100)\.'; then
    log "agy claude weekly ≥90 — writing STOP"
    echo "quota brake $(ts)" >"$STOP"
  fi
fi

if [[ -f "$STOP" ]]; then
  exit 0
fi

# Skip spawn if bridge already has active sessions
if orbit status 2>/dev/null | rg -q 'sessions=[1-9]'; then
  log "active spawn sessions — skip queue"
  exit 0
fi

# orbit sessions= can stay 0 while mintmux/agy is live — also gate on processes.
if pgrep -f '[b]ridge spawn' >/dev/null 2>&1 || pgrep -f '[b]ridge-agy|[b]ridge-ca' >/dev/null 2>&1; then
  log "active bridge spawn/adapter process — skip queue"
  exit 0
fi

# Mintmux must answer mm-ctl ping or spawn fails with EACCES / empty session.
if ! timeout 5 mm-ctl ping >/dev/null 2>&1; then
  log "mintmux unhealthy (mm-ctl ping failed) — kickstarting LaunchAgent"
  launchctl kickstart -k "gui/$(id -u)/org.nixos.com.jwalinshah.mintmux" 2>/dev/null || true
  sleep 3
  if ! timeout 5 mm-ctl ping >/dev/null 2>&1; then
    log "mintmux still down — skip spawn this tick"
    exit 1
  fi
  log "mintmux recovered"
fi

# Pick oldest ready ticket: NAME.json + NAME.brief.md, not *.done
ticket=""
brief=""
for j in "$QUEUE"/*.json; do
  [[ -f "$j" ]] || continue
  base="${j%.json}"
  [[ -f "${base}.done" ]] && continue
  [[ -f "${base}.brief.md" ]] || continue
  ticket="$j"
  brief="${base}.brief.md"
  break
done

if [[ -z "$ticket" ]]; then
  log "queue empty — prove-only tick"
  exit 0
fi

adapter="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('adapter',''))" "$ticket" 2>/dev/null || true)"
repo="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('target_repository',''))" "$ticket" 2>/dev/null || true)"
repo_dir="${HOME}/projects/${repo}"
if [[ -z "$repo" || ! -d "$repo_dir" ]]; then
  log "bad target_repository=$repo for $(basename "$ticket")"
  exit 1
fi
log "spawning $(basename "$ticket") adapter=${adapter:-default} cwd=$repo_dir"

export BRIDGE_AGY_MODEL="${BRIDGE_AGY_MODEL:-claude-sonnet-4-6}"
set +e
(
  cd "$repo_dir"
  # Sandbox+ca overnight often idles with no file activity (005 failure mode).
  # Opt out until sandbox toolchain covers adapter cold-start; Layer B still
  # runs prove pack fail-closed before spawn.
  bridge spawn --no-sandbox "$ticket" "$brief"
) >>"$LOG" 2>&1
ec=$?
set -e
if [[ "$ec" -eq 0 ]]; then
  touch "${ticket%.json}.done"
  log "spawn OK → marked done $(basename "$ticket")"
else
  log "spawn FAIL exit=$ec for $(basename "$ticket")"
  exit "$ec"
fi
