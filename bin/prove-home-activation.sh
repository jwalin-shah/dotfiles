#!/usr/bin/env bash
# Prove the generated Home Manager activation preserves its tool PATH.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

resolve_activation_script() {
  local system_path activation_wrapper activation_script
  system_path="$(nix build "$ROOT#darwinConfigurations.mac.system" --no-link --print-out-paths)"
  activation_wrapper="$(
    nix-store -q --references "$system_path" \
      | rg -- '-activation-[^/]+$' \
      | head -n 1
  )"
  if [[ -z "$activation_wrapper" || ! -f "$activation_wrapper" ]]; then
    echo "prove-home-activation: generated user activation wrapper not found" >&2
    return 1
  fi

  activation_script="$(
    sed -nE 's|^exec ([^ ]+-home-manager-generation/activate).*|\1|p' \
      "$activation_wrapper"
  )"
  if [[ -z "$activation_script" || ! -f "$activation_script" ]]; then
    echo "prove-home-activation: Home Manager activate script not found" >&2
    return 1
  fi
  printf '%s\n' "$activation_script"
}

check_activation_script() {
  local activation_script="$1" path_exports path_export_count coreutils_bin

  # Home Manager owns exactly one global PATH export at script startup. Custom
  # nodes must scope PATH to their command. Detect direct, indented, grouped,
  # and command-chained exports instead of relying on one formatting shape.
  path_exports="$(
    rg -n '(^|[;{(&|])[ \t]*export[ \t]+PATH([= \t]|$)' \
      "$activation_script" || true
  )"
  path_export_count="$(printf '%s\n' "$path_exports" | sed '/^$/d' | wc -l | tr -d ' ')"
  if [[ "$path_export_count" -ne 1 ]]; then
    echo "prove-home-activation: expected one global PATH export, got $path_export_count" >&2
    printf '%s\n' "$path_exports" >&2
    return 1
  fi

  coreutils_bin="$(
    rg -o '/nix/store/[^:"]+-coreutils-[^/:"]+/bin' "$activation_script" \
      | head -n 1
  )"
  if [[ -z "$coreutils_bin" || ! -x "$coreutils_bin/readlink" ]]; then
    echo "prove-home-activation: generated PATH lacks GNU coreutils readlink" >&2
    return 1
  fi
  "$coreutils_bin/readlink" -e "$activation_script" >/dev/null
}

case "${1:-}" in
  --print-script)
    resolve_activation_script
    exit
    ;;
  --check-script)
    [[ $# -eq 2 ]] || { echo "usage: $0 --check-script <path>" >&2; exit 2; }
    check_activation_script "$2"
    ;;
  "")
    check_activation_script "$(resolve_activation_script)"
    ;;
  *)
    echo "usage: $0 [--print-script | --check-script <path>]" >&2
    exit 2
    ;;
esac

echo "prove-home-activation: PASS (one global PATH; GNU readlink -e available)"
