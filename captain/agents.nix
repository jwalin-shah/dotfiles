# Centralized agent configuration — SINGLE SOURCE OF TRUTH
# All tool configs (MCPs, hooks, permissions) defined here.
# Generated files are created from this schema, not stored separately.

{ config, pkgs, lib, ... }:

let
  permissions = import ./permissions.nix;
  services = import ./services.nix;

  # MCP server definitions — shared across tools
  mcpServers = {
    githits = { command = "githits"; args = ["mcp" "start"]; };
    tldr = { command = "tldr-mcp"; args = ["--project" "/Users/jwalinshah/projects"]; };
    cocoindex = { command = "ccc"; args = ["mcp"]; };
    cognee = { command = "/Users/jwalinshah/bin/cognee"; args = ["mcp"]; };
  };

  # Hook definitions — shared across tools
  hooks = {
    empty = { };
    gemini_workflow_ladder = {
      "workflow-ladder-status" = {
        PreInvocation = [{
          type = "command";
          command = "/Users/jwalinshah/.agents/skills/workflow-ladder/scripts/ladder-status.sh";
          timeout = 10;
        }];
      };
      "workflow-ladder-gate" = {
        PreToolUse = [{
          matcher = "write_to_file|replace_file_content|multi_replace_file_content|run_command";
          hooks = [{
            type = "command";
            command = "/Users/jwalinshah/.agents/skills/workflow-ladder/scripts/check-ladder.sh";
            timeout = 10;
          }];
        }];
      };
    };
  };

in

{
  _permissions = permissions;
  _services = services;

  description = "Unified AI agent configuration — MCPs, hooks, and permissions from single source";

  # AGENT SCHEMA: Single source of truth
  agents = {
    "claude-code" = {
      description = "Primary agent — high trust baseline";
      launcher = "claude";
      config_file = "~/.claude/settings.json";
      uses_headroom = false;
      mcp_servers = { };  # Disabled
      hooks = hooks.empty;
      permissions = permissions.claude.permissions;
    };

    "claude-tokenrouter" = {
      description = "Claude via TokenRouter (ct launcher)";
      launcher = "ct";
      config_file = "~/.claude/settings.json";
      uses_headroom = true;
      mcp_servers = { };  # Disabled
      hooks = hooks.empty;
      permissions = permissions.claude.permissions;
    };

    "codex" = {
      description = "OpenAI Codex — GPT models";
      launcher = "codex";
      config_file = "~/.codex/config.toml";
      uses_headroom = false;
      mcp_servers = { };  # Disabled
      hooks = hooks.empty;
      permissions = permissions.codex.permissions;
    };

    "opencode" = {
      description = "OpenCode via TokenRouter";
      launcher = "ot";
      config_file = "~/.config/opencode/opencode.json";
      uses_headroom = true;
      mcp_servers = { };  # Disabled
      hooks = hooks.empty;
      permissions = permissions.opencode.permissions;
    };

    "cursor" = {
      description = "Cursor agent CLI — IDE integration";
      launcher = "cu";
      config_file = "~/.cursor/cli-config.json";
      uses_headroom = false;
      mcp_servers = { };  # Disabled (was wrongly enabled, now fixed)
      hooks = hooks.empty;
      permissions = permissions.cursor.permissions;
    };

    "gemini" = {
      description = "Agy (Gemini) — Google's models";
      launcher = "agy";
      config_file = "~/.gemini/antigravity-cli/settings.json";
      uses_headroom = false;
      mcp_servers = { };  # Disabled
      hooks = hooks.gemini_workflow_ladder;  # Workflow ladder hooks enabled
      permissions = permissions.gemini.permissions;
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

  # Validation summary
  validation = {
    description = "All MCPs disabled across all tools (consistency enforced)";
    hooks_status = {
      "claude-code" = "empty";
      "claude-tokenrouter" = "empty";
      "codex" = "empty";
      "opencode" = "empty";
      "cursor" = "empty";
      "gemini" = "workflow-ladder only";
    };
    canonical_source = "captain/agents.nix (single source of truth)";
  };

  required_services = with services; [
    headroom
    tokenrouter
    mlx_chat
    cognee
    cocoindex
  ];

  startup_order = [
    "1. nix rebuild (generates + validates all configs from agents.nix)"
    "2. launchctl services start automatically"
    "3. ct --version (verify system ready)"
  ];
}
