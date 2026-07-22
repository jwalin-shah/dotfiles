#!/usr/bin/env bash
# Fail closed if githits is on PATH but not authenticated.
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

if ! command -v githits >/dev/null 2>&1; then
  echo "FAIL: githits not on PATH — install Homebrew githits" >&2
  exit 1
fi

if ! githits auth status >/dev/null 2>&1; then
  echo "FAIL: githits not authenticated. Run: githits login" >&2
  githits auth status 2>&1 || true
  exit 1
fi

echo "OK: githits authenticated ($(githits -V 2>/dev/null || true))"
exit 0
