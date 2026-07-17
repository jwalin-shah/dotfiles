#!/usr/bin/env bash
# audit-hook-ownership.sh - deterministic per-harness hook-ownership audit.
#
# For every agent harness, resolve its hook config to the actual command
# target(s) it runs, then verify each target: it exists, is executable, and is
# declaratively OWNED (a home-manager symlink into the nix store or the repo),
# not a hand-placed regular file. Fails CLOSED: a missing repo root, or a
# missing / non-executable / unowned target, is a VIOLATION - never a silent
# skip. This replaces eyeball-grepping a harness directory (or a transcript log)
# to guess what a hook runs and who owns it.
#
# Exit: 0 all owned+executable, 1 one or more violations, 2 repo not locatable.
set -uo pipefail

HOME_DIR="${HOME:?}"

# --- resolve the dotfiles repo from this script's own location, fail closed ---
# Run from the repo (bin/…), $0 resolves inside it. Run from a deployed nix-store
# copy, that resolution lands in the store, so fall back to the conventional
# repo path - then require home.nix either way so a wrong root fails closed
# instead of silently auditing nothing (the old hardcoded-path failure mode).
resolve_repo() {
  local self dir
  self=$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")
  dir=$(cd "$(dirname "$self")/.." 2>/dev/null && pwd -P || true)
  if [ -n "$dir" ] && [ -f "$dir/home.nix" ]; then printf '%s\n' "$dir"; return 0; fi
  if [ -f "$HOME_DIR/dotfiles/home.nix" ]; then printf '%s\n' "$HOME_DIR/dotfiles"; return 0; fi
  return 1
}
REPO=$(resolve_repo) || {
  echo "audit-hook-ownership: FAIL closed - cannot locate the dotfiles repo (no home.nix)" >&2
  exit 2
}

violations=0
ok()  { printf 'OK        %s\n' "$*"; }
bad() { printf 'VIOLATED  %s\n' "$*"; violations=$((violations + 1)); }

# Classify a hook command target path by ownership.
classify_target() {
  local t=$1 real
  if [ -L "$t" ]; then
    if [ ! -e "$t" ]; then echo "MISSING(dangling-symlink)"; return; fi
    real=$(readlink -f "$t" 2>/dev/null || true)
    case "$real" in
      /nix/store/*) [ -x "$t" ] && echo "OWNED(nix)" || echo "OWNED-BUT-NOT-EXECUTABLE" ;;
      "$REPO"/*)    [ -x "$t" ] && echo "OWNED(repo)" || echo "OWNED-BUT-NOT-EXECUTABLE" ;;
      *)            echo "UNOWNED(symlink-outside-nix-and-repo)" ;;
    esac
  elif [ -e "$t" ]; then
    real=$(readlink -f "$t" 2>/dev/null || true)
    case "$real" in
      "$REPO"/*) [ -x "$t" ] && echo "OWNED(repo)" || echo "OWNED-BUT-NOT-EXECUTABLE" ;;
      *)         echo "UNOWNED(hand-placed-regular-file)" ;;
    esac
  else
    echo "MISSING(target-does-not-exist)"
  fi
}

# Extract every absolute .sh command target from a hook config's command strings.
# jq '[.. | .command?]' finds command keys at ANY nesting (Claude/Codex/Cursor
# use a flat hooks map; Gemini nests under PreInvocation/PreToolUse), so one
# extractor handles every harness shape.
extract_targets() {
  local cfg=$1
  [ -f "$cfg" ] || return 0
  jq -r '[.. | .command? // empty] | .[]' "$cfg" 2>/dev/null \
    | grep -oE "/[^ \"']+\.sh" || true
}

# Audit one harness. Args: label config-file
audit_harness() {
  local label=$1 cfg=$2 t cls found=0
  if [ ! -f "$cfg" ]; then
    printf -- '-         %s: no hook config (%s) - nothing to load\n' "$label" "$cfg"
    return 0
  fi
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    found=1
    cls=$(classify_target "$t")
    case "$cls" in
      OWNED\(*) ok "$label -> $t [$cls]" ;;
      *)        bad "$label -> $t [$cls]" ;;
    esac
  done < <(extract_targets "$cfg")
  [ "$found" = 1 ] || printf -- '-         %s: hook config present but declares no command targets\n' "$label"
}

echo "== hook-ownership audit (repo: $REPO) =="
audit_harness "claude(.claude)"       "$HOME_DIR/.claude/settings.json"
audit_harness "claude(.claude-a)"     "$HOME_DIR/.claude-a/settings.json"
audit_harness "claude(.claude-token)" "$HOME_DIR/.claude-token/settings.json"
audit_harness "codex"                 "$HOME_DIR/.codex/hooks.json"
audit_harness "cursor"                "$HOME_DIR/.cursor/hooks.json"
audit_harness "gemini"                "$HOME_DIR/.gemini/config/hooks.json"
echo "== $violations violation(s) =="

[ "$violations" -eq 0 ]
