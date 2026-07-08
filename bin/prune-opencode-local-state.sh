#!/usr/bin/env bash
set -euo pipefail

exec "$(dirname "$0")/prune-agent-local-state.sh" opencode "$@"
