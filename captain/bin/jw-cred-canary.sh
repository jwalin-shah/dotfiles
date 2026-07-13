#!/usr/bin/env bash
# jw-cred-canary — daily 1-request auth check per provider credential.
# Catches expired/rotated keys at 9am instead of mid-overnight-run.
# On failure: macOS notification + launch_failed event on the jw bus.
set -u

EVENTS="$HOME/.local/share/jw/events.jsonl"
FAILS=0

check() {
  local name=$1 url=$2 header=$3
  local code
  code=$("$HOME/.local/bin/secret-cache" exec -- bash -c \
    "curl -sS -m 10 -o /dev/null -w '%{http_code}' '$url' -H \"$header\"" 2>/dev/null) || code=000
  if [ "$code" = "200" ]; then
    return 0
  fi
  FAILS=$((FAILS+1))
  local msg="credential canary: $name auth check returned HTTP $code"
  echo "$msg" >&2
  osascript -e "display notification \"$msg\" with title \"jw-cred-canary\"" 2>/dev/null || true
  printf '{"ts":"%s","source":"cred-canary","event":"credential_failed","text":"%s HTTP %s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$name" "$code" >> "$EVENTS" 2>/dev/null || true
}

# Providers whose keys back unattended agent work. Extend one line per provider.
check tokenrouter "https://api.tokenrouter.com/v1/models" 'Authorization: Bearer $TOKENROUTER_API_KEY'
check openrouter  "https://openrouter.ai/api/v1/models"   'Authorization: Bearer $OPENROUTER_API_KEY'

if [ "$FAILS" = 0 ]; then
  printf '{"ts":"%s","source":"cred-canary","event":"credential_ok","text":"all provider keys healthy"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$EVENTS" 2>/dev/null || true
fi
exit "$FAILS"
