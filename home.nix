{ config, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in

{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    ripgrep
    fd
    fzf
    jq
    lazygit
    neovim
    nerd-fonts.hack
    bat
    eza
    delta
    btop
    dust
    fastfetch
    ripgrep-all
    tree
  ];

  fonts.fontconfig.enable = true;
  home.sessionVariables = {
    EDITOR = "nvim";
    NLTK_DATA = "${config.home.homeDirectory}/.local/share/nltk_data";
    GOPATH = "${config.home.homeDirectory}/.local/share/go";
    PATH = "${config.home.homeDirectory}/.cargo/bin:${config.home.homeDirectory}/.local/bin:${config.home.homeDirectory}/bin:/opt/homebrew/bin:$PATH";
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = ''
      bindkey '^f' autosuggest-accept
      eval "$(direnv hook zsh)"

      # History
      HISTSIZE=50000
      SAVEHIST=50000
      HISTFILE=~/.zsh_history
      setopt HIST_IGNORE_ALL_DUPS
      setopt HIST_IGNORE_SPACE
      setopt HIST_REDUCE_BLANKS
      setopt INC_APPEND_HISTORY
      setopt SHARE_HISTORY

      # Completion
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      zstyle ':completion:*' completer _expand _complete _ignored _approximate
      zstyle ':completion:*' max-errors 2

      # Better globbing
      setopt EXTENDED_GLOB
      setopt NO_CASE_GLOB

      # Nice defaults
      setopt AUTO_CD
      setopt INTERACTIVE_COMMENTS
      unsetopt BEEP

      # Include dotfiles in glob patterns
      setopt GLOB_DOTS
    '';
    shellAliases = {
      ".." = "cd ..";
      "..." = "cd ../..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      rb = "cd ~/projects/dotfiles && ./rebuild.sh";
      ll = "eza -l";
      la = "eza -la";
      lt = "eza --tree";
      cat = "bat";
      grep = "rg";
      find = "fd";
      cx = "command cx";
      codex = "cx";
      cur = "cursor";
      gha = "/opt/homebrew/bin/gh-axi";
      cda = "/opt/homebrew/bin/chrome-devtools-axi";
      lva = "/opt/homebrew/bin/lavish-axi";
      g = "git";
      gs = "git status";
      rm = "trash";
      gc = "git commit";
      gcm = "git commit -m";
      gp = "git push";
      gl = "git pull";
      gd = "git diff";
      glog = "git log --oneline --graph --decorate";
      reload = "exec zsh";
      path = "echo $PATH | tr ':' '\n'";
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

  # Edit-in-place symlinks -- real files live in the dotfiles repo
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";

  # Global git hooks dir -- applies to every repo, every tool (not Claude-Code-
  # specific). Currently enforces: never commit directly to inbox's core
  # server code from its primary checkout, only from a worktree. See
  # home/.config/git/hooks/pre-commit for the dispatch logic.
  home.file.".config/git/hooks".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/git/hooks";
  # Not using programs.git here -- ~/.gitconfig is hand-authored, not nix-
  # managed, and enabling that module would fight it. Just set the one line
  # idempotently instead.
  home.activation.gitHooksPath = config.lib.dag.entryAfter ["writeBoundary"] ''
    /usr/bin/git config --global core.hooksPath "${config.home.homeDirectory}/.config/git/hooks" || true
  '';

  # Claude config dirs (3) -- same settings, symlinked
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";
  home.file.".claude/settings.local.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.local.json";
  home.file.".claude/settings.local.json".force = true;
  home.file.".claude/mcp.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/mcp.json";
  home.file.".claude/mcp.json".force = true;
  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/GLOBAL.md";

  home.file.".claude-a/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";
  home.file.".claude-a/settings.json".force = true;
  home.file.".claude-a/settings.local.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.local.json";
  home.file.".claude-a/settings.local.json".force = true;
  home.file.".claude-a/mcp.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude-a/mcp.json";
  home.file.".claude-a/mcp.json".force = true;
  home.file.".claude-a/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/GLOBAL.md";

  home.file.".claude-token/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";
  home.file.".claude-token/settings.json".force = true;
  home.file.".claude-token/settings.local.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.local.json";
  home.file.".claude-token/settings.local.json".force = true;
  home.file.".claude-token/mcp.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude-token/mcp.json";
  home.file.".claude-token/mcp.json".force = true;
  home.file.".claude-token/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/GLOBAL.md";
  home.file.".claude-token/CLAUDE.md".force = true;

  # Other agent configs

  # Machine constitution — the single ~/CLAUDE.md that every doc references
  home.file."CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/GLOBAL.md";

  home.file.".codex/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.codex/config.toml";
  home.file.".codex/hooks.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.codex/hooks.json";
  home.file.".codex/rules/default.rules".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.codex/rules/default.rules";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/GLOBAL.md";

  home.file.".cursor/mcp.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.cursor/mcp.json";
  home.file.".cursor/hooks.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.cursor/hooks.json";
  home.file.".cursor/cli-config.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.cursor/cli-config.json";
  home.file.".cursor/cli-config.json".force = true;
  home.file.".cursor/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/GLOBAL.md";

  home.file.".gemini/config/mcp_config.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.gemini/config/mcp_config.json";
  home.file.".gemini/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.gemini/settings.json";
  home.file.".gemini/antigravity-cli/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.gemini/antigravity-cli/settings.json";
  home.file.".gemini/antigravity-cli/settings.json".force = true;
  home.file.".gemini/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/GLOBAL.md";

  home.activation.npmGlobalTools = config.lib.dag.entryAfter ["writeBoundary"] ''
    (
      export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:$PATH"
      # Launcher dependencies — wrappers in ~/bin/ exec these directly
      /opt/homebrew/bin/npm install -g @anthropic-ai/claude-code @openai/codex command-code || true
      # Agent toolchain — used across all projects by agents and Bridge context assembly
      /opt/homebrew/bin/npm install -g gh-axi githits chrome-devtools-axi lavish-axi tasks-axi @inference/cli gnhf || true
      # Linting, formatting, and type-checking — used by Bridge verification gates and agent toolchains
      /opt/homebrew/bin/npm install -g eslint prettier pyright typescript pnpm || true
    )
  '';

  # uv-managed tools: installs are idempotent (uv tool install is a no-op when
  # already at the right version). These provide binaries that LaunchAgents and
  # bridge's context assembly depend on. Without this, they're lost on fresh machine.
  home.activation.uvTools = config.lib.dag.entryAfter ["writeBoundary"] ''
    (
      export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:$PATH"
      uv tool install mlx-lm || true
      uv tool install cocoindex || true
      uv tool install cocoindex-code || true

      uv tool install "llm-tldr" || true
      uv tool install z3-solver || true
    )
  '';

  home.file.".config/claude/mcp.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/claude/mcp.json";

  # Models config — single source of truth for LLM model selection
  home.file.".config/orbit/models.env".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/orbit/models.env";

  # ~/bin launcher wrappers — ca and ct only.
  # All other agents (codex, cursor-agent, agy, cmd) are called directly.
  home.file."bin/ct".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/bin/ct-wrapper";
  home.file."bin/ca".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/bin/ca-wrapper";

  # Personal tool wrappers (only useful ones — dead wrappers removed)
  home.file."bin/ap".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/bin/ap";

  home.file."bin/daemon-wrapper".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/bin/daemon-wrapper";


  # Bridge worker adapters - source lives in ~/projects/bridge/scripts/
  # (versioned alongside the Go spawn code that calls them)
  home.file."bin/bridge-ca".source =
    config.lib.file.mkOutOfStoreSymlink "/Users/jwalinshah/projects/bridge/scripts/bridge-ca";
  home.file."bin/bridge-ct".source =
    config.lib.file.mkOutOfStoreSymlink "/Users/jwalinshah/projects/bridge/scripts/bridge-ct";
  home.file."bin/bridge-cua".source =
    config.lib.file.mkOutOfStoreSymlink "/Users/jwalinshah/projects/bridge/scripts/bridge-cua";
  home.file."bin/bridge-agy".source =
    config.lib.file.mkOutOfStoreSymlink "/Users/jwalinshah/projects/bridge/scripts/bridge-agy";

  home.file."bin/bridge-cx".source =
    config.lib.file.mkOutOfStoreSymlink "/Users/jwalinshah/projects/bridge/scripts/bridge-cx";
  home.file."bin/bridge-cc".source =
    config.lib.file.mkOutOfStoreSymlink "/Users/jwalinshah/projects/bridge/scripts/bridge-cc";

  # Mintmux session backends - tmux only (orca/zellij/herdr not installed)
  # source lives in ~/projects/bridge/scripts/ alongside the adapter scripts
  home.file."bin/backends/tmux.sh".source =
    config.lib.file.mkOutOfStoreSymlink "/Users/jwalinshah/projects/bridge/scripts/tmux-backend.sh";

  # Global linter/formatter configs
  home.file.".config/lint/.prettierrc".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/lint/.prettierrc";
  home.file.".config/lint/.eslintrc.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/lint/.eslintrc.json";
  home.file.".config/lint/pyproject.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/lint/pyproject.toml";
  home.file.".config/lint/.golangci.yml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/lint/.golangci.yml";
  home.file.".config/lint/rustfmt.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/lint/rustfmt.toml";
  home.file.".config/lint/.clang-format".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/lint/.clang-format";
  home.file.".config/lint/.shellcheckrc".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/lint/.shellcheckrc";

  # Ghostty terminal config
  home.file.".config/ghostty/config".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/ghostty/config";

  # Window manager + keyboard + launchers
  home.file.".aerospace.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/aerospace/aerospace.toml";
  home.file.".config/karabiner/karabiner.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/karabiner/karabiner.json";
  imports = [
    ({ config, ... }: {
      # Skills declared once in ./.agents/ and projected into Claude configs.
      # force = true because these paths held hand-made symlinks predating nix.
      home.file = let
        skills = builtins.attrNames (builtins.readDir ./.agents);
        skillDirs = [ ".claude" ".claude-a" ".claude-token" ];
        link = dir: name: {
          name = "${dir}/skills/${name}";
          value = {
            source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/.agents/${name}";
            force = true;
          };
        };
      in builtins.listToAttrs
        (builtins.concatMap (dir: map (link dir) skills) skillDirs);
    })
  ];
}
