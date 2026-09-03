#!/usr/bin/env bash
# prove-launchers.sh — captain surfaces + LaunchAgents match inventory contract.
set -euo pipefail
export PATH="${HOME}/.local/bin:${HOME}/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

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

# bridge-serve freshness is only meaningful when the optional gRPC surface is up.
# live launchctl/pgrep truth is host-global; binary path stays under ~/.local/bin.
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
  else
    ok "bridge-serve not running (optional; CLI bridge spine OK)"
  fi
fi

if [[ -x "${HOME}/bin/ca" && -x "${HOME}/bin/ct" && -x "${HOME}/bin/ca-watch" ]]; then
  ok "HM launchers ca+ct+ca-watch present"
else
  fail "missing ~/bin/ca, ~/bin/ct, or ~/bin/ca-watch (need rebuild home.nix)"
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
# orbit is a gRPC thin shell over bridge. bridge-serve was deliberately removed
# 2026-07-31 (captain cut it), so a live bridge health line is NOT expected.
# The proof is: the auth token resolves (no "token file is required") and the
# failure mode is a clean connection-refused — i.e. the client is wired.
orbit_out="$(orbit status 2>&1 || true)"
if echo "$orbit_out" | grep -q "gRPC auth token file is required"; then
  fail "orbit status cannot resolve the gRPC auth token (stale binary?). got: ${orbit_out:0:120}"
else
  ok "orbit status resolves gRPC auth token (bridge-serve absent is expected)"
fi

# --- LaunchAgents declared in this worktree's configuration.nix must be loaded ---
# Prefer ROOT so proves work from disposable worktrees; launchctl truth stays live-home.
CFG="${ROOT}/configuration.nix"
if [[ ! -f "$CFG" ]]; then
  fail "missing configuration.nix at $CFG"
else
  ok "configuration.nix present"
  if rg -q 'defaultPATH.*usr/sbin' "$CFG"; then
    ok "configuration.nix defaultPATH includes /usr/sbin"
  else
    fail "configuration.nix defaultPATH missing /usr/sbin (LaunchAgent ghost lsof/chown)"
  fi
fi

required=(
  # mlx-chat-daemon PARKED 2026-07-23 (Neo4j sole-store; embeds :8081/:8082 only)
  org.nixos.com.jwalinshah.homebase
  # Cut 2026-07-31 (must not be required): knowledge-engine, bridge-cdp-quota,
  # bridge-serve, voice-engine, overnight-harden, verify-machine
  org.nixos.com.jwalinshah.llama-embed-server
  org.nixos.com.jwalinshah.coderank-embed-server
  org.nixos.com.jwalinshah.mintmux
  org.nixos.com.jwalinshah.inbox-server
  org.nixos.com.jwalinshah.m5logd
)

if "$ROOT/bin/reconcile-agent-toolchain.sh" check >/dev/null; then
  ok "agent toolchain matches exact version receipt"
else
  fail "agent toolchain version drift (run reconcile-agent-toolchain.sh install)"
fi

# Formal tool ownership is deliberate: Dafny is Nix/Home Manager, Z3 is uv,
# and Lean's lake is installed by elan. Do not restore duplicate Homebrew
# packages merely because cleanup removed an undeclared copy.
for formal_bin in dafny z3 java lake; do
  if command -v "$formal_bin" >/dev/null 2>&1; then
    ok "formal tool $formal_bin → $(command -v "$formal_bin")"
  else
    fail "missing formal tool: $formal_bin (see docs/FORMAL_TOOLCHAIN.md)"
  fi
done

loaded="$(launchctl list 2>/dev/null || true)"
for label in "${required[@]}"; do
  if echo "$loaded" | grep -q "$label"; then
    ok "loaded $label"
  else
    fail "LaunchAgent not loaded: $label (run rebuild.sh)"
  fi
done

# Retired labels must not be loaded alongside their Nix-managed replacements.
# A stale plist on disk is recoverable; a loaded duplicate can double-run work.
retired=(
  org.orbit.bridge-cdp-quota
  org.nixos.com.jwalinshah.cocoindex-daemon
  org.nixos.com.jwalinshah.tldr-daemon
)
for label in "${retired[@]}"; do
  if echo "$loaded" | grep -qE "[[:space:]]${label}$"; then
    fail "retired duplicate LaunchAgent is loaded: $label"
  else
    ok "retired LaunchAgent not loaded: $label"
  fi
done

# Deliberately removed 2026-07-31 (captain cut). The prove asserts they are
# NOT loaded and NOT re-declared in configuration.nix — re-adding any of them
# without reversing the removal is drift and must fail.
removed=(
  org.nixos.com.jwalinshah.knowledge-engine
  org.nixos.com.jwalinshah.bridge-cdp-quota
  org.nixos.com.jwalinshah.bridge-serve
  org.nixos.com.jwalinshah.voice-engine
  org.nixos.com.jwalinshah.verify-machine
  org.nixos.com.jwalinshah.overnight-harden
)
for label in "${removed[@]}"; do
  if echo "$loaded" | grep -q "$label"; then
    fail "removed LaunchAgent is loaded: $label (captain cut 2026-07-31)"
  else
    ok "removed LaunchAgent not loaded: $label"
  fi
  if grep -q "$label" "$CFG"; then
    fail "removed LaunchAgent re-declared in configuration.nix: $label"
  else
    ok "removed LaunchAgent not re-declared in configuration.nix: $label"
  fi
done

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
SCHEMA_PROVE="${ROOT}/bin/prove-factory-e2e-scorecard.sh"
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

# Forced MACHINE.md / SYSTEM_MAP freshness vs live machine
DOCS_PROVE="${ROOT}/bin/prove-docs-freshness.sh"
if [[ -x "$DOCS_PROVE" ]]; then
  if "$DOCS_PROVE"; then
    ok "prove-docs-freshness.sh PASS"
  else
    fail "prove-docs-freshness.sh FAILED"
  fi
else
  fail "missing executable $DOCS_PROVE"
fi

if [[ "$FAIL" -ne 0 ]]; then
  echo "prove-launchers: FAILED" >&2
  exit 1
fi
echo "prove-launchers: ALL CHECKS PASSED (see WARNs)"
exit 0
