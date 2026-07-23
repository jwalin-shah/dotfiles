#!/usr/bin/env bash
# prove-launchers.sh — captain surfaces + LaunchAgents match inventory contract.
set -euo pipefail
export PATH="${HOME}/.local/bin:${HOME}/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

FAIL=0
ok() { echo "OK: $*"; }
fail() { echo "FAIL: $*" >&2; FAIL=1; }
warn() { echo "WARN: $*" >&2; }

# --- PATH captains ---
for bin in orbit bridge; do
  if command -v "$bin" >/dev/null 2>&1; then
    ok "PATH $bin → $(command -v "$bin")"
  else
    fail "missing on PATH: $bin"
  fi
done

# bridge-serve must not be older than ~/.local/bin/bridge (stale gRPC binary).
BRIDGE_BIN="${HOME}/.local/bin/bridge"
if [[ -x "$BRIDGE_BIN" ]]; then
  bin_m=$(stat -f %m "$BRIDGE_BIN" 2>/dev/null || echo 0)
  serve_pid=$(pgrep -f 'bridge-serve:9101' | head -1 || true)
  if [[ -n "$serve_pid" && "$bin_m" -gt 0 ]]; then
    lstart=$(ps -p "$serve_pid" -o lstart= 2>/dev/null || true)
    started=$(date -j -f "%a %b %e %T %Y" "$(echo "$lstart" | tr -s ' ')" +%s 2>/dev/null || echo 0)
    if [[ "$started" -gt 0 && "$bin_m" -gt "$started" ]]; then
      fail "bridge-serve stale (bin mtime $bin_m > serve start $started) — kickstart org.nixos.com.jwalinshah.bridge-serve"
    else
      ok "bridge-serve not older than ~/.local/bin/bridge"
    fi
  fi
fi

if [[ -x "${HOME}/bin/ca" && -x "${HOME}/bin/ct" ]]; then
  ok "HM launchers ca+ct present"
else
  fail "missing ~/bin/ca or ~/bin/ct (need rebuild home.nix)"
fi

for b in bridge-ca bridge-ct bridge-agy bridge-cx; do
  if [[ -e "${HOME}/bin/$b" ]]; then
    ok "adapter wrapper $b"
  else
    fail "missing ~/bin/$b"
  fi
done

# Dead FirstMate binaries must stay gone
for dead in jw jw-heal; do
  if command -v "$dead" >/dev/null 2>&1 || [[ -e "${HOME}/.local/bin/$dead" ]]; then
    fail "orphan still on PATH: $dead (quarantine/remove)"
  else
    ok "no dead launcher $dead"
  fi
done

# Unmanaged chrome wrappers — documented waiver, warn if present
for c in chrome-ai-tools chrome-main chrome-third; do
  if [[ -e "${HOME}/bin/$c" ]]; then
    warn "WAIVER unmanaged ~/bin/$c (see launcher-inventory)"
  fi
done

# --- orbit identity ---
orbit_out="$(orbit status 2>&1 || true)"
if echo "$orbit_out" | grep -q 'bridge health'; then
  ok "orbit status is gRPC thin shell"
else
  fail "orbit status does not show bridge health (stale binary?). got: ${orbit_out:0:120}"
fi

# --- LaunchAgents declared in configuration.nix must be loaded (or calendar) ---
CFG="${HOME}/projects/dotfiles/configuration.nix"
if [[ ! -f "$CFG" ]]; then
  fail "missing configuration.nix"
else
  ok "configuration.nix present"
  if rg -q 'defaultPATH.*usr/sbin' "$CFG"; then
    ok "configuration.nix defaultPATH includes /usr/sbin"
  else
    fail "configuration.nix defaultPATH missing /usr/sbin (LaunchAgent ghost lsof/chown)"
  fi
fi

required=(
  org.nixos.com.jwalinshah.mlx-chat-daemon
  org.nixos.com.jwalinshah.llama-embed-server
  org.nixos.com.jwalinshah.coderank-embed-server
  org.nixos.com.jwalinshah.tldr-daemon
  org.nixos.com.jwalinshah.mintmux
  org.nixos.com.jwalinshah.knowledge-engine
  org.nixos.com.jwalinshah.inbox-server
  org.nixos.com.jwalinshah.bridge-cdp-quota
  org.nixos.com.jwalinshah.bridge-serve
  org.nixos.com.jwalinshah.m5logd
  org.nixos.com.jwalinshah.voice-engine
)

loaded="$(launchctl list 2>/dev/null || true)"
for label in "${required[@]}"; do
  if echo "$loaded" | grep -q "$label"; then
    ok "loaded $label"
  else
    fail "LaunchAgent not loaded: $label (run rebuild.sh)"
  fi
