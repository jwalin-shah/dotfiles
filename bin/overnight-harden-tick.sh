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
export PATH="${HOME}/.local/bin:${HOME}/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"

ORBIT_DATA="${HOME}/.local/share/orbit"
QUEUE="${HOME}/projects/portfolio/wayfinder/overnight-queue"
LOG="${ORBIT_DATA}/overnight-harden.log"
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

# If ~/.local/bin/bridge was rebuilt after bridge-serve started, reload serve
# so gRPC/CLI share the same fixes (lease defer, KillSession ENOENT, …).
BRIDGE_BIN="${HOME}/.local/bin/bridge"
if [[ -x "$BRIDGE_BIN" ]]; then
  bin_m=$(stat -f %m "$BRIDGE_BIN" 2>/dev/null || echo 0)
  serve_pid=$(pgrep -f 'bridge-serve:9101' | head -1 || true)
  if [[ -n "$serve_pid" && "$bin_m" -gt 0 ]]; then
    lstart=$(ps -p "$serve_pid" -o lstart= 2>/dev/null || true)
    started=$(date -j -f "%a %b %e %T %Y" "$(echo "$lstart" | tr -s ' ')" +%s 2>/dev/null || echo 0)
    if [[ "$started" -gt 0 && "$bin_m" -gt "$started" ]]; then
      log "bridge binary newer than serve (bin=$bin_m start=$started) — kickstarting bridge-serve"
      launchctl kickstart -k "gui/$(id -u)/org.nixos.com.jwalinshah.bridge-serve" 2>/dev/null || true
      sleep 2
    fi
  fi
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
# NOTE: under set -e, `[[ ok ]] && rg -q` exits the script when rg misses —
# keep the rg inside a nested if so a clean prove can continue to spawn.
if [[ "$PROVE_OK" -eq 1 ]]; then
  if tail -60 "$LOG" | rg -q '^  ✗ '; then
    PROVE_OK=0
    log "prove pack RED — verify-machine gate failure seen in log"
  fi
fi

if [[ "$PROVE_OK" -eq 1 ]]; then
  log "prove pack GREEN"
else
  log "prove pack RED — see $LOG (no spawn this tick)"
  # Capture structured gate detail for intermittent flakes (bare ✗ is useless).
  if command -v bridge >/dev/null 2>&1; then
    {
      echo "=== $(ts) verify-machine --json (RED dump) ==="
      bridge verify-machine --json 2>/dev/null || true
    } >>"$LOG" 2>&1 || true
  fi
  exit 1
fi

# Best-effort quota brake (do not fail tick if script missing / hung)
if [[ -x "${HOME}/projects/bridge/scripts/quota-recommend.sh" && ! -f "$STOP" ]]; then
  qout="$(timeout 30 "${HOME}/projects/bridge/scripts/quota-recommend.sh" 2>/dev/null || true)"
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
if pgrep -f '/bridge-agy([[:space:]]|$)' >/dev/null 2>&1 \
  || pgrep -f '/bridge-ca([[:space:]]|$)' >/dev/null 2>&1 \
  || pgrep -f '/bridge[[:space:]]+spawn([[:space:]]|$)' >/dev/null 2>&1; then
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

# Pick oldest ready ticket: NAME.json + NAME.brief.md, not *.done / *.failed
ticket=""
brief=""
for j in "$QUEUE"/*.json; do
  [[ -f "$j" ]] || continue
  base="${j%.json}"
  [[ -f "${base}.done" ]] && continue
  [[ -f "${base}.failed" ]] && continue
  [[ -f "${base}.brief.md" ]] || continue
  ticket="$j"
  brief="${base}.brief.md"
  break
done

if [[ -z "$ticket" ]]; then
  log "queue empty — prove-only tick"
  exit 0
fi

adapter="$(jq -r '.adapter // empty' "$ticket" 2>/dev/null || true)"
repo="$(jq -r '.target_repository // empty' "$ticket" 2>/dev/null || true)"
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
  # Fail-closed belt (042 class): spawn exit 0 + verification_commands can pass
  # without an open PR. delivery=pr must show a gh-visible open PR matching
  # ticket id (title/body/branch search). Bridge LandedWorkProof still owns
  # release; this stops overnight from marking .done on a false ledger.
  delivery="$(jq -r '.delivery // empty' "$ticket" 2>/dev/null || true)"
  tid="$(jq -r '.id // empty' "$ticket" 2>/dev/null || true)"
  if [[ "$delivery" == "pr" ]]; then
    pr_n=0
    if [[ -n "$tid" ]] && command -v gh-axi >/dev/null 2>&1; then
      # Prefer listing open PRs + local match: GitHub --search often misses
      # abbreviated head branches (047: id had "-requires-", branch did not).
      pr_n="$(
        cd "$repo_dir" && gh-axi api \
          '/repos/{owner}/{repo}/pulls?state=open&per_page=40' 2>/dev/null \
          | jq --arg tid "$tid" '
              def tokens: ascii_downcase | gsub("/"; "-") | split("-") | map(select(length > 2));
              def stem_tokens: tokens
                | map(select(
                    (. != "fix" and . != "feat" and . != "feature"
                     and . != "chore" and . != "docs" and . != "design"
                     and . != "refactor" and . != "test" and . != "ci"
                     and . != "clean")
                    and (test("^[0-9]+$") | not)
                  ));
              [.[] | select(
                (.head.ref | contains($tid)) or
                (.title | contains($tid)) or
                ((.body // "") | contains($tid)) or
                (
                  (.head.ref | stem_tokens) as $ht
                  | ($ht | length) >= 4
                  and ($ht | all(. as $t | ($tid | ascii_downcase | contains($t))))
                )
              )] | length
            ' 2>/dev/null || echo 0
      )"
    fi
    if [[ "${pr_n:-0}" -lt 1 ]]; then
      touch "${ticket%.json}.failed"
      log "spawn exit 0 but delivery=pr with no open PR matching id=${tid:-?} — fail-closed → marked failed"
      exit 1
    fi
    log "delivery=pr proved open PR count=$pr_n for id=$tid"
  fi
  touch "${ticket%.json}.done"
  log "spawn OK → marked done $(basename "$ticket")"
else
  # Stop infinite 15m re-burn after ESCALATED / retry_limit — captain reviews .failed
  touch "${ticket%.json}.failed"
  log "spawn FAIL exit=$ec for $(basename "$ticket") → marked failed (skip until captain clears)"
  exit "$ec"
fi
