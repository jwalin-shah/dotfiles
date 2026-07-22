#!/bin/bash
# fmt-on-edit.sh - run after agent edits a file. Routes to correct formatter by extension.
# Claude Code sets CLAUDE_TOOL_INPUT_FILE_PATH. Other agents may set FILE_PATH.
# Also fans in Neo4j on-change sync for factory repos (async; never blocks format).
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

# Neo4j sole-store on-change (structure+CALLS). Single fan-in; see neo4j-on-change.sh.
if [ -x "${HOME}/.dotfiles/bin/neo4j-on-change.sh" ]; then
  CLAUDE_TOOL_INPUT_FILE_PATH="$FILE" "${HOME}/.dotfiles/bin/neo4j-on-change.sh" || true
elif [ -x "${HOME}/projects/dotfiles/bin/neo4j-on-change.sh" ]; then
  CLAUDE_TOOL_INPUT_FILE_PATH="$FILE" "${HOME}/projects/dotfiles/bin/neo4j-on-change.sh" || true
fi
