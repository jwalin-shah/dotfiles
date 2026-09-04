#!/usr/bin/env bash
# Adopt nix-darwin LaunchAgent com.jwalinshah.openclaw-gateway and drop the
# Homebrew/OpenClaw-generated ai.openclaw.gateway so they do not both bind
# :18789. Does not darwin-rebuild. Does not print secrets.
set -euo pipefail
UID_NUM="$(id -u)"
BREW_LABEL="ai.openclaw.gateway"
echo "bootout ${BREW_LABEL} (ok if already unloaded)"
launchctl bootout "gui/${UID_NUM}/${BREW_LABEL}" 2>/dev/null || true
if [[ -f "${HOME}/Library/LaunchAgents/${BREW_LABEL}.plist" ]]; then
  mkdir -p "${HOME}/Library/LaunchAgents/archive"
  mv "${HOME}/Library/LaunchAgents/${BREW_LABEL}.plist" \
    "${HOME}/Library/LaunchAgents/archive/${BREW_LABEL}.plist"
  echo "archived brew plist"
fi
echo "Next: darwin-rebuild switch --flake \"\$HOME/.dotfiles#mac\"  (quote #mac; nix agent RunAtLoad=true)"
echo "Then: curl -sS -m 2 -o /dev/null -w '%{http_code}\\n' http://127.0.0.1:18789/"
echo "Expect one listener: lsof -nP -iTCP:18789 -sTCP:LISTEN"
echo "Do not grant Full Disk Access to node/OpenClaw; inbox python3.12 keeps FDA."
