#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'audit-config-ownership: %s\n' "$1" >&2
  exit 1
}

# Resolve the repo from this script's own location, then fall back to the
# conventional path - and FAIL CLOSED if neither is the real repo. The old
# hardcoded /Users/jwalinshah/projects/dotfiles is now a 27-byte pointer file,
# not a directory, so every check_content_match died on a bogus mismatch.
resolve_repo() {
  local self dir
  self=$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")
  dir=$(cd "$(dirname "$self")/.." 2>/dev/null && pwd -P || true)
  if [ -n "$dir" ] && [ -f "$dir/home.nix" ]; then printf '%s\n' "$dir"; return 0; fi
  if [ -f "${HOME}/dotfiles/home.nix" ]; then printf '%s\n' "${HOME}/dotfiles"; return 0; fi
  return 1
}
repo=$(resolve_repo) || fail "cannot locate the dotfiles repo (no home.nix at script parent or ~/dotfiles)"

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

check_absent() {
  local live=$1
  [ ! -e "$live" ] || fail "unexpected file present: $live"
}

check_content_match /Users/jwalinshah/.codex/config.toml "$repo/home/.codex/config.toml"
check_content_match /Users/jwalinshah/.codex/hooks.json "$repo/home/.codex/hooks.json"
check_content_match /Users/jwalinshah/.codex/rules/default.rules "$repo/home/.codex/rules/default.rules"
check_content_match /Users/jwalinshah/.claude/settings.json "$repo/home/.claude/settings.json"
check_content_match /Users/jwalinshah/.claude/CLAUDE.md "$repo/home/AGENTS.md"
check_content_match /Users/jwalinshah/.cursor/cli-config.json "$repo/home/.cursor/cli-config.json"
check_content_match /Users/jwalinshah/.cursor/mcp.json "$repo/home/.cursor/mcp.json"
check_content_match /Users/jwalinshah/.cursor/hooks.json "$repo/home/.cursor/hooks.json"
check_content_match /Users/jwalinshah/.cursor/AGENTS.md "$repo/home/AGENTS.md"
check_content_match /Users/jwalinshah/.gemini/settings.json "$repo/home/.gemini/settings.json"
check_content_match /Users/jwalinshah/.gemini/config/mcp_config.json "$repo/home/.gemini/config/mcp_config.json"
check_content_match /Users/jwalinshah/.gemini/config/hooks.json "$repo/home/.gemini/config/hooks.json"
check_content_match /Users/jwalinshah/.gemini/antigravity-cli/settings.json "$repo/home/.gemini/antigravity-cli/settings.json"
check_content_match /Users/jwalinshah/.gemini/AGENTS.md "$repo/home/AGENTS.md"
check_content_match /Users/jwalinshah/.claude-a/settings.json "$repo/home/.claude/settings.json"
check_content_match /Users/jwalinshah/.claude-a/CLAUDE.md "$repo/home/AGENTS.md"
check_content_match /Users/jwalinshah/.claude-token/settings.json "$repo/home/.claude/settings.json"
check_content_match /Users/jwalinshah/.claude-token/CLAUDE.md "$repo/home/AGENTS.md"
check_absent /Users/jwalinshah/.config/opencode/AGENTS-face.md
check_absent /Users/jwalinshah/.config/opencode/profiles/face.json
check_content_match /Users/jwalinshah/.config/kilo/kilo.jsonc "$repo/home/.config/kilo/kilo.jsonc"
check_content_match /Users/jwalinshah/.config/kilo/AGENTS.md "$repo/home/AGENTS.md"
check_content_match /Users/jwalinshah/.config/opencode/opencode.json "$repo/captain/config/opencode.json"
check_content_match /Users/jwalinshah/.config/opencode/AGENTS.md "$repo/home/AGENTS.md"
check_content_match /Users/jwalinshah/.config/herdr/config.toml "$repo/home/.config/herdr/config.toml"
check_content_match /Users/jwalinshah/.config/jw/models.env "$repo/captain/config/models.env"
check_content_match /Users/jwalinshah/bin/ct "$repo/captain/bin/ct-wrapper"
check_content_match /Users/jwalinshah/bin/claude "$repo/captain/bin/claude-wrapper"
check_content_match /Users/jwalinshah/bin/audit-config-ownership.sh "$repo/bin/audit-config-ownership.sh"
check_content_match /Users/jwalinshah/bin/audit-doc-freshness.sh "$repo/bin/audit-doc-freshness.sh"
check_content_match /Users/jwalinshah/bin/openwiki "$repo/captain/bin/openwiki"
check_content_match /Users/jwalinshah/bin/jw-restart "$repo/captain/bin/jw-restart"
check_content_match /Users/jwalinshah/bin/ca "$repo/captain/bin/ca-wrapper"
check_content_match /Users/jwalinshah/bin/cu "$repo/captain/bin/cu-wrapper"
check_content_match /Users/jwalinshah/bin/oo "$repo/captain/bin/oo-wrapper"
check_content_match /Users/jwalinshah/bin/ot "$repo/captain/bin/ot-wrapper"
check_content_match /Users/jwalinshah/bin/ko "$repo/captain/bin/ko-wrapper"
check_content_match /Users/jwalinshah/bin/kt "$repo/captain/bin/kt-wrapper"
check_content_match /Users/jwalinshah/bin/cx "$repo/captain/bin/cx-wrapper"
check_content_match /Users/jwalinshah/.local/bin/oo "$repo/home/.local/bin/oo"
check_content_match /Users/jwalinshah/.local/bin/rtldr "$repo/home/.local/bin/rtldr"

