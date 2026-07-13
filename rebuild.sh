#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" ~/.dotfiles

# Automatically pre-trust third-party Homebrew taps before Nix invokes homebrew-bundle
brew trust felixkratz/formulae 2>/dev/null || true

sudo darwin-rebuild switch --flake ~/.dotfiles#mac
"$DIR/bin/audit-config-ownership.sh"
"$DIR/bin/audit-hook-ownership.sh"
exec "$DIR/bin/audit-doc-freshness.sh"
