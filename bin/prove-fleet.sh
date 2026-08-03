#!/usr/bin/env bash
# prove-fleet.sh — unified fleet prove gate.
#
# One command, exit 0 = every KEEP piece proves green. This is the "prove exit
# 0 on every piece" requirement from the system-of-systems map (2026-08-01).
#
# Each entry is a NAME + COMMAND pair. The command must exit 0 on success.
# Design intent: every repo's prove command is narrow, owned by that repo,
# and this script only aggregates. Do not hardcode repo-specific logic here.
#
# Usage: prove-fleet.sh [--fast]   (--fast skips slow gates: verify-machine, KE check)
set -uo pipefail

FAST=0
[[ "${1:-}" == "--fast" ]] && FAST=1

cd "$(dirname "$0")/.." || exit 1
ROOT="$(pwd)"

PASS=0
FAIL=0
FAILED=()

run() {
  local name="$1"; shift
  if [[ "$FAST" == "1" && "$name" == SLOW:* ]]; then
    echo "SKIP $name (fast)"
    return
  fi
  if "$@" >/tmp/prove-fleet-$name.log 2>&1; then
    echo "PASS $name"
    PASS=$((PASS+1))
  else
    echo "FAIL $name"
    FAIL=$((FAIL+1))
    FAILED+=("$name")
  fi
}

echo "=== prove-fleet: $(date '+%Y-%m-%dT%H:%M:%SZ') ==="

# --- Constitution (dotfiles) ---
run "dotfiles:prove-launchers" "$ROOT/bin/prove-launchers.sh"
run "dotfiles:prove-docs-freshness" "$ROOT/bin/prove-docs-freshness.sh"
run "dotfiles:prove-skills" "$ROOT/bin/prove-skills.sh"
run "dotfiles:prove-home-activation" "$ROOT/bin/prove-home-activation.sh"
run "dotfiles:prove-factory-e2e-scorecard" "$ROOT/bin/prove-factory-e2e-scorecard.sh"

# --- Enforcement (bridge) ---
run "SLOW:bridge:verify-machine" "$HOME/projects/bridge/bridge" verify-machine

# --- Knowledge plane (KE + axioms) ---
run "SLOW:knowledge-engine:check" "$HOME/projects/knowledge-engine/scripts/check.sh"
run "axioms:count" bash -c "cd $HOME/projects/axioms && test -f axioms.json && echo 'axioms.json present'"

# --- Fleet (firstmate) ---
run "firstmate:fleet-health" "$HOME/firstmate/bin/fm-herdr-health.sh"

# --- Repo test suites ---
run "mintmux:go-test" bash -c "cd $HOME/projects/mintmux && go test ./... >/dev/null 2>&1"
run "homebase:go-test" bash -c "cd $HOME/projects/homebase && go test ./... >/dev/null 2>&1"
run "trajectory:test" bash -c "cd $HOME/projects/trajectory && npm test >/dev/null 2>&1"

echo
echo "=== RESULT: $PASS passed, $FAIL failed ==="
if [[ $FAIL -gt 0 ]]; then
  printf 'FAILED: %s\n' "${FAILED[@]}"
  exit 1
fi
exit 0