#!/usr/bin/env bash
# Mutation/property tests for the generated activation PATH invariant.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROVE="$ROOT/bin/prove-home-activation.sh"
actual_script="$($PROVE --print-script)"
base_export="$(rg '(^|[;{(&|])[ \t]*export[ \t]+PATH([= \t]|$)' "$actual_script" | head -n 1)"

fixture="$(mktemp -d "${TMPDIR:-/tmp}/prove-home-activation-mutations.XXXXXX")"
trap '/bin/rm -rf "$fixture"' EXIT

write_fixture() {
  local path="$1" mutation="$2" slot="$3" export_line="${4:-$base_export}"
  {
    printf '%s\n' '#!/usr/bin/env bash'
    [[ "$slot" == before ]] && printf '%s\n' "$mutation"
    printf '%s\n' "$export_line"
    [[ "$slot" == middle ]] && printf '%s\n' "$mutation"
    printf '%s\n' '_iNote "Activating %s" "linkGeneration"'
    [[ "$slot" == after ]] && printf '%s\n' "$mutation"
  } >"$path"
  :
}

expect_pass() {
  local label="$1" mutation="$2" slot="${3:-middle}" path
  path="$fixture/$label"
  write_fixture "$path" "$mutation" "$slot"
  if ! "$PROVE" --check-script "$path" >/dev/null 2>&1; then
    echo "prove-home-activation-mutations: expected PASS: $label" >&2
    exit 1
  fi
}

expect_fail() {
  local label="$1" mutation="$2" slot="$3" path
  path="$fixture/$label-$slot"
  write_fixture "$path" "$mutation" "$slot"
  if "$PROVE" --check-script "$path" >/dev/null 2>&1; then
    echo "prove-home-activation-mutations: expected FAIL: $label/$slot" >&2
    exit 1
  fi
}

# Scoped PATH changes do not leak into later activation nodes.
expect_pass scoped-assignment "PATH=\"/usr/bin:\$PATH\" /usr/bin/true"
expect_pass scoped-env "env PATH=\"/usr/bin:\$PATH\" /usr/bin/true"
expect_pass scoped-command "command env PATH=\"/usr/bin:\$PATH\" /usr/bin/true"

# Every global export form must be rejected at every activation position.
bad_mutations=(
  "export PATH=\"/usr/bin:\$PATH\""
  "  export PATH=\"/opt/homebrew/bin:\$PATH\""
  'PATH="/usr/bin"; export PATH'
  'PATH="/usr/bin" && export PATH'
  "{ export PATH=\"/usr/bin:\$PATH\"; }"
)
for i in "${!bad_mutations[@]}"; do
  for slot in before middle after; do
    expect_fail "global-$i" "${bad_mutations[$i]}" "$slot"
  done
done

# The checker must also reject a missing or non-GNU base tool path.
no_export="$fixture/no-export"
printf '%s\n' '#!/usr/bin/env bash' '/usr/bin/true' >"$no_export"
if "$PROVE" --check-script "$no_export" >/dev/null 2>&1; then
  echo "prove-home-activation-mutations: expected FAIL: no export" >&2
  exit 1
fi
bad_base="$fixture/bad-base"
write_fixture "$bad_base" '' middle 'export PATH="/usr/bin:/bin"'
if "$PROVE" --check-script "$bad_base" >/dev/null 2>&1; then
  echo "prove-home-activation-mutations: expected FAIL: non-GNU base" >&2
  exit 1
fi

echo "prove-home-activation-mutations: PASS (20 deterministic mutations)"
