# Centralized agent configuration for all AI tools
# This module declares:
# - All tool configurations
# - Permissions policies
# - Service dependencies
# - MCP registrations (empty)
# - Launcher setup

{ config, pkgs, ... }:

let
  permissions = import ./permissions.nix;
  services = import ./services.nix;
in

{
  # Export permissions and services for reference
  _permissions = permissions;
  _services = services;

  description = "Unified AI agent configuration for Claude, Codex, OpenCode, Cursor, Gemini";

  # Configuration summary:
  # 1. MCPs are DISABLED across all tools (empty registrations)
  # 2. Each tool has explicit permission policies (defined in permissions.nix)
  # 3. Headroom proxy provides context optimization at port 8788
  # 4. TokenRouter gateway provides unified provider routing at port 18999
  # 5. All launchers route through appropriate proxies
  # 6. All configs are version-controlled in dotfiles via home.nix symlinks

  agents = {
    "claude-code" = {
      description = "Primary agent — high trust baseline";
      launcher = "claude";
      config_file = "~/.claude/settings.json";
      mcp = "disabled";
      permissions = permissions.claude.permissions;
      uses_headroom = false;  # OAuth sends no API key, goes direct to Anthropic
      note = "Direct Anthropic API (OAuth) bypasses Headroom. Use ct for TokenRouter.";
    };

    "claude-tokenrouter" = {
      description = "Claude via TokenRouter (ct launcher) — enables cost optimization";
      launcher = "ct";
      config_file = "~/.claude/settings.json";
      mcp = "disabled";
      permissions = permissions.claude.permissions;
      uses_headroom = true;  # Routes through headroom@8788 → tokenrouter@18999
      note = "Set mode=token in ct launcher to enable compression";
    };

    "codex" = {
      description = "OpenAI Codex — secondary agent with GPT models";
      launcher = "codex";
      config_file = "~/.codex/config.toml";
      mcp = "disabled";
      permissions = permissions.codex.permissions;
      uses_headroom = false;  # Direct OpenAI API
    };

    "opencode" = {
      description = "OpenCode via TokenRouter — alternative to Claude";
      launcher = "ot";
      config_file = "~/.config/opencode/opencode.json";
      mcp = "disabled";
      permissions = permissions.opencode.permissions;
      uses_headroom = true;
      note = "Routes through headroom@8788 → tokenrouter@18999";
    };

    "cursor" = {
      description = "Cursor agent CLI — IDE integration";
      launcher = "cu";
      config_file = "~/.cursor/cli-config.json";
      mcp = "disabled";
      permissions = permissions.cursor.permissions;
      uses_headroom = false;
      sandbox = "disabled";
    };

    "gemini" = {
      description = "Agy (Gemini) — Google's multimodal models";
      launcher = "agy";
      config_file = "~/.gemini/antigravity-cli/settings.json";
      mcp = "disabled";
      permissions = permissions.gemini.permissions;
      uses_headroom = false;  # Direct Google API
    };
  };

  # Service dependency graph
  service_dependencies = {
    "claude-code" = [ ];
    "claude-tokenrouter" = [ "headroom" "tokenrouter" ];
    "codex" = [ ];
    "opencode" = [ "headroom" "tokenrouter" ];
    "cursor" = [ ];
    "gemini" = [ ];
  };

  # MCP configuration summary
  mcp_status = {
    claude_code = "disabled (empty ~/ .config/claude/mcp.json)";
    opencode = "disabled (empty ~/.config/opencode/mcp.json)";
    codex = "disabled (no [mcp_servers] in ~/.codex/config.toml)";
    cursor = "disabled (no mcp config)";
    gemini = "disabled";
    canonical_source = "~/projects/dotfiles via home.nix symlinks";
  };

  # Services that must be running
  required_services = with services; [
    headroom
    tokenrouter
    mlx_chat
    cognee
    cocoindex
  ];

  # How to start everything
  startup_order = [
    "1. nix rebuild (applies all dotfiles symlinks)"
    "2. launchctl start headroom-tokenrouter (or it starts at boot)"
    "3. launchctl start tokenrouter-proxy (or it starts at boot)"
    "4. ct --version (verify headroom is responding)"
    "5. Use ct, cx, ot, ca, agy as needed"
  ];
}
