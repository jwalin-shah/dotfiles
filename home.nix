{ config, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in

{
  imports = [ ./captain/user.nix ];

  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";
  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep   # fast search
    fd        # fast find
    fzf       # fuzzy finder
    jq        # json on the command line
    lazygit
    neovim
    # the font everything renders in
    nerd-fonts.hack
  ];
  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "nvim";

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid
    initContent = ''
      bindkey '^f' autosuggest-accept
    '';
    shellAliases = {
      ".." = "cd ..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      rb = "cd ~/projects/dotfiles && ./rebuild.sh";
      cc = "claude --dangerously-skip-permissions";
      co = "codex --full-auto";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  # Edit-in-place: the real file stays in my repo, ~/.config just points at it.
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".config/herdr".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";
  home.file."bin/ct".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/captain/bin/ct";
  home.file."bin/audit-config-ownership.sh".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/bin/audit-config-ownership.sh";
  home.file."bin/audit-doc-freshness.sh".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/bin/audit-doc-freshness.sh";
  home.file."bin/verify-core-launchers.sh".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/bin/verify-core-launchers.sh";
  home.file."bin/openwiki".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/captain/bin/openwiki";
  home.file."bin/routing-proxy".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/captain/bin/routing-proxy";
  home.file."bin/tokenrouter-proxy".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/captain/bin/tokenrouter-proxy";
  home.file."bin/claude-launch".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/captain/bin/claude-launch";
  home.file."bin/claude-endpoints.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/captain/bin/claude-endpoints.toml";
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";
  home.file.".codex/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.codex/config.toml";
  home.file.".cursor/cli-config.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.cursor/cli-config.json";
  home.file.".codex/hooks.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.codex/hooks.json";
  home.file.".codex/rules/default.rules".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.codex/rules/default.rules";
  home.file.".cursor/hooks.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.cursor/hooks.json";
  home.file.".gemini/antigravity-cli/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.gemini/antigravity-cli/settings.json";
  home.file.".gemini/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.gemini/settings.json";
  home.file.".gemini/config/hooks.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.gemini/config/hooks.json";
  home.file.".config/kilo/kilo.jsonc".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/kilo/kilo.jsonc";
  home.file.".config/claude/mcp.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/claude/mcp.json";
  home.file.".config/opencode/mcp.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/opencode/mcp.json";
  home.file.".config/opencode/opencode.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/opencode/opencode.json";

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
