#!/usr/bin/env bash
# Prove the generated Home Manager activation preserves its tool PATH.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
system_path="$(nix build "$ROOT#darwinConfigurations.mac.system" --no-link --print-out-paths)"

activation_wrapper="$(
  nix-store -q --references "$system_path" \
    | rg -- '-activation-[^/]+$' \
    | head -n 1
)"
if [[ -z "$activation_wrapper" || ! -f "$activation_wrapper" ]]; then
  echo "prove-home-activation: generated user activation wrapper not found" >&2
  exit 1
fi

activation_script="$(
  sed -nE 's|^exec ([^ ]+-home-manager-generation/activate).*|\1|p' \
    "$activation_wrapper"
)"
if [[ -z "$activation_script" || ! -f "$activation_script" ]]; then
  echo "prove-home-activation: Home Manager activate script not found" >&2
  exit 1
fi

# Home Manager owns exactly one global PATH export at script startup. Custom
# activation nodes must scope PATH to their command; exporting another PATH can
# shadow GNU coreutils before standard nodes such as linkGeneration run.
path_exports="$(rg -n '^export PATH=' "$activation_script" || true)"
path_export_count="$(printf '%s\n' "$path_exports" | sed '/^$/d' | wc -l | tr -d ' ')"
if [[ "$path_export_count" -ne 1 ]]; then
  echo "prove-home-activation: expected one global PATH export, got $path_export_count" >&2
  printf '%s\n' "$path_exports" >&2
  exit 1
fi

coreutils_bin="$(
  rg -o '/nix/store/[^:"]+-coreutils-[^/:"]+/bin' "$activation_script" \
    | head -n 1
)"
if [[ -z "$coreutils_bin" || ! -x "$coreutils_bin/readlink" ]]; then
  echo "prove-home-activation: generated PATH lacks GNU coreutils readlink" >&2
  exit 1
fi
"$coreutils_bin/readlink" -e "$activation_script" >/dev/null

echo "prove-home-activation: PASS (one global PATH; GNU readlink -e available)"
