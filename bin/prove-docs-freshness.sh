#!/usr/bin/env bash
# prove-docs-freshness.sh — fail closed when MACHINE.md / SYSTEM_MAP.md drift from live reality.
# Forces documentation to stay honest: undeclared PARKED services must stay off,
# required skills must exist, orbit/bridge on PATH, SYSTEM_MAP must document live gates.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
export PATH="${HOME}/.local/bin:${HOME}/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

FAIL=0
ok() { echo "OK: $*"; }
fail() { echo "FAIL: $*" >&2; FAIL=1; }

MACHINE="${ROOT}/MACHINE.md"
MAP="${ROOT}/docs/SYSTEM_MAP.md"
OPS="${ROOT}/docs/OPERATING.md"
AGENTS="${ROOT}/AGENTS.md"
README="${ROOT}/README.md"

# --- required docs exist ---
for f in "$MACHINE" "$MAP" "$OPS" "$AGENTS"; do
  if [[ -f "$f" ]]; then
    ok "present $(basename "$(dirname "$f")")/$(basename "$f")"
  else
    fail "missing $f"
  fi
done

# --- MACHINE.md must link system map and carry freshness stamp ---
if rg -q 'docs/SYSTEM_MAP\.md' "$MACHINE"; then
  ok "MACHINE.md links docs/SYSTEM_MAP.md"
else
  fail "MACHINE.md must link docs/SYSTEM_MAP.md"
fi
if rg -q 'Last updated: 2026-' "$MACHINE"; then
  ok "MACHINE.md has Last updated stamp"
else
  fail "MACHINE.md missing 'Last updated: 2026-…' stamp"
fi

# --- OPERATING.md required topics ---
for needle in 'worktree' 'commit' 'Lane A' 'Lane B' 'Lane C' 'bridge deliver' 'HomeBase'; do
  if rg -q --fixed-strings "$needle" "$OPS"; then
    ok "OPERATING mentions $needle"
  else
    fail "OPERATING.md missing required mention: $needle"
  fi
done

# --- SYSTEM_MAP required sections ---
for needle in 'Orbit' 'Bridge' 'HomeBase' 'Seatbelt' 'Knowledge Engine' 'prove-docs-freshness' 'BRIDGE_ALLOW_UNSAFE_LOCAL_MODE' 'PARKED'; do
  if rg -q --fixed-strings "$needle" "$MAP"; then
    ok "SYSTEM_MAP mentions $needle"
  else
    fail "SYSTEM_MAP.md missing required mention: $needle"
  fi
done

# --- AGENTS / README entry points ---
if rg -q 'SYSTEM_MAP' "$AGENTS"; then
  ok "AGENTS.md points at SYSTEM_MAP"
else
  fail "AGENTS.md must point agents at docs/SYSTEM_MAP.md"
fi
if [[ -f "$README" ]] && rg -q 'SYSTEM_MAP|Machine constitution|docs/SYSTEM_MAP' "$README"; then
  ok "README.md points at system map / constitution"
else
  fail "README.md must link docs/SYSTEM_MAP.md near the top"
fi

# --- PARKED / REMOVED must stay off ---
if launchctl list 2>/dev/null | rg -q 'mlx-chat'; then
  fail "mlx-chat LaunchAgent loaded — PARKED; unload or update MACHINE.md + ticket"
else
  ok "mlx-chat not loaded (PARKED)"
fi
if launchctl list 2>/dev/null | rg -q 'cocoindex-daemon'; then
  fail "cocoindex-daemon loaded — REMOVED; do not re-enable"
else
  ok "cocoindex-daemon not loaded (REMOVED)"
fi

# --- declared core surfaces on PATH ---
for bin in orbit bridge; do
  if command -v "$bin" >/dev/null 2>&1; then
    ok "PATH $bin"
  else
    fail "missing on PATH: $bin (MACHINE/SYSTEM_MAP claim orbit+bridge captains)"
  fi
done

# --- skills prove (source of truth under .agents) ---
if [[ -x "${ROOT}/bin/prove-skills.sh" ]]; then
  if "${ROOT}/bin/prove-skills.sh" >/dev/null; then
    ok "prove-skills.sh PASS"
  else
    fail "prove-skills.sh FAILED — restore skills under .agents/"
  fi
else
  fail "missing bin/prove-skills.sh"
fi

# --- MACHINE claims neo4j sole store; brew service should be started ---
if brew services list 2>/dev/null | rg -q 'neo4j[[:space:]]+started'; then
  ok "neo4j brew service started"
else
  fail "neo4j not started (MACHINE.md claims sole store at :7687)"
fi

# --- bridge-serve loaded (orbit surface) ---
if launchctl list 2>/dev/null | rg -q 'org\.nixos\.com\.jwalinshah\.bridge-serve'; then
  ok "bridge-serve LaunchAgent listed"
else
  fail "bridge-serve not in launchctl (SYSTEM_MAP claims orbit→bridge-serve)"
fi

# --- HomeBase gap must be documented (spawn blocker) ---
if rg -q 'HomeBase' "$MAP" && rg -q 'BRIDGE_HOMEBASE_URL' "$MAP"; then
  ok "SYSTEM_MAP documents HomeBase spawn requirement"
else
  fail "SYSTEM_MAP must document HomeBase / BRIDGE_HOMEBASE_URL spawn gate"
fi

# --- portfolio one-surface pointer ---
PORT_MAP="${HOME}/projects/portfolio/wayfinder/one-surface-system-2026-07-30/map.md"
if [[ -f "$PORT_MAP" ]]; then
  ok "portfolio one-surface map present"
else
  fail "missing portfolio one-surface map (SYSTEM_MAP cross-link)"
fi

if [[ "$FAIL" -ne 0 ]]; then
  echo "prove-docs-freshness: FAILED" >&2
  exit 1
fi
echo "prove-docs-freshness: PASS"
exit 0
