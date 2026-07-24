#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/prove-pi-cockpit.XXXXXX")"
trap '/bin/rm -rf "$fixture"' EXIT
stubs="$fixture/bin"
log="$fixture/calls.log"
mkdir -p "$stubs" "$fixture/workspace"

printf '%s\n' '#!/bin/sh' 'exit 0' > "$stubs/pi"
# These single-quoted lines are the literal bodies of generated test stubs.
# shellcheck disable=SC2016
printf '%s\n' \
  '#!/bin/sh' \
  'printf '\''attach\t%s\n'\'' "$*" >> "$PI_COCKPIT_TEST_LOG"' \
  > "$stubs/mm-attach"
# shellcheck disable=SC2016
printf '%s\n' \
  '#!/bin/sh' \
  'case "$1" in' \
  '  ping) exit 0 ;;' \
  '  list-panes)' \
  '    case "$PI_COCKPIT_TEST_CASE" in' \
  '      live) echo '\''meta map[panes:[map[id:7 window:1]] session:test]'\'' ;;' \
  '      empty) echo '\''meta map[panes:[] session:test]'\'' ;;' \
  '      missing) exit 1 ;;' \
  '    esac' \
  '    ;;' \
  '  kill-session|new-session)' \
  '    printf '\''%s\t%s\n'\'' "$1" "$*" >> "$PI_COCKPIT_TEST_LOG"' \
  '    ;;' \
  'esac' \
  > "$stubs/mm-ctl"
chmod 0755 "$stubs/pi" "$stubs/mm-attach" "$stubs/mm-ctl"

run_case() {
  local test_case="$1"
  : > "$log"
  PI_COCKPIT_TEST_CASE="$test_case" \
  PI_COCKPIT_TEST_LOG="$log" \
  PATH="$stubs:/opt/homebrew/bin:/usr/bin:/bin" \
    "$ROOT/bin/pi-cockpit" --session test "$fixture/workspace"
}

run_case live
rg -q '^attach' "$log"
if rg -q 'new-session|kill-session' "$log"; then
  echo "prove-pi-cockpit: live session was replaced" >&2
  exit 1
fi

run_case missing
rg -q '^new-session' "$log"
if rg -q -- ' -c($| )' "$log"; then
  echo "prove-pi-cockpit: first launch unexpectedly requested continuation" >&2
  exit 1
fi
rg -q '^attach' "$log"

run_case empty
rg -q '^kill-session' "$log"
rg -q '^new-session.* -c' "$log"
rg -q '^attach' "$log"

echo "prove-pi-cockpit: PASS (reattach, first start, empty-pane resume)"
