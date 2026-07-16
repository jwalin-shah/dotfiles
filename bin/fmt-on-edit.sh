#!/bin/bash
# fmt-on-edit.sh - run after agent edits a file. Routes to correct formatter by extension.
# Claude Code sets CLAUDE_TOOL_INPUT_FILE_PATH. Other agents may set FILE_PATH.
FILE="${CLAUDE_TOOL_INPUT_FILE_PATH:-${FILE_PATH:-}}"
[ -z "$FILE" ] && exit 0
[ -f "$FILE" ] || exit 0

case "$FILE" in
  *.go)
    gofmt -w "$FILE"
    ;;
  *.py)
    command -v ruff >/dev/null 2>&1 && ruff format --quiet "$FILE" || true
    ;;
  *.swift)
    command -v swift-format >/dev/null 2>&1 && swift-format -i "$FILE" || true
    ;;
esac
