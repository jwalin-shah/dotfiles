{ user, ... }:

{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin";

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };
  system.stateVersion = 6;

  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      _HIHideMenuBar = true;
      AppleShowAllExtensions = true;
      ApplePressAndHoldEnabled = false;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSScrollAnimationEnabled = false;
    };
    dock = {
      autohide = true;
      show-recents = false;
      mru-spaces = false;
      minimize-to-application = true;
      tilesize = 36;
    };
    finder = {
      FXPreferredViewStyle = "Nlsv";
      CreateDesktop = false;
      ShowPathbar = true;
      ShowStatusBar = true;
      AppleShowAllFiles = true;
      FXEnableExtensionChangeWarning = false;
    };
    trackpad.Clicking = true;
    trackpad.TrackpadRightClick = true;
    screensaver = {
      askForPassword = true;
      askForPasswordDelay = 5;
    };
    screencapture = {
      location = "~/Desktop/screenshots";
      type = "png";
      disable-shadow = true;
    };
  };

  # Homebrew via nix-homebrew
  nix-homebrew = {
    enable = true;
    autoMigrate = true;
    inherit user;
  };

  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.extraFlags = [ "--force" ];

    brews = [
      "bat"
      "borders"
      "btop"
      "clang-format"
      "cmake"
      "coreutils"
      "direnv"
      "dust"
      "eza"
      "fd"
      "ffmpeg"
      "fzf"
      "gh"
      "go"
      "gofumpt"
      "golangci-lint"
      "herdr"
      "infisical"
      "jq"
      "llama.cpp"
      "ncdu"
      "node"
      "opencode"
      "ruff"
      "python@3.14"
      "rustup"
      "shellcheck"
      "swift-format"
      "tailscale"
      "tmux"
      "tree"
      "tuxedo"
      "typst"
      "uv"
      "wget"
      "yq"
      "zig"
      "zoxide"
    ];

    casks = [
      "aerospace"
      "brave-browser"
      "cursor"
      "ghostty"
      "karabiner-elements"
      "lulu"
      "monitorcontrol"
      "raycast"
    ];
  };

  # LaunchAgents -- background services
  launchd.user.agents = let
    home = "/Users/${user}";
    localBin = "${home}/.local/bin";
    uvBin = "${home}/.local/share/uv/tools";
    brewBin = "/opt/homebrew/bin";
    defaultPATH = "${localBin}:${brewBin}:/usr/local/bin:/usr/bin:/bin";
  in {

    # -- Local AI Stack --
    # mlx-chat: Gemma 4 4B chat server on :8080
    "com.jwalinshah.mlx-chat-server" = {
      serviceConfig = {
        ProgramArguments = [
          "/bin/bash" "-c"
          "source ${home}/.config/jw/models.env && exec ${uvBin}/mlx-lm/bin/mlx_lm.server --model \"$JW_CHAT_MODEL_REPO\" --host 127.0.0.1 --port 8080 --trust-remote-code"
        ];
        KeepAlive = true;
        RunAtLoad = true;
        ThrottleInterval = 10;
        EnvironmentVariables = {
          HOME = home;
          PATH = defaultPATH;
        };
        StandardOutPath = "${home}/.local/share/jw/mlx-chat.log";
        StandardErrorPath = "${home}/.local/share/jw/mlx-chat.log";
      };
    };

    # llama-embed: Qwen3-Embedding 0.6B on :8081 (1024-dim)
    "com.jwalinshah.llama-embed-server" = {
      serviceConfig = {
        ProgramArguments = [
          "${brewBin}/llama-server"
          "-m" "${home}/.cache/huggingface/hub/models--Qwen--Qwen3-Embedding-0.6B-GGUF/snapshots/main/Qwen3-Embedding-0.6B-Q8_0.gguf"
          "--embedding" "--host" "127.0.0.1" "--port" "8081"
          "-c" "512" "-np" "1" "-b" "512" "-ub" "512" "-ngl" "99"
        ];
        KeepAlive = true;
        RunAtLoad = true;
        ThrottleInterval = 10;
        EnvironmentVariables = {
          PATH = "${brewBin}:/usr/local/bin:/usr/bin:/bin";
        };
        StandardOutPath = "${home}/.local/share/jw/llama-embed.log";
        StandardErrorPath = "${home}/.local/share/jw/llama-embed.log";
      };
    };

    # coderank-embed: CodeRankEmbed on :8082 (768-dim, 2048 ctx trained)
    "com.jwalinshah.coderank-embed-server" = {
      serviceConfig = {
        ProgramArguments = [
          "${brewBin}/llama-server"
          "-m" "${home}/.cache/huggingface/hub/models--handwoven8588--CodeRankEmbed-GGUF/snapshots/14be4104a35a5f4e32e6e225955ccf271fb5b956/CodeRankEmbed-Q8_0.gguf"
          "--embedding" "--host" "127.0.0.1" "--port" "8082"
          "-c" "2048" "-np" "1" "-b" "2048" "-ub" "2048" "-ngl" "99"
        ];
        KeepAlive = true;
        RunAtLoad = true;
        ThrottleInterval = 10;
        EnvironmentVariables = {
          PATH = "${brewBin}:/usr/local/bin:/usr/bin:/bin";
        };
        StandardOutPath = "${home}/.local/share/jw/coderank-embed.log";
        StandardErrorPath = "${home}/.local/share/jw/coderank-embed.log";
      };
    };

    # cognee: knowledge graph API on :8000
    "com.jwalinshah.cognee-api" = {
      serviceConfig = {
        ProgramArguments = [
          "/bin/bash" "-c"
          "source ${home}/.config/jw/models.env && exec ${uvBin}/cognee/bin/cognee-cli serve --host 127.0.0.1 --port 8000"
        ];
        KeepAlive = true;
        RunAtLoad = true;
        ThrottleInterval = 10;
        EnvironmentVariables = {
          HOME = home;
          PATH = defaultPATH;
          CACHING = "true";
          COGNEE_SKIP_CONNECTION_TEST = "true";
        };
        StandardOutPath = "${home}/.local/share/jw/cognee-api.log";
        StandardErrorPath = "${home}/.local/share/jw/cognee-api.log";
      };
    };

    # cocoindex: incremental code index daemon (watch + auto-reindex)
    "com.jwalinshah.cocoindex-daemon" = {
      serviceConfig = {
        ProgramArguments = [ "${uvBin}/cocoindex-code/bin/ccc" "run-daemon" ];
        KeepAlive = true;
        RunAtLoad = true;
        ThrottleInterval = 10;
        WorkingDirectory = home;
        EnvironmentVariables = {
          HOME = home;
          PATH = defaultPATH;
        };
        StandardOutPath = "${home}/.local/share/cocoindex/daemon-stdout.log";
        StandardErrorPath = "${home}/.local/share/cocoindex/daemon-stderr.log";
      };
    };

    # -- Session Infrastructure --
    # mintmux: PTY multiplexer
    "com.jwalinshah.mintmux" = {
      serviceConfig = {
        ProgramArguments = [ "${localBin}/mintmux" ];
        KeepAlive = true;
        RunAtLoad = true;
        EnvironmentVariables = {
          PATH = defaultPATH;
        };
        StandardOutPath = "${home}/.cache/mintmux/launchd-stdout.log";
        StandardErrorPath = "${home}/.cache/mintmux/launchd-stderr.log";
        ThrottleInterval = 5;
        ExitTimeOut = 10;
      };
    };

    # herdr: agent-native terminal multiplexer (session provider)
    "com.jwalinshah.herdr" = {
      serviceConfig = {
        ProgramArguments = [ "${brewBin}/herdr" "server" ];
        KeepAlive = true;
        RunAtLoad = true;
        EnvironmentVariables = {
          HOME = home;
          PATH = defaultPATH;
        };
        StandardOutPath = "${home}/.local/share/jw/herdr.log";
        StandardErrorPath = "${home}/.local/share/jw/herdr.log";
        ThrottleInterval = 5;
        ExitTimeOut = 10;
      };
    };

    # -- Monitoring & Health --
    # auto-save: commit + push uncommitted changes every 5 min (never lose work)
    "com.jwalinshah.auto-save" = {
      serviceConfig = {
        ProgramArguments = [ "/bin/bash" "${home}/bin/auto-save.sh" ];
        RunAtLoad = true;
        StartInterval = 300;
        EnvironmentVariables = {
          HOME = home;
          PATH = defaultPATH;
        };
        StandardOutPath = "${home}/.local/share/jw/auto-save.log";
        StandardErrorPath = "${home}/.local/share/jw/auto-save.log";
      };
    };

    "com.jw.heal" = {
      serviceConfig = {
        ProgramArguments = [ "${localBin}/jw-heal" ];
        RunAtLoad = true;
        StartInterval = 300;
        StandardOutPath = "${home}/.local/share/jw/heal-stdout.log";
        StandardErrorPath = "${home}/.local/share/jw/heal-stderr.log";
      };
    };

    # m5logd: M5 hardware logging daemon
    "com.jwalinshah.m5logd" = {
      serviceConfig = {
        ProgramArguments = [ "${localBin}/m5logd" ];
        KeepAlive = true;
        RunAtLoad = true;
        EnvironmentVariables = {
          HOME = home;
          PATH = "${localBin}:/usr/local/bin:/usr/bin:/bin";
        };
        StandardOutPath = "${home}/Library/Logs/m5logd-stdout.log";
        StandardErrorPath = "${home}/Library/Logs/m5logd-stderr.log";
      };
    };

    # jw-cred-canary: credential expiry checker, 9am + 9pm
    "com.jwalinshah.jw-cred-canary" = {
      serviceConfig = {
        ProgramArguments = [ "/bin/bash" "${home}/bin/jw-cred-canary.sh" ];
        StartCalendarInterval = [
          { Hour = 9; Minute = 0; }
          { Hour = 21; Minute = 0; }
        ];
        StandardOutPath = "${home}/.local/share/jw/cred-canary.log";
        StandardErrorPath = "${home}/.local/share/jw/cred-canary.log";
      };
    };

    # voice-engine: macOS dictation menubar app
    "com.jwalinshah.voice-engine" = {
      serviceConfig = {
        ProgramArguments = [ "${localBin}/voice-engine" ];
        KeepAlive = true;
        RunAtLoad = true;
        ThrottleInterval = 10;
        EnvironmentVariables = {
          HOME = home;
          PATH = defaultPATH;
        };
        StandardOutPath = "/tmp/voice-engine.log";
        StandardErrorPath = "/tmp/voice-engine.log";
      };
    };
  };

  # -- Root Daemons --
  launchd.daemons."com.jwalinshah.m5fand" = {
    serviceConfig = {
      ProgramArguments = [ "/Users/${user}/.local/bin/m5fand" ];
      UserName = "root";
      KeepAlive = true;
      RunAtLoad = true;
      EnvironmentVariables = {
        HOME = "/Users/${user}";
        PATH = "/Users/${user}/.local/bin:/usr/local/bin:/usr/bin:/bin";
      };
      StandardOutPath = "/Users/${user}/Library/Logs/m5fand.log";
      StandardErrorPath = "/Users/${user}/Library/Logs/m5fand.log";
    };
  };
}
