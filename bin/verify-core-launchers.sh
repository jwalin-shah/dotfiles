#!/usr/bin/env bash
set -euo pipefail

need() {
  local cmd=$1
  command -v "$cmd" >/dev/null 2>&1 || {
    printf 'verify-core-launchers: missing command: %s\n' "$cmd" >&2
    exit 1
  }
}

need treehouse
need npx
need openwiki
need ct
need routing-proxy
need tokenrouter-proxy
need claude-launch

if ! zsh -ic 'alias gha >/dev/null && alias cda >/dev/null && alias lva >/dev/null'; then
  printf 'verify-core-launchers: missing AXI aliases gha/cda/lva\n' >&2
  exit 1
fi

printf 'verify-core-launchers: ok\n'
