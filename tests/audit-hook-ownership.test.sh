#!/usr/bin/env bash
# Tests for bin/audit-hook-ownership.sh. Hermetic: builds a fake HOME with a
# fixture dotfiles repo and fixture harness hook configs, then asserts the
# auditor classifies each target and fails closed correctly.
set -uo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
SCRIPT="$HERE/../bin/audit-hook-ownership.sh"
fails=0
ok()   { printf 'ok - %s\n' "$1"; }
bad()  { printf 'not ok - %s\n' "$1" >&2; fails=$((fails + 1)); }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# --- fixture dotfiles repo (home.nix marks the root; copy the script in) ------
repo="$tmp/dotfiles"
mkdir -p "$repo/bin"
: > "$repo/home.nix"
cp "$SCRIPT" "$repo/bin/audit-hook-ownership.sh"
chmod +x "$repo/bin/audit-hook-ownership.sh"

# --- fixture harness configs under a fake HOME --------------------------------
fake_home="$tmp/home"
mkdir -p "$fake_home/.claude" "$fake_home/.codex" "$fake_home/.cursor" \
         "$fake_home/.gemini/config" "$fake_home/targets"

# An OWNED target: a symlink whose real path is inside the repo.
real_owned="$repo/bin/hook-owned.sh"; printf '#!/bin/sh\n' > "$real_owned"; chmod +x "$real_owned"
ln -s "$real_owned" "$fake_home/targets/owned.sh"
# An UNOWNED target: a hand-placed regular file.
printf '#!/bin/sh\n' > "$fake_home/targets/manual.sh"; chmod +x "$fake_home/targets/manual.sh"
# A MISSING target: referenced but never created ($fake_home/targets/gone.sh).

# claude: owned target -> should pass.
cat > "$fake_home/.claude/settings.json" <<JSON
{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"bash '$fake_home/targets/owned.sh' session"}]}]}}
JSON
# codex: missing target -> should violate.
cat > "$fake_home/.codex/hooks.json" <<JSON
{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"bash '$fake_home/targets/gone.sh' session"}]}]}}
JSON
# cursor: unowned (manual) target -> should violate.
cat > "$fake_home/.cursor/hooks.json" <<JSON
{"hooks":{"sessionStart":[{"command":"bash '$fake_home/targets/manual.sh' session"}]}}
JSON
# gemini: nested shape (PreToolUse) with a missing target -> should violate.
cat > "$fake_home/.gemini/config/hooks.json" <<JSON
{"g":{"PreToolUse":[{"hooks":[{"type":"command","command":"$fake_home/targets/gone.sh"}]}]}}
JSON

run() { HOME="$fake_home" bash "$repo/bin/audit-hook-ownership.sh" 2>&1; }

out=$(run); rc=$?

# --- assertions ---------------------------------------------------------------
printf '%s\n' "$out" | grep -q "OK .*owned.sh \[OWNED" \
  && ok "owned symlink into repo is reported OWNED" \
  || bad "owned target not reported OWNED"$'\n'"$out"

printf '%s\n' "$out" | grep -q "VIOLATED .*gone.sh \[MISSING" \
  && ok "missing target is a violation" \
  || bad "missing target not flagged"$'\n'"$out"

printf '%s\n' "$out" | grep -q "VIOLATED .*manual.sh \[UNOWNED" \
  && ok "hand-placed regular file is a violation" \
  || bad "unowned target not flagged"$'\n'"$out"

printf '%s\n' "$out" | grep -q "gemini .*gone.sh \[MISSING" \
  && ok "nested gemini PreToolUse shape is parsed" \
  || bad "nested gemini command not extracted"$'\n'"$out"

[ "$rc" -eq 1 ] \
  && ok "exit 1 when violations exist (fails closed)" \
  || bad "expected exit 1 with violations, got $rc"

# --- fail closed when the repo cannot be located ------------------------------
# Copy the script somewhere with no home.nix parent and a HOME lacking ~/dotfiles.
lonely="$tmp/lonely"; mkdir -p "$lonely/bin"
cp "$SCRIPT" "$lonely/bin/audit-hook-ownership.sh"
empty_home="$tmp/empty-home"; mkdir -p "$empty_home"
HOME="$empty_home" bash "$lonely/bin/audit-hook-ownership.sh" >/dev/null 2>&1
[ "$?" -eq 2 ] \
  && ok "exit 2 (fail closed) when the repo cannot be located" \
  || bad "expected exit 2 when repo not found"

if [ "$fails" -eq 0 ]; then
  echo "PASS: all audit-hook-ownership tests"
else
  echo "FAIL: $fails assertion(s)" >&2
  exit 1
fi
