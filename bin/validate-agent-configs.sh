#!/bin/bash
# Validate that all deployed agent configs match captain/agents.nix
# Run this before rebuild to ensure no contradictions exist
set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENTS_NIX="$DOTFILES_ROOT/captain/agents.nix"

echo "=== AGENT CONFIG VALIDATION ==="
echo "Checking that deployed configs match agents.nix (single source of truth)..."
echo ""

ERRORS=0

# Check Cursor MCPs (should be disabled)
echo "Cursor MCPs:"
if jq -e '.mcpServers | length > 0' "$DOTFILES_ROOT/home/.cursor/mcp.json" >/dev/null 2>&1; then
  echo "  ✗ FAIL: Cursor has MCPs enabled (agents.nix says disabled)"
  ERRORS=$((ERRORS + 1))
else
  echo "  ✓ OK: Cursor MCPs disabled"
fi

# Check Claude MCPs (should be disabled)
echo "Claude Code MCPs:"
if jq -e '.mcpServers | length > 0' "$DOTFILES_ROOT/home/.claude/mcp.json" >/dev/null 2>&1 || \
   jq -e '.mcpServers | length > 0' "$DOTFILES_ROOT/home/.claude-a/mcp.json" >/dev/null 2>&1 || \
   jq -e '.mcpServers | length > 0' "$DOTFILES_ROOT/home/.claude-token/mcp.json" >/dev/null 2>&1 || \
   jq -e '.mcpServers | length > 0' "$DOTFILES_ROOT/home/.config/claude/mcp.json" >/dev/null 2>&1; then
  echo "  ✗ FAIL: Claude has MCPs enabled (agents.nix says disabled)"
  ERRORS=$((ERRORS + 1))
else
  echo "  ✓ OK: Claude MCPs disabled"
fi

# Check OpenCode MCPs (should be disabled)
echo "OpenCode MCPs:"
if jq -e '.mcpServers | length > 0' "$DOTFILES_ROOT/home/.config/opencode/mcp.json" >/dev/null 2>&1; then
  echo "  ✗ FAIL: OpenCode has MCPs enabled (agents.nix says disabled)"
  ERRORS=$((ERRORS + 1))
else
  echo "  ✓ OK: OpenCode MCPs disabled"
fi

# Check Gemini hooks (should have workflow-ladder)
echo "Gemini Hooks:"
if jq -e '.["workflow-ladder-status"] and .["workflow-ladder-gate"]' "$DOTFILES_ROOT/home/.gemini/config/hooks.json" >/dev/null 2>&1; then
  echo "  ✓ OK: Gemini has workflow-ladder hooks"
else
  echo "  ✗ FAIL: Gemini missing workflow-ladder hooks (agents.nix declares them)"
  ERRORS=$((ERRORS + 1))
fi

# Check Cursor hooks (should be empty)
echo "Cursor Hooks:"
CURSOR_HOOKS=$(jq '.hooks' "$DOTFILES_ROOT/home/.cursor/hooks.json" 2>/dev/null || echo "{}")
if [ "$CURSOR_HOOKS" = "{}" ]; then
  echo "  ✓ OK: Cursor hooks empty"
else
  echo "  ✗ FAIL: Cursor has hooks (agents.nix says empty)"
  ERRORS=$((ERRORS + 1))
fi

# Check Codex hooks (should be empty)
echo "Codex Hooks:"
CODEX_HOOKS=$(jq '.hooks' "$DOTFILES_ROOT/home/.codex/hooks.json" 2>/dev/null || echo "{}")
if [ "$CODEX_HOOKS" = "{}" ]; then
  echo "  ✓ OK: Codex hooks empty"
else
  echo "  ✗ FAIL: Codex has hooks (agents.nix says empty)"
  ERRORS=$((ERRORS + 1))
fi

echo ""
if [ $ERRORS -eq 0 ]; then
  echo "✓ All configs match agents.nix — system is consistent"
  exit 0
else
  echo "✗ $ERRORS validation error(s) found — configs contradict agents.nix"
  echo ""
  echo "Fix by running: nix rebuild switch"
  exit 1
fi
