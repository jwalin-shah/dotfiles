# Secrets management - environment variables injected at runtime
# NEVER store plaintext secrets in version control
# ALWAYS use infisical or environment variables

{ config, pkgs, ... }:

{
  # All secrets come from environment variables or infisical
  # They are injected at launch time, not stored in git

  secrets = {
    description = "Runtime secrets for all agents";

    # Required environment variables (from .env or infisical)
    required = [
      "TOKENROUTER_API_KEY"    # TokenRouter gateway key
      "ANTHROPIC_API_KEY"      # Direct Anthropic API (for ca launcher)
      "OPENAI_API_KEY"         # OpenAI API (for oo launcher)
      "PIONEER_API_KEY"        # Pioneer gateway key (optional)
    ];

    # How secrets are sourced:
    sources = {
      local = "~/.env.local (not in git, never committed)";
      infisical = "Infisical vault (encrypted at rest)";
      environment = "Shell environment variables";
      keychain = "macOS Keychain (password-encrypted)";
    };

    # Secret injection pattern:
    pattern = {
      launcher = "~/bin/ct";
      calls = "secret-cache exec -- claude-launch run headroom";
      flow = [
        "1. ct launcher runs"
        "2. secret-cache intercepts"
        "3. secret-cache fetches TOKENROUTER_API_KEY from keychain/infisical"
        "4. claude-launch receives injected key"
        "5. Key never exposed to git/logs"
      ];
    };
  };
}
