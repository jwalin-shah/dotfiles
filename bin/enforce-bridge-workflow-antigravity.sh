#!/usr/bin/env bash
# Same machine-wide policy as enforce-bridge-workflow.sh (all ~/projects/*).
set -u
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"
exec /Users/jwalinshah/.dotfiles/bin/enforce-bridge-workflow.sh
