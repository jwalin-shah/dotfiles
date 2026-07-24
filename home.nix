{ config, pkgs, lib, user, ... }:

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
    tree-sitter
    btop
    dust
    fastfetch
    ripgrep-all
    tree
    zsh-vi-mode
    zsh-history-substring-search
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
    plugins = [
      {
        name = "zsh-vi-mode";
        src = pkgs.zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
      {
        name = "zsh-history-substring-search";
        src = pkgs.zsh-history-substring-search;
        file = "share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh";
      }
    ];
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

      # zoxide (installed via homebrew) — smarter cd
      eval "$(/opt/homebrew/bin/zoxide init zsh)"

      # worktree CLI — shell wrapper for directory navigation
      eval "$(worktree-bin init zsh 2>/dev/null)"

      # fzf key-bindings + completions
      source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
      source /opt/homebrew/opt/fzf/shell/completion.zsh

      # fzf defaults + previews with bat and eza
      export FZF_DEFAULT_OPTS="--layout=reverse --height 40% --border"
      export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always {}'"
      export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -50'"

      # history-substring-search keybindings
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down
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
      codex = "command codex";
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
  home.file.".claude/settings.json".force = true;
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
  home.file.".codex/hooks.json".force = true;
  home.file.".codex/rules/default.rules".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.codex/rules/default.rules";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/GLOBAL.md";

  home.file.".cursor/mcp.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.cursor/mcp.json";
  home.file.".cursor/hooks.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.cursor/hooks.json";
  home.file.".cursor/hooks.json".force = true;
  home.file.".cursor/cli-config.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.cursor/cli-config.json";
  home.file.".cursor/cli-config.json".force = true;
  home.file.".cursor/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/GLOBAL.md";
  home.file.".cursor/AGENTS.md".force = true;
  home.file.".cursor/rules".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.cursor/rules";
  home.file.".cursor/rules".force = true;

  home.file.".gemini/config/mcp_config.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.gemini/config/mcp_config.json";
  home.file.".gemini/config/hooks.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.gemini/config/hooks.json";
  home.file.".gemini/config/hooks.json".force = true;
  home.file.".gemini/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.gemini/settings.json";
  home.file.".gemini/settings.json".force = true;
  home.file.".gemini/antigravity-cli/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.gemini/antigravity-cli/settings.json";
  home.file.".gemini/antigravity-cli/settings.json".force = true;
  home.file.".gemini/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/GLOBAL.md";

  # One line-oriented receipt owns exact npm and uv versions. Activation is a
  # no-op when the live versions match and fails closed on install drift.
  home.activation.agentToolchain = config.lib.dag.entryAfter ["writeBoundary"] ''
    PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:$PATH" \
      "${dotfiles}/bin/reconcile-agent-toolchain.sh" install
  '';

  # Pi owns the interactive cockpit only. Bridge remains the admitted worker
  # and verification engine. Auth stays runtime-owned in ~/.pi/agent/auth.json.
  home.file.".pi/agent/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/settings.json";
  home.file.".pi/agent/settings.json".force = true;

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
  home.file."bin/worktree".source =
    config.lib.file.mkOutOfStoreSymlink "/Users/jwalinshah/.cargo/bin/worktree-bin";

  home.file."bin/ap".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/bin/ap";

  home.file."bin/daemon-wrapper".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/bin/daemon-wrapper";
  home.file."bin/pi-cockpit".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/bin/pi-cockpit";


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
      # Skills live as REAL files under ./.agents/ and are COPIED into the nix
      # store, then linked into each agent config. Do NOT use mkOutOfStoreSymlink
      # here: a live link .agents ↔ ~/.claude/skills forms a closed loop the
      # moment anything (or a prior hand-made symlink) points the wrong way.
      # Rebuild required after editing a skill — that is intentional.
      # Skip symlinks and *.backup so a polluted .agents/ cannot re-enter the loop.
      home.file = let
        entries = builtins.readDir ./.agents;
        isSkill = name: type:
          type != "symlink"
          && !(builtins.match ".*\\.backup" name != null);
        skills = builtins.attrNames (lib.filterAttrs isSkill entries);
        skillDirs = [ ".claude" ".claude-a" ".claude-token" ".codex" ];
        link = dir: name:
          let typ = entries.${name};
          in {
            name = "${dir}/skills/${name}";
            value = {
              source = ./.agents + "/${name}";
              force = true;
              recursive = typ == "directory";
            };
          };
        cursorLink = name:
          let typ = entries.${name};
          in {
            name = ".cursor/skills-cursor/${name}";
            value = {
              source = ./.agents + "/${name}";
              force = true;
              recursive = typ == "directory";
            };
          };
      in builtins.listToAttrs
        ((builtins.concatMap (dir: map (link dir) skills) skillDirs) ++
         (map cursorLink skills));
    })
  ];
}
