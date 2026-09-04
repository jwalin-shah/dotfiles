#!/usr/bin/env bash
# Bounded proof that OpenClaw is the nix LaunchAgent on :18789 and that
# inbox/HomeBase were not sacrificed for it. No secrets. No FDA on node.
set -euo pipefail
FAIL=0
ok() { echo "OK: $*"; }
fail() { echo "FAIL: $*" >&2; FAIL=1; }

UID_NUM="$(id -u)"
loaded="$(launchctl list 2>/dev/null || true)"

if echo "$loaded" | grep -q 'org.nixos.com.jwalinshah.openclaw-gateway'; then
  ok "nix OpenClaw LaunchAgent loaded"
else
  fail "org.nixos.com.jwalinshah.openclaw-gateway not loaded (darwin-rebuild not applied?)"
fi

if echo "$loaded" | grep -qE '[[:space:]]ai.openclaw.gateway$'; then
  fail "retired ai.openclaw.gateway still loaded (dual KeepAlive on :18789)"
else
  ok "retired ai.openclaw.gateway not loaded"
fi

if [[ -f "${HOME}/Library/LaunchAgents/ai.openclaw.gateway.plist" ]]; then
  fail "brew plist still in LaunchAgents (expected archived)"
else
  ok "brew OpenClaw plist not in LaunchAgents"
fi

listeners="$(lsof -nP -iTCP:18789 -sTCP:LISTEN 2>/dev/null || true)"
n="$(printf '%s\n' "$listeners" | awk 'NR>1 && /LISTEN/ {print $2}' | sort -u | wc -l | tr -d ' ')"
pids="$(printf '%s\n' "$listeners" | awk 'NR>1 && /LISTEN/ {print $2}' | sort -u | tr '\n' ' ')"
if [[ "$n" -eq 1 ]]; then
  ok "exactly one process on :18789 (pid ${pids})"
elif [[ "$n" -eq 0 ]]; then
  fail "nothing listening on :18789 (gateway down)"
else
  fail "multiple processes on :18789 (dual manager): ${pids}"
fi

if curl -sf -m 3 -o /dev/null http://127.0.0.1:9102/v1/status; then
  ok "HomeBase :9102 /v1/status"
else
  fail "HomeBase :9102 down"
fi

if curl -sf -m 3 -o /dev/null http://127.0.0.1:9849/health; then
  ok "inbox :9849 /health"
else
  fail "inbox :9849 down"
fi

if lsof -nP -iTCP:9847 -sTCP:LISTEN >/dev/null 2>&1; then
  fail "leftover HomeBase-drive still on :9847"
else
  ok "no listener on :9847"
fi

inbox_cmd="$(lsof -nP -iTCP:9849 -sTCP:LISTEN 2>/dev/null | awk 'NR==2 {print $1}')"
if [[ "$inbox_cmd" == python3.1* || "$inbox_cmd" == python* ]]; then
  ok "inbox listener is python (FDA identity stays here, not node)"
else
  fail "inbox listener is not python (got ${inbox_cmd:-none})"
fi

if [[ "$FAIL" -ne 0 ]]; then
  echo "prove-openclaw-cutover: FAILED" >&2
  exit 1
fi
echo "prove-openclaw-cutover: PASS"
exit 0
