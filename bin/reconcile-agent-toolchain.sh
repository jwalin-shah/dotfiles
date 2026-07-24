#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
RECEIPT="${AGENT_TOOLCHAIN_RECEIPT:-${ROOT}/config/agent-toolchain.tsv}"
MODE="${1:-install}"

if [[ "$MODE" != "install" && "$MODE" != "check" ]]; then
  echo "usage: reconcile-agent-toolchain.sh [install|check]" >&2
  exit 2
fi
if [[ ! -f "$RECEIPT" ]]; then
  echo "agent-toolchain: missing version receipt: $RECEIPT" >&2
  exit 1
fi

NPM="$(command -v npm || true)"
UV="$(command -v uv || true)"
JQ="$(command -v jq || true)"
if [[ -z "$NPM" || -z "$UV" || -z "$JQ" ]]; then
  echo "agent-toolchain: npm, uv, and jq are required" >&2
  exit 1
fi

npm_root="$($NPM root -g)"
uv_inventory="$($UV tool list)"
failures=0

npm_version() {
  local package="$1"
  local manifest="${npm_root}/${package}/package.json"
  [[ -f "$manifest" ]] || return 1
  "$JQ" -er '.version' "$manifest" 2>/dev/null
}

uv_version() {
  local package="$1"
  awk -v package="$package" '
    $1 == package {
      version = $2
      sub(/^v/, "", version)
      print version
      exit
    }
  ' <<<"$uv_inventory"
}

while IFS=$'\t' read -r manager package expected extra; do
  [[ -z "$manager" || "$manager" == \#* ]] && continue
  if [[ -z "$package" || -z "$expected" || -n "$extra" ]]; then
    echo "agent-toolchain: malformed receipt row: $manager $package $expected $extra" >&2
    exit 1
  fi

  case "$manager" in
    npm|npm-safe)
      installed="$(npm_version "$package" || true)"
      if [[ "$installed" != "$expected" && "$MODE" == "install" ]]; then
        install_args=(install -g)
        [[ "$manager" == "npm-safe" ]] && install_args+=(--ignore-scripts)
        "$NPM" "${install_args[@]}" "${package}@${expected}"
        installed="$(npm_version "$package" || true)"
      fi
      ;;
    uv)
      installed="$(uv_version "$package")"
      if [[ "$installed" != "$expected" && "$MODE" == "install" ]]; then
        "$UV" tool install --force "${package}==${expected}"
        uv_inventory="$($UV tool list)"
        installed="$(uv_version "$package")"
      fi
      ;;
    *)
      echo "agent-toolchain: unknown manager '$manager' for $package" >&2
      exit 1
      ;;
  esac

  if [[ "$installed" == "$expected" ]]; then
    printf 'OK\t%s\t%s\t%s\n' "$manager" "$package" "$expected"
  else
    printf 'MISMATCH\t%s\t%s\texpected=%s\tinstalled=%s\n' \
      "$manager" "$package" "$expected" "${installed:-missing}" >&2
    failures=$((failures + 1))
  fi
done < "$RECEIPT"

if (( failures > 0 )); then
  echo "agent-toolchain: FAILED (${failures} mismatches)" >&2
  exit 1
fi

echo "agent-toolchain: VERIFIED"
