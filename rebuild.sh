#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" ~/.dotfiles
"$DIR/bin/audit-config-ownership.sh"
"$DIR/bin/audit-doc-freshness.sh"
exec sudo darwin-rebuild switch --flake ~/.dotfiles#mac
