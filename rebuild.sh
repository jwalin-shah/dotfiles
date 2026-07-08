#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" ~/.dotfiles
sudo darwin-rebuild switch --flake ~/.dotfiles#mac
"$DIR/bin/audit-config-ownership.sh"
exec "$DIR/bin/audit-doc-freshness.sh"
