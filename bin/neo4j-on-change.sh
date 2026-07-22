#!/usr/bin/env bash
# Single fan-in trigger: map edited file → factory repo → on-change-sync (async).
# Wired from fmt-on-edit.sh (PostToolUse). Does not write Neo4j itself.
set -euo pipefail

FILE="${CLAUDE_TOOL_INPUT_FILE_PATH:-${FILE_PATH:-${1:-}}}"
[ -z "$FILE" ] && exit 0

# Resolve absolute path
case "$FILE" in
  /*) ABS="$FILE" ;;
  *) ABS="$(cd "$(dirname "$FILE")" 2>/dev/null && pwd)/$(basename "$FILE")" ;;
esac

PROJECTS="${HOME}/projects"
case "$ABS" in
  "$PROJECTS"/*) ;;
  *) exit 0 ;;
esac

REL="${ABS#"$PROJECTS"/}"
REPO="${REL%%/*}"
[ -z "$REPO" ] || [ "$REPO" = "$REL" ] && exit 0

FACTORY="axioms knowledge-engine dotfiles portfolio mintmux btw-v1 orbit bridge"
case " $FACTORY " in
  *" $REPO "*) ;;
  *) exit 0 ;;
esac

# Only code-ish paths matter for structure/CALLS (skip noise).
case "$ABS" in
  */.git/*|*/node_modules/*|*/.venv/*|*/__pycache__/*|*/target/*|*/dist/*|*/.tldr/*) exit 0 ;;
esac
case "$ABS" in
  *.py|*.go|*.ts|*.tsx|*.js|*.jsx|*.rs|*.swift|*.md|*.json|*.toml|*.nix|*.sh) ;;
  *) exit 0 ;;
esac

SYNC="${HOME}/projects/knowledge-engine/scripts/on-change-sync.sh"
[ -x "$SYNC" ] || exit 0

# Background: never block the editor/agent formatter.
nohup "$SYNC" "$REPO" >/dev/null 2>&1 &
exit 0
