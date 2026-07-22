#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" ~/.dotfiles

# Pre-trust Homebrew taps before Nix invokes homebrew-bundle
brew trust felixkratz/formulae 2>/dev/null || true
brew trust nikitabobko/tap 2>/dev/null || true
brew trust daytonaio/cli 2>/dev/null || true

# Apply nix changes
sudo $(command -v darwin-rebuild) switch --flake ~/.dotfiles#mac

# Refresh capability manifest (content hash changed)
if command -v bridge >/dev/null 2>&1; then
  echo "==> refreshing machine capability manifest"
  bridge verify-machine
fi

# Restart daemons that may have stale config after rebuild
for svc in com.jwalinshah.tldr-daemon com.jwalinshah.cocoindex-daemon; do
  launchctl kickstart -k "gui/$(id -u)/org.nixos.$svc" 2>/dev/null || true
done

echo "==> rebuild complete"
