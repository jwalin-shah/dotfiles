# Centralized permissions for all AI tools
# Single source of truth for what each agent can do

{
  # Claude Code — primary agent, high trust
  claude.permissions = {
    env.ENABLE_TOOL_SEARCH = "true";
    permissions = {
      allow = [ "Bash(*)" ];
      deny = [ ];
      ask = [
        "Bash(rm *)"
        "Bash(rm -r *)"
        "Bash(rm -rf *)"
        "Bash(rm -fr *)"
        "Bash(git reset --hard *)"
        "Bash(git clean -fd *)"
        "Bash(git clean -fdx *)"
        "Bash(git checkout -- .)"
        "Bash(git switch --discard-changes *)"
        "Bash(git push --force *)"
        "Bash(git push -f *)"
        "Bash(launchctl *)"
        "Bash(brew *)"
        "Bash(npm *)"
        "Bash(pnpm *)"
        "Bash(sudo *)"
        "Bash(chown *)"
        "Bash(chmod 777 *)"
        "Bash(dd if=*)"
        "Bash(mkfs*)"
      ];
    };
  };

  # Codex (OpenAI) — secondary, same baseline as Claude
  codex.permissions = {
    approvals_reviewer = "user";
    model = "gpt-5.4-mini";
    model_reasoning_effort = "medium";
    sandbox_permissions = "danger-full-access";
    bash = {
      "*" = "allow";
      "rm" = "ask";
      "rm *" = "ask";
      "sudo" = "ask";
      "sudo *" = "ask";
      "security" = "deny";
      "security *" = "deny";
      "export" = "ask";
      "export *" = "ask";
    };
  };

  # OpenCode — TokenRouter variant, moderate trust
  opencode.permissions = {
    edit = "allow";
    read = "allow";
    grep = "allow";
    glob = "allow";
    list = "allow";
    webfetch = "allow";
    websearch = "allow";
    bash = {
      "*" = "allow";
      "rm" = "ask";
      "rm *" = "ask";
      "sudo" = "ask";
      "sudo *" = "ask";
    };
  };

  # Cursor — IDE integration, high trust with explicit denies
  cursor.permissions = {
    allow = [
      "Shell(*)"
      "Shell(bun *)"
      "Shell(ccc *)"
      "Shell(chrome-devtools-axi *)"
      "Shell(cocoindex-code *)"
      "Shell(cognee-cli *)"
      "Shell(ctx7 *)"
      "Shell(du -s *)"
      "Shell(fastedit *)"
      "Shell(gh-axi *)"
      "Shell(githits *)"
      "Shell(gtimeout *)"
      "Shell(inf *)"
      "Shell(jq *)"
      "Shell(lavish-axi *)"
      "Shell(llm-tldr *)"
      "Shell(pioneer *)"
      "Shell(rtk *)"
      "Shell(secret-cache exec *)"
      "Shell(timeout *)"
      "Shell(treehouse *)"
      "Shell(uv *)"
      "Shell(yq *)"
    ];
    deny = [
      "Shell(rm *)"
      "Shell(git reset --hard *)"
      "Shell(git clean -fd *)"
      "Shell(git clean -fdx *)"
      "Shell(git checkout -- .)"
      "Shell(git switch --discard-changes *)"
      "Shell(git push --force *)"
      "Shell(git push -f *)"
      "Shell(sudo *)"
      "Shell(chown *)"
      "Shell(chmod 777 *)"
      "Shell(launchctl *)"
      "Shell(brew uninstall *)"
      "Shell(dd *)"
      "Shell(mkfs*)"
    ];
  };

  # Gemini (Agy) — high permissions, researched and approved
  gemini.permissions = {
    allowNonWorkspaceAccess = true;
    enableTelemetry = false;
    model = "Claude Sonnet 4.6 (Thinking)";
    # Permissions are extensive and include debugging/investigation tools
    # Maintains the same security boundaries as Claude
  };

  # Kilo — experimental, basic permissions
  kilo.permissions = {
    # Minimal until fully evaluated
  };
}
