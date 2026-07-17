#!/usr/bin/env bash
# ── Cognee API daemon launcher ───────────────────────────────────────
# Thin wrapper: sets daemon-wrapper env vars, then delegates.
# The real contract enforcement (flock, crash-loop, lifecycle log) lives
# in daemon-wrapper. Prefer the Nix LaunchAgent entry in configuration.nix
# for production use; this script is for manual ad-hoc starts.
set -euo pipefail

HOME="${HOME:-$(eval echo ~$(whoami))}"
COGNEE_PYTHON="$HOME/.local/share/uv/tools/cognee/bin/python"
ENV_FILE="$HOME/.config/jw/models.env"

exec env \
  HOME="$HOME" \
  DAEMON_NAME="cognee-api" \
  DAEMON_PORT="8000" \
  DAEMON_DISPLAY_NAME="cognee-api:8000" \
  DAEMON_TYPE="foreground" \
  DAEMON_HEALTH_URL="/health" \
  DAEMON_ENV_FILE="$ENV_FILE" \
  DAEMON_VALIDATION_CMD="$COGNEE_PYTHON -c 'import cognee; print(\"OK\")'" \
  "$HOME/.dotfiles/bin/daemon-wrapper" \
  "$COGNEE_PYTHON" \
  -m uvicorn cognee.api.client:app \
  --host 127.0.0.1 --port 8000
