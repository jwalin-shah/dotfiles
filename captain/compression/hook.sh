#!/usr/bin/env bash
# Compression hook wrapper - pipe launcher output through compression
# Usage: launcher_command | compression-hook
set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON3="${PYTHON3:-$(which python3)}"

# Run the compression hook
exec "$PYTHON3" "$HOOK_DIR/hook.py" "$@"
