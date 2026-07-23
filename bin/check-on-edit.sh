#!/bin/bash
# check-on-edit.sh - run lightweight type/lint checks after agent edits a file.
# Claude Code sets CLAUDE_TOOL_INPUT_FILE_PATH. Other agents may set FILE_PATH.
# Exits silently (with true) if nothing applies — never blocks the agent.
#
# IMPORTANT: diagnostics go to stderr. Claude Code JSON-parses PostToolUse
# stdout; plain lint text starting with "{" or free-form text triggers
# "Hook JSON output validation failed".
FILE="${CLAUDE_TOOL_INPUT_FILE_PATH:-${FILE_PATH:-}}"
[ -z "$FILE" ] && exit 0
[ -f "$FILE" ] || exit 0

case "$FILE" in
  *.py)
    command -v ruff >/dev/null 2>&1 && ruff check --quiet "$FILE" >&2 || true
    ;;
  *.ts|*.tsx)
    DIR="$(dirname "$FILE")"
    while [ "$DIR" != "/" ]; do
      if [ -f "$DIR/tsconfig.json" ]; then
        command -v npx >/dev/null 2>&1 && \
          (cd "$DIR" && npx tsc --noEmit 2>&1 | head -20 >&2) || true
        break
      fi
      DIR="$(dirname "$DIR")"
    done
    ;;
  *.rs)
    if [ -f "Cargo.toml" ] || [ -f "$(dirname "$FILE")/Cargo.toml" ]; then
      command -v cargo >/dev/null 2>&1 && cargo check 2>&1 | tail -10 >&2 || true
    fi
    ;;
  *.go)
    command -v go >/dev/null 2>&1 && go vet "$(dirname "$FILE")" >&2 || true
    ;;
esac
exit 0
