#!/usr/bin/env bash
# Prove the DSH Infisical launch boundary without exposing secret values.
# shellcheck disable=SC2016
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
WRAPPER="$ROOT/bin/dsh-infisical"

[[ -x "$WRAPPER" ]] || { echo "FAIL: dsh-infisical is not executable" >&2; exit 1; }
command -v infisical >/dev/null 2>&1 || { echo "FAIL: infisical CLI missing" >&2; exit 1; }
command -v pnpm >/dev/null 2>&1 || { echo "FAIL: pnpm missing" >&2; exit 1; }

presence="$(
  infisical run --env "${DSH_INFISICAL_ENV:-dev}" --path "${DSH_INFISICAL_PATH:-/providers}" -- \
    sh -c 'if [ -n "${GMI_API_KEY:-}" ]; then printf present; else printf absent; fi'
)"
if [[ "$presence" != "present" ]]; then
  echo "FAIL: Infisical did not inject GMI_API_KEY" >&2
  exit 1
fi

bash -n "$WRAPPER"
"$WRAPPER" --version >/dev/null
echo "PASS: Infisical injects GMI_API_KEY and dsh-infisical boots dsh without exposing the value"