stale_hits="$(
  rg -n \
    -g '!**/.git/**' \
    -g '!docs/archive/**' \
    -g '!templates/**' \
    -g '!**/node_modules/**' \
    -g '!**/audit-config-ownership.sh' \
    -g '!**/audit-doc-freshness.sh' \
    -e '/Users/jwalinshah/projects/machine-scratch' \
    -e 'orca' \
    -e 'rtk' \
    -e 'machine-bootstrap router' \
    "$repo" || true
)"

if [ -n "$stale_hits" ]; then
  printf '%s\n' "$stale_hits" >&2
  fail "stale references found in active files"
fi

# ── Verify everything referenced in configs exists ─────────────────

# 1. Every tool in TOOL_REGISTRY.md marked ACTIVE must be on PATH
echo "=== verifying TOOL_REGISTRY.md ACTIVE tools ==="
while IFS= read -r line; do
  tool=$(echo "$line" | sed 's/^[[:space:]]*| \([a-zA-Z0-9_-]*\).*/\1/')
  [ -z "$tool" ] && continue
  command -v "$tool" >/dev/null 2>&1 || echo "WARNING: $tool is ACTIVE in TOOL_REGISTRY.md but not on PATH"
done < <(grep '| ACTIVE' "$repo/captain/agent-rules/TOOL_REGISTRY.md" 2>/dev/null || true)

# 2. ~/.agent-rules/ must exist
[ -e "$HOME/.agent-rules" ] || echo "WARNING: ~/.agent-rules/ does not exist"

# 3. Every LaunchAgent binary referenced in configuration.nix must exist
echo "=== verifying LaunchAgent binaries ==="
while IFS= read -r binary; do
  [ -z "$binary" ] && continue
  eval "resolved=$binary" 2>/dev/null || true
  [ -x "$resolved" ] || echo "WARNING: LaunchAgent binary not found: $binary"
done < <(grep 'ProgramArguments.*\.local\|ProgramArguments.*/opt/homebrew' "$repo/configuration.nix" 2>/dev/null | sed 's/.*"\(.*\)".*/\1/' | head -20)

# 4. Every service in services.conf must have a reachable health check
echo "=== verifying services.conf ports ==="
while IFS= read -r line; do
  echo "$line" | grep -q '|http|' || continue
  addr=$(echo "$line" | cut -d'|' -f3)
  path=$(echo "$line" | cut -d'|' -f4)
  [ -z "$addr" ] && continue
  curl -sf --max-time 3 "http://${addr}${path}" >/dev/null 2>&1 || echo "WARNING: service health check failed: $addr$path"
done < <(grep -v '^#' "$HOME/.config/jw/services.conf" 2>/dev/null | grep '|')

# 5. Verify agent-rules symlink chain is intact
for f in "$HOME/.agent-rules/GLOBAL.md" "$HOME/.agent-rules/TOOL_REGISTRY.md" "$HOME/.agent-rules/KNOWN_ISSUES.md"; do
  [ -f "$f" ] || echo "WARNING: agent rule not reachable: $f"
done

printf 'audit-config-ownership: ok\n'

# 6. Scan Mach-O binaries for hardcoded ~/.local/bin paths
echo "=== scanning binaries for hardcoded paths ==="
for bin in "$HOME"/.local/bin/*; do
  [ -f "$bin" ] && [ -x "$bin" ] || continue
  file "$bin" 2>/dev/null | grep -q "Mach-O" || continue
  deps=$(strings "$bin" 2>/dev/null | grep -oE "$HOME/\\.(local/bin|bin)/[a-zA-Z0-9_-]+" | sort -u)
  [ -z "$deps" ] && continue
  while IFS= read -r dep; do
    [ -e "$dep" ] || echo "MISSING: $bin references $dep"
  done <<< "$deps"
done
