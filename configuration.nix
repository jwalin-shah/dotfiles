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

      # Premium QoL
      AppleShowScrollBars = "Always";              # Never wonder where you are
      NSWindowResizeTime = 0.001;                  # Instant window resize
      NSAutomaticWindowAnimationsEnabled = false;   # No bounce/glide
      NSTableViewDefaultSizeMode = 1;              # Denser table rows
      AppleWindowTabbingMode = "always";            # Apps prefer tabs over windows
      NSDisableAutomaticTermination = true;         # Don't kill background apps
      NSUseAnimatedFocusRing = false;               # No glow delay
      AppleSpacesSwitchOnActivate = true;           # Switch spaces when switching apps
      NSAutomaticSpellingCorrectionEnabled = false; # No auto-fix
      NSAutomaticInlinePredictionEnabled = false;   # No inline predictions
      NSDocumentSaveNewDocumentsToCloud = false;    # Save local by default
      NSNavPanelExpandedStateForSaveMode = true;    # Expanded save dialog
      NSNavPanelExpandedStateForSaveMode2 = true;   # Same for v2
      PMPrintingExpandedStateForPrint = true;       # Expanded print dialog
      PMPrintingExpandedStateForPrint2 = true;      # Same for v2
      AppleFontSmoothing = 1;                       # Medium font smoothing
      AppleICUForce24HourTime = true;               # 24-hour clock
      AppleMetricUnits = true;                      # Metric system
      AppleEnableSwipeNavigateWithScrolls = false;  # Kill accidental back-swipe in browsers
      AppleKeyboardUIMode = 3;                      # Tab through ALL dialog controls
    };
    dock = {
      autohide = true;
      show-recents = false;
      mru-spaces = false;
      minimize-to-application = true;
      tilesize = 36;

      # Premium QoL - instant dock
      autohide-delay = 0.0;                        # Dock pops immediately on hover
      autohide-time-modifier = 0.0;                # No slide animation, instant show/hide
      expose-animation-duration = 0.1;             # Mission Control snaps
      expose-group-apps = true;                     # Group windows by app in Exposé
      mineffect = "scale";                          # "scale" is instant, "genie" is slow
      orientation = "bottom";                       # Keep at bottom
      showhidden = true;                            # Translucent icons for hidden apps
      launchanim = false;                           # No bounce when opening apps
      enable-spring-load-actions-on-all-items = true;  # Spring load from dock
      static-only = false;                          # Show running + recent
      magnification = false;                        # No magnification on hover
    };
    finder = {
      FXPreferredViewStyle = "Nlsv";
      CreateDesktop = false;
      ShowPathbar = true;
      ShowStatusBar = true;
      AppleShowAllFiles = true;
      FXEnableExtensionChangeWarning = false;

      # Premium QoL
      _FXShowPosixPathInTitle = true;              # Show real UNIX path in title bar
      _FXSortFoldersFirst = true;                   # Folders before files
      _FXSortFoldersFirstOnDesktop = true;          # Folders before files on desktop too
      FXDefaultSearchScope = "SCcf";                # Search current folder, not whole Mac
      FXRemoveOldTrashItems = true;                 # Auto-empty trash after 30 days
      QuitMenuItem = true;                          # Cmd-Q quits Finder
      ShowExternalHardDrivesOnDesktop = false;
      ShowHardDrivesOnDesktop = false;
      ShowMountedServersOnDesktop = false;
      ShowRemovableMediaOnDesktop = true;           # USB drives show on desktop
      NewWindowTarget = "Other";                    # Open new windows to custom path
      NewWindowTargetPath = "/Users/${user}";        # Home folder
    };
    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;

      # Premium QoL
      TrackpadThreeFingerDrag = true;               # Three-finger drag (huge QoL)
      Dragging = true;                              # Enable drag
      ActuationStrength = 0;                        # Silent clicking
      FirstClickThreshold = 0;                       # Light click
      SecondClickThreshold = 0;                      # Light second click
      TrackpadMomentumScroll = true;                 # Momentum scrolling
    };
    WindowManager = {
      GloballyEnabled = false;                      # No Stage Manager
      EnableTilingByEdgeDrag = false;               # Kill macOS native tiling (Aerospace handles it)
      EnableTopTilingByEdgeDrag = false;            # Same
      EnableTilingOptionAccelerator = false;        # Same
      EnableStandardClickToShowDesktop = true;       # Click wallpaper to show desktop
      AutoHide = false;                             # Don't auto-hide stage strip
      AppWindowGroupingBehavior = true;              # All windows at once
      StandardHideDesktopIcons = false;              # Don't hide desktop icons
    };
    universalaccess = {
      reduceMotion = true;                          # No macOS motion sickness
      reduceTransparency = false;                    # Keep transparency
    };
    controlcenter = {
      BatteryShowPercentage = true;                 # Show battery %
      Sound = true;                                 # Show sound in menu bar
      Bluetooth = false;                             # Hide Bluetooth (never change it)
      Display = false;                               # Hide display brightness
      AirDrop = false;                               # Hide AirDrop (never use it)
      FocusModes = false;                            # Hide focus mode
    };
    menuExtraClock = {
      Show24Hour = true;
      ShowDayOfMonth = true;
      ShowDayOfWeek = true;
      ShowDate = 2;                                 # Show full date
      ShowAMPM = false;
      IsAnalog = false;
    };
    screencapture = {
      location = "~/Desktop/screenshots";
      type = "png";
      disable-shadow = true;
      include-date = true;                          # Include date in filename
      show-thumbnail = false;                       # No floating thumbnail
    };
    screensaver = {
      askForPassword = true;
      askForPasswordDelay = 5;
    };
    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;  # Manual updates only
    spaces.spans-displays = false;                  # Each display has its own Spaces
    loginwindow = {
      GuestEnabled = false;                         # No guest account
      SHOWFULLNAME = true;                          # Show name + password field
    };
    hitoolbox.AppleFnUsageType = "Do Nothing";      # Fn key does nothing (reclaim it)
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
    # Do NOT auto-update Homebrew taps on every rebuild - that is the slow
    # "Auto-updating Homebrew... Updated N taps" phase and the hint/untap noise.
    # brew still installs/upgrades the listed formulae; it just skips refreshing
    # the tap index each switch. Run `brew update` by hand when you want it.
    onActivation.autoUpdate = false;
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

    # inbox: Personal data API server (iMessage, Gmail, Calendar, Tasks, ...)
    # Loads env from ~/.config/inbox/env.
    # All traffic stays on 127.0.0.1:9849 - completely local and private.
    "com.jwalinshah.inbox-server" = {
      serviceConfig = {
        ProgramArguments = [
          "/bin/bash" "-c"
          "source ${home}/.config/inbox/env && exec ${brewBin}/uv run --directory ${home}/projects/inbox python inbox_server.py"
        ];
        KeepAlive = true;
        RunAtLoad = true;
        ThrottleInterval = 10;
        WorkingDirectory = "${home}/projects/inbox";
        EnvironmentVariables = {
          HOME = home;
          PATH = "${brewBin}:${defaultPATH}";
        };
        StandardOutPath = "${home}/.local/share/jw/inbox-server.log";
        StandardErrorPath = "${home}/.local/share/jw/inbox-server.log";
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
