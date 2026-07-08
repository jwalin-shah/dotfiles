#!/usr/bin/env bash
set -euo pipefail

repo="/Users/jwalinshah/projects/dotfiles"

fail() {
  printf 'audit-config-ownership: %s\n' "$1" >&2
  exit 1
}

check_link() {
  local live=$1 expected=$2
  [ -e "$live" ] || fail "missing live file: $live"
  local target
  target=$(readlink "$live") || fail "not a symlink: $live"
  [ "$target" = "$expected" ] || fail "wrong target for $live: $target (expected $expected)"
}

check_content_match() {
  local live=$1 source=$2
  [ -e "$live" ] || fail "missing live file: $live"
  cmp -s "$live" "$source" || fail "content mismatch: $live vs $source"
}

check_content_match /Users/jwalinshah/.codex/config.toml "$repo/home/.codex/config.toml"
check_content_match /Users/jwalinshah/.codex/hooks.json "$repo/home/.codex/hooks.json"
check_content_match /Users/jwalinshah/.codex/rules/default.rules "$repo/home/.codex/rules/default.rules"
check_content_match /Users/jwalinshah/.claude/settings.json "$repo/home/.claude/settings.json"
check_content_match /Users/jwalinshah/.claude/CLAUDE.md "$repo/home/AGENTS.md"
check_content_match /Users/jwalinshah/.cursor/cli-config.json "$repo/home/.cursor/cli-config.json"
check_content_match /Users/jwalinshah/.cursor/hooks.json "$repo/home/.cursor/hooks.json"
check_content_match /Users/jwalinshah/.gemini/settings.json "$repo/home/.gemini/settings.json"
check_content_match /Users/jwalinshah/.gemini/config/hooks.json "$repo/home/.gemini/config/hooks.json"
check_content_match /Users/jwalinshah/.gemini/antigravity-cli/settings.json "$repo/home/.gemini/antigravity-cli/settings.json"
check_content_match /Users/jwalinshah/.config/kilo/kilo.jsonc "$repo/home/.config/kilo/kilo.jsonc"
check_content_match /Users/jwalinshah/.config/opencode/opencode.json "$repo/captain/config/opencode.json"
check_content_match /Users/jwalinshah/.config/opencode/AGENTS.md "$repo/home/AGENTS.md"
check_content_match /Users/jwalinshah/.config/herdr/config.toml "$repo/home/.config/herdr/config.toml"
check_content_match /Users/jwalinshah/.headroom-tr-proxy.toml "$repo/captain/config/headroom-tr-proxy.toml"
check_content_match /Users/jwalinshah/.config/jw/models.env "$repo/captain/config/models.env"
check_content_match /Users/jwalinshah/bin/ct "$repo/captain/bin/ct"
check_content_match /Users/jwalinshah/bin/audit-config-ownership.sh "$repo/bin/audit-config-ownership.sh"
check_content_match /Users/jwalinshah/bin/audit-doc-freshness.sh "$repo/bin/audit-doc-freshness.sh"
check_content_match /Users/jwalinshah/bin/verify-core-launchers.sh "$repo/bin/verify-core-launchers.sh"
check_content_match /Users/jwalinshah/bin/openwiki "$repo/captain/bin/openwiki"
check_content_match /Users/jwalinshah/bin/routing-proxy "$repo/captain/bin/routing-proxy"
check_content_match /Users/jwalinshah/bin/tokenrouter-proxy "$repo/captain/bin/tokenrouter-proxy"
check_content_match /Users/jwalinshah/bin/claude-launch "$repo/captain/bin/claude-launch"
check_content_match /Users/jwalinshah/bin/claude-endpoints.toml "$repo/captain/bin/claude-endpoints.toml"

stale_hits="$(
  rg -n \
    -g '!**/.git/**' \
    -g '!docs/archive/**' \
    -g '!templates/**' \
    -g '!**/node_modules/**' \
    -g '!**/audit-config-ownership.sh' \
    -g '!**/audit-doc-freshness.sh' \
    -e '/Users/jwalinshah/projects/machine-scratch' \
    -e 'tool-guard' \
    -e 'orca' \
    -e 'rtk' \
    -e 'machine-bootstrap router' \
    "$repo" || true
)"

if [ -n "$stale_hits" ]; then
  printf '%s\n' "$stale_hits" >&2
  fail "stale references found in active files"
fi

printf 'audit-config-ownership: ok\n'