done

# verify-machine daily agent: required in nix source; loaded after rebuild
if grep -q 'com.jwalinshah.verify-machine' "$CFG"; then
  ok "verify-machine declared in configuration.nix"
  if echo "$loaded" | grep -q 'org.nixos.com.jwalinshah.verify-machine'; then
    ok "loaded org.nixos.com.jwalinshah.verify-machine"
  else
    warn "verify-machine not loaded yet — run rebuild.sh to activate daily 09:00 gate"
  fi
else
  fail "verify-machine missing from configuration.nix"
fi

# overnight-harden interval agent (durable wrap — not Cursor-session-bound)
if grep -q 'com.jwalinshah.overnight-harden' "$CFG"; then
  ok "overnight-harden declared in configuration.nix"
  if echo "$loaded" | grep -q 'org.nixos.com.jwalinshah.overnight-harden'; then
    ok "loaded org.nixos.com.jwalinshah.overnight-harden"
  else
    warn "overnight-harden not loaded yet — run rebuild.sh (or interim LaunchAgent)"
  fi
  OH_TICK="${HOME}/projects/dotfiles/bin/overnight-harden-tick.sh"
  if [[ -x "$OH_TICK" ]]; then
    if bash -n "$OH_TICK" 2>/dev/null; then
      ok "overnight-harden-tick.sh bash -n clean"
    else
      fail "overnight-harden-tick.sh bash -n failed (syntax)"
    fi
    if [[ -x "${HOME}/projects/dotfiles/bin/prove-overnight-pr-belt.sh" ]]; then
      if "${HOME}/projects/dotfiles/bin/prove-overnight-pr-belt.sh" >/dev/null; then
        ok "prove-overnight-pr-belt.sh PASS"
      else
        fail "prove-overnight-pr-belt.sh FAILED"
      fi
    fi
    if rg -q '/usr/sbin' "$OH_TICK"; then
      ok "overnight-harden-tick.sh PATH includes /usr/sbin"
    else
      fail "overnight-harden-tick.sh PATH missing /usr/sbin (lsof/chown ghost under LaunchAgent)"
    fi
  else
    fail "missing executable $OH_TICK"
  fi
else
  fail "overnight-harden missing from configuration.nix"
fi

# CDP quota prove (offline merge always; live optional via CDP_PROVE_LIVE=1)
CDP_PROVE="${HOME}/projects/bridge/scripts/prove-cdp-quota.sh"
if [[ -x "$CDP_PROVE" ]]; then
  if CDP_PROVE_OFFLINE=1 "$CDP_PROVE"; then
    ok "prove-cdp-quota.sh OFFLINE PASS"
  else
    fail "prove-cdp-quota.sh OFFLINE FAILED"
  fi
  if [[ "${CDP_PROVE_LIVE:-}" == "1" ]]; then
    if "$CDP_PROVE"; then
      ok "prove-cdp-quota.sh LIVE PASS"
    else
      fail "prove-cdp-quota.sh LIVE FAILED"
    fi
  else
    warn "prove-cdp-quota LIVE skipped (set CDP_PROVE_LIVE=1 to open Brave + scrape)"
  fi
else
  fail "missing executable $CDP_PROVE"
fi

# Factory e2e scorecard schema (Y rows must prove)
SCHEMA_PROVE="${HOME}/projects/dotfiles/bin/prove-factory-e2e-scorecard.sh"
if [[ -x "$SCHEMA_PROVE" ]]; then
  if "$SCHEMA_PROVE"; then
    ok "prove-factory-e2e-scorecard.sh PASS"
  else
    fail "prove-factory-e2e-scorecard.sh FAILED"
  fi
else
  fail "missing executable $SCHEMA_PROVE"
fi

# Inventory note exists
INV="${HOME}/projects/portfolio/wayfinder/launcher-inventory-2026-07-23.md"
if [[ -f "$INV" ]]; then
  ok "launcher inventory CRDM present"
else
  fail "missing $INV"
fi

# Factory e2e readiness CRDM
E2E="${HOME}/projects/portfolio/wayfinder/factory-e2e-readiness-2026-07-23.md"
if [[ -f "$E2E" ]]; then
  ok "factory e2e readiness CRDM present"
else
  fail "missing $E2E"
fi

if [[ "$FAIL" -ne 0 ]]; then
  echo "prove-launchers: FAILED" >&2
  exit 1
fi
echo "prove-launchers: ALL CHECKS PASSED (see WARNs)"
exit 0
