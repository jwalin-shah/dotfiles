#!/usr/bin/env bash
# Contract tests for daemon-wrapper's Keychain projection boundary.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
WRAPPER="$ROOT/bin/daemon-wrapper"
tmp="$(mktemp -d /tmp/daemon-wrapper-secrets.XXXXXX)"

run_wrapper() {
  ORBIT_DATA_DIR="$tmp/data" \
  DAEMON_NAME="daemon-wrapper-contract" \
  DAEMON_PORT=0 \
  DAEMON_DISPLAY_NAME="daemon-wrapper-contract" \
  DAEMON_HEALTH_URL="pid-only" \
  DAEMON_TYPE="foreground" \
  "$WRAPPER" "$@"
}

if ! run_wrapper /usr/bin/true >/dev/null 2>&1; then
  echo "daemon-wrapper no-secret path failed" >&2
  exit 1
fi

set +e
missing_output="$(
  ORBIT_DATA_DIR="$tmp/missing" \
  DAEMON_NAME="daemon-wrapper-contract-missing" \
  DAEMON_PORT=0 \
  DAEMON_DISPLAY_NAME="daemon-wrapper-contract-missing" \
  DAEMON_HEALTH_URL="pid-only" \
  DAEMON_TYPE="foreground" \
  DAEMON_KEYCHAIN_SECRETS="DAEMON_WRAPPER_TEST_MISSING" \
  "$WRAPPER" /usr/bin/true 2>&1
)"
missing_exit=$?
set -e

if [[ "$missing_exit" -eq 0 || "$missing_output" != *"required Keychain secret DAEMON_WRAPPER_TEST_MISSING is unavailable"* ]]; then
  echo "daemon-wrapper did not fail closed on missing Keychain secret" >&2
  exit 1
fi

if [[ "$missing_output" == *"secret_value"* ]]; then
  echo "daemon-wrapper exposed secret internals in diagnostics" >&2
  exit 1
fi

if ! bash -n "$WRAPPER"; then
  echo "daemon-wrapper syntax failed" >&2
  exit 1
fi

echo "daemon-wrapper secret contract passed"
