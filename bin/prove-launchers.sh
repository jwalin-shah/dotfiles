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

# Inventory note exists
INV="${HOME}/projects/portfolio/wayfinder/launcher-inventory-2026-07-23.md"
if [[ -f "$INV" ]]; then
  ok "launcher inventory CRDM present"
else
  fail "missing $INV"
fi

if [[ "$FAIL" -ne 0 ]]; then
  echo "prove-launchers: FAILED" >&2
  exit 1
fi
echo "prove-launchers: ALL CHECKS PASSED (see WARNs)"
exit 0
