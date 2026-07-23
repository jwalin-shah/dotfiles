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
      AppleICUForce24HourTime = true;                # 24-hour clock
      AppleMetricUnits = 1;                          # Metric system (1=on, 0=off)
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
      askForPasswordDelay = 0;
    };
    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false;  # Manual updates only
    spaces.spans-displays = false;                  # Each display has its own Spaces
    loginwindow = {
      GuestEnabled = false;                         # No guest account
      SHOWFULLNAME = true;                          # Show name + password field
    };
    hitoolbox.AppleFnUsageType = "Do Nothing";      # Fn key does nothing (reclaim it)

    CustomUserPreferences = {
      "com.apple.LaunchServices" = {
        LSQuarantine = false;
      };
      "com.apple.finder" = {
        QLEnableTextSelection = true;
        CalculateAllSizes = true;                    # Show folder sizes in list view (even unopened)
      };
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      "com.apple.print.PrintingPrefs" = {
        "Quit When Finished" = true;
      };
      "com.apple.frameworks.diskimages" = {
        skip-verify = true;
        skip-verify-locked = true;
        skip-verify-remote = true;
      };
      "com.apple.PowerChime" = {
        ChimeOnAllHardware = false;
      };
      "com.brave.Browser" = {
        AppleEnableSwipeNavigateWithScrolls = false;
        ExtensionInstallForcelist = [
          "hkgfoiooedgoejojocmhlaklaeopbecg;https://clients2.google.com/service/update2/crx"
          "keycebghjcehjfofhccebellnndmhead;https://clients2.google.com/service/update2/crx"
          "dbepggeogbaibhgnhhndojpepiihcmeb;https://clients2.google.com/service/update2/crx"
          "gppongmhjkpfnbhagpmjfkannfbllamg;https://clients2.google.com/service/update2/crx"
        ];
        URLBlocklist = [
          "zoommtg:*"
          "slack:*"
          "spotify:*"
          "discord:*"
        ];
        PopupsBlockedForUrls = [
          # Add any domains here to block all popups/new tabs, e.g.:
          # "https://[*.]somebadsite.com"
        ];
      };
    };
  };

  system.startup.chime = false;

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

    taps = [
      "nikitabobko/tap"
      "felixkratz/formulae"
      "daytonaio/cli"
    ];

    brews = [
      "bat"
      "borders"
      "btop"
      "clang-format"
      "cmake"
      "container"
      "coreutils"
      "daytonaio/cli/daytona"
      "direnv"
      "dust"
      "elan-init"
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
      "neo4j"
      "node"
      "ripgrep"
      "openjdk"
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
      "yazi"
      "sketchybar"
    ];

    casks = [
      "aerospace"
      "alt-tab"
      "brave-browser"
      "google-chrome"
      "chatgpt-classic"
      "cursor"
      "flux-app"
      "ghostty"
      "homerow"
      "karabiner-elements"
      "lulu"
      "lunar"
      "maccy"
      "raycast"
      "shottr"
    ];
  };

  # LaunchAgents -- background services
  launchd.user.agents = let
    home = "/Users/${user}";
    localBin = "${home}/.local/bin";
    uvBin = "${home}/.local/share/uv/tools";
    brewBin = "/opt/homebrew/bin";
    dotfilesBin = "${home}/.dotfiles/bin";
    defaultPATH = "${localBin}:${dotfilesBin}:${brewBin}:/usr/local/bin:/usr/bin:/bin";
  in {

    # llama-embed: Qwen3-Embedding 0.6B on :8081 (1024-dim)
    "com.jwalinshah.llama-embed-server" = {
      serviceConfig = {
        ProgramArguments = [
          "${dotfilesBin}/daemon-wrapper"
          "${brewBin}/llama-server"
          "-m" "$ORBIT_EMBED_MODEL_PATH"
          "--embedding" "--host" "127.0.0.1" "--port" "8081"
          "-c" "2048" "-np" "1" "-b" "2048" "-ub" "2048" "-ngl" "99"
        ];
        KeepAlive.SuccessfulExit = false;
        RunAtLoad = true;
        ThrottleInterval = 10;
        WorkingDirectory = home;
        EnvironmentVariables = {
          HOME = home;
          PATH = defaultPATH;
          DAEMON_NAME = "llama-embed";
          DAEMON_PORT = "8081";
          DAEMON_DISPLAY_NAME = "llama-embed:8081";
          DAEMON_TYPE = "child-block";
          DAEMON_HEALTH_URL = "/health";
          DAEMON_ENV_FILE = "${home}/.config/orbit/models.env";
          DAEMON_EXPAND_ENV = "1";
        };
        StandardOutPath = "${home}/.local/share/orbit/llama-embed.log";
        StandardErrorPath = "${home}/.local/share/orbit/llama-embed.log";
      };
    };

    # coderank-embed: CodeRankEmbed on :8082 (768-dim, 2048 ctx trained)
    "com.jwalinshah.coderank-embed-server" = {
      serviceConfig = {
        ProgramArguments = [
          "${dotfilesBin}/daemon-wrapper"
          "${brewBin}/llama-server"
          "-m" "$ORBIT_CODERANK_MODEL_PATH"
          "--embedding" "--host" "127.0.0.1" "--port" "8082"
          "-c" "2048" "-np" "1" "-b" "2048" "-ub" "2048" "-ngl" "99"
          "--flash-attn" "on"
        ];
        KeepAlive.SuccessfulExit = false;
        RunAtLoad = true;
        ThrottleInterval = 10;
        WorkingDirectory = home;
        EnvironmentVariables = {
          HOME = home;
          PATH = defaultPATH;
          DAEMON_NAME = "coderank-embed";
          DAEMON_PORT = "8082";
          DAEMON_DISPLAY_NAME = "coderank-embed:8082";
          DAEMON_TYPE = "child-block";
          DAEMON_HEALTH_URL = "/health";
          DAEMON_ENV_FILE = "${home}/.config/orbit/models.env";
          DAEMON_EXPAND_ENV = "1";
        };
        StandardOutPath = "${home}/.local/share/orbit/coderank-embed.log";
        StandardErrorPath = "${home}/.local/share/orbit/coderank-embed.log";
      };
    };

    # ── AI Stack (unified daemon-wrapper) ────────────────────────────
    # mlx-chat: Qwen3.5 9B on :8080 (model from models.env)
    # Use python binary directly (not the script) so exec -a works for ps naming.
    "com.jwalinshah.mlx-chat-daemon" = {
      serviceConfig = {
        ProgramArguments = [
          "${dotfilesBin}/daemon-wrapper"
          "${uvBin}/mlx-lm/bin/python"
          "${uvBin}/mlx-lm/bin/mlx_lm.server"
          "--model" "$ORBIT_CHAT_MODEL_REPO"
          "--host" "127.0.0.1" "--port" "8080"
          "--trust-remote-code"
          "--chat-template-args" "{\"enable_thinking\":false}"
        ];
        KeepAlive.SuccessfulExit = false;
        RunAtLoad = true;
        ThrottleInterval = 30;
        WorkingDirectory = home;
        EnvironmentVariables = {
          HOME = home;
          PATH = defaultPATH;
          DAEMON_NAME = "mlx-chat";
          DAEMON_PORT = "8080";
          DAEMON_DISPLAY_NAME = "mlx-chat:8080";
          DAEMON_TYPE = "child-block";
          DAEMON_HEALTH_URL = "/v1/models";
          DAEMON_ENV_FILE = "${home}/.config/orbit/models.env";
          DAEMON_EXPAND_ENV = "1";
          DAEMON_VALIDATION_CMD = "${uvBin}/mlx-lm/bin/python -c 'import mlx_lm; print(\"OK\")'";
        };
        StandardOutPath = "${home}/.local/share/orbit/mlx-chat.log";
        StandardErrorPath = "${home}/.local/share/orbit/mlx-chat.log";
      };
    };





    # tldr daemon: watches ~/projects, auto-refreshes call-graph index.
    # child-block mode: llm-tldr daemonizes internally, wrapper runs as
    # child, verifies, then blocks until SIGTERM.
    "com.jwalinshah.tldr-daemon" = {
      serviceConfig = {
        ProgramArguments = [
          "${uvBin}/llm-tldr/bin/python3"
          "-m" "tldr.daemon" "${home}/projects" "--foreground"
        ];
        KeepAlive = true;
        RunAtLoad = true;
        ThrottleInterval = 30;
        WorkingDirectory = home;
        EnvironmentVariables = {
          HOME = home;
          PATH = defaultPATH;
        };
        StandardOutPath = "${home}/.local/share/orbit/tldr-daemon.log";
        StandardErrorPath = "${home}/.local/share/orbit/tldr-daemon.log";
      };
    };

    # ── AI Stack (continued) ──────────────────────────────────────────

    # cognee-api: REMOVED 2026-07-17 — replaced by bridge Ladybug DB (290MB, 172K edges)
    # Was crash-looping since July 2 with missing Auth0 device client ID.
    # The uv tool and LaunchAgent config are both removed.

    # cocoindex-daemon: REMOVED 2026-07-22 — Neo4j is sole semantic+structure store
    # (knowledge-engine on-change + daily catch-up). Optional `ccc` CLI may remain
    # for bridge soft-fail SearchSource until Neo4j vector search replaces it.
    # Do not re-enable this LaunchAgent as a second sink.

    # knowledge-engine: daily catch-up (cocoindex embeds + sync-graph).
    # Primary path is on-change: fmt-on-edit → neo4j-on-change → on-change-sync.sh.
    # MUST use project .venv (has requests + cocoindex[neo4j]); global uv tool lacks deps.
    "com.jwalinshah.knowledge-engine" = {
      serviceConfig = {
        ProgramArguments = [
          "${dotfilesBin}/daemon-wrapper"
          "${home}/projects/knowledge-engine/scripts/sync-and-embed.sh"
        ];
        RunAtLoad = true;
        # Daily catch-up only — not hourly theater. On-change owns freshness.
        StartCalendarInterval = [
          {
            Hour = 3;
            Minute = 15;
          }
        ];
        WorkingDirectory = "${home}/projects/knowledge-engine";
        EnvironmentVariables = {
          HOME = home;
          PATH = "${home}/projects/knowledge-engine/.venv/bin:${defaultPATH}";
          DAEMON_NAME = "knowledge-engine";
          DAEMON_PORT = "0";
          DAEMON_DISPLAY_NAME = "knowledge-engine:neo4j";
          DAEMON_TYPE = "foreground";
          DAEMON_HEALTH_URL = "pid-only";
          NEO4J_URI = "neo4j://localhost:7687";
          NEO4J_USER = "neo4j";
          NEO4J_PASSWORD = "axiom-knowledge";
        };
        StandardOutPath = "${home}/.local/share/orbit/knowledge-engine.log";
        StandardErrorPath = "${home}/.local/share/orbit/knowledge-engine.log";
      };
    };

    # inbox-server: unified inbox API (Gmail/iMessage/Calendar/Sheets/Docs)
    # Was a hand-installed plist, not nix-managed, not through daemon-wrapper
    # — showed up as generic "python3.12" everywhere, invisible to bridge/
    # orbit health monitoring. See jwalin-shah/inbox#65.
    "com.jwalinshah.inbox-server" = {
      serviceConfig = {
        ProgramArguments = [
          "${dotfilesBin}/daemon-wrapper"
          "${home}/projects/inbox/scripts/run_server_daemon.sh"
        ];
        KeepAlive.SuccessfulExit = false;
        RunAtLoad = true;
        ThrottleInterval = 30;
        WorkingDirectory = "${home}/projects/inbox";
        EnvironmentVariables = {
          HOME = home;
          PATH = defaultPATH;
          DAEMON_NAME = "inbox-server";
          DAEMON_PORT = "9849";
          DAEMON_DISPLAY_NAME = "inbox-server:9849";
          DAEMON_TYPE = "foreground";
          DAEMON_HEALTH_URL = "http://127.0.0.1:9849/health";
        };
        StandardOutPath = "${home}/.local/share/orbit/inbox-server.log";
        StandardErrorPath = "${home}/.local/share/orbit/inbox-server.log";
      };
    };

    # bridge-cdp-quota: refresh ~/.bridge/cdp-cache.json every 6h.
    # Requires CDP Brave profile (bridge/scripts/ensure-cdp-browser.sh) logged
    # into billing sites. Source of truth was hand-installed
    # org.orbit.bridge-cdp-quota (bridge/scripts/org.orbit.bridge-cdp-quota.plist);
    # after rebuild unload that label if still loaded:
    #   launchctl bootout gui/$UID/org.orbit.bridge-cdp-quota
    "com.jwalinshah.bridge-cdp-quota" = {
      serviceConfig = {
        ProgramArguments = [
          "/bin/bash"
          "-c"
          ''
            export PATH="${home}/bin:${home}/.local/bin:${brewBin}:$PATH"
            "${home}/projects/bridge/scripts/ensure-cdp-browser.sh" && \
              "${home}/projects/bridge/scripts/cdp-scrape-quota.py" >>"${home}/.bridge/cdp-scrape.log" 2>&1
          ''
        ];
        StartInterval = 21600;
        RunAtLoad = true;
        WorkingDirectory = "${home}/projects/bridge";
        EnvironmentVariables = {
          HOME = home;
          PATH = defaultPATH;
        };
        StandardOutPath = "${home}/.bridge/cdp-launchd.out.log";
        StandardErrorPath = "${home}/.bridge/cdp-launchd.err.log";
      };
    };

    # -- Session Infrastructure --
    # neo4j: sole knowledge store. Package declared in brews above; runtime
    # ownership is Homebrew `brew services` (homebrew.mxcl.neo4j) — do NOT
    # also declare an org.nixos LaunchAgent or both fight over :7687.
    # Verified 2026-07-21: dual managers left nix agent exit -15 and HTTP down.
    # mintmux: PTY multiplexer (daemonizes internally, child-block mode)
    "com.jwalinshah.mintmux" = {
      serviceConfig = {
        ProgramArguments = [
          "${dotfilesBin}/daemon-wrapper"
          "${localBin}/mintmux"
        ];
        KeepAlive.SuccessfulExit = false;
        RunAtLoad = true;
        ThrottleInterval = 5;
        ExitTimeOut = 10;
        WorkingDirectory = home;
        EnvironmentVariables = {
          HOME = home;
          PATH = defaultPATH;
          DAEMON_NAME = "mintmux";
          DAEMON_PORT = "0";
          DAEMON_DISPLAY_NAME = "mintmux";
          DAEMON_TYPE = "child-block";
          DAEMON_HEALTH_URL = "pid-only";
          DAEMON_HEALTH_CMD = "test -S ${home}/.cache/mintmux/mintmux-$(id -u).sock";
        };
        StandardOutPath = "${home}/.cache/mintmux/launchd-stdout.log";
        StandardErrorPath = "${home}/.cache/mintmux/launchd-stderr.log";
      };
    };


    # m5logd: M5 hardware logging daemon
    "com.jwalinshah.m5logd" = {
      serviceConfig = {
        ProgramArguments = [ "${localBin}/m5logd" ];
        KeepAlive = true;
        RunAtLoad = true;
        ThrottleInterval = 30;
        EnvironmentVariables = {
          HOME = home;
          PATH = "${localBin}:/usr/local/bin:/usr/bin:/bin";
        };
        StandardOutPath = "${home}/Library/Logs/m5logd-stdout.log";
        StandardErrorPath = "${home}/Library/Logs/m5logd-stderr.log";
      };
    };

    # voice-engine: macOS dictation menubar app
    # (Re-enabled: KV-cache decoder rearchitecture built to avoid CoreML states)
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

    # verify-machine: daily machine health (hooks + daemons + config).
    # Closes the gap where verify-machine only ran on rebuild/pre-commit.
    # Log: ~/.local/share/orbit/verify-machine.log
    "com.jwalinshah.verify-machine" = {
      serviceConfig = {
        ProgramArguments = [
          "/bin/bash"
          "-c"
          ''
            export PATH="${home}/.local/bin:${home}/bin:${dotfilesBin}:${brewBin}:$PATH"
            mkdir -p "${home}/.local/share/orbit"
            {
              echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) verify-machine ==="
              if command -v bridge >/dev/null 2>&1; then
                bridge verify-machine
              else
                echo "ERROR: bridge not on PATH" >&2
                exit 1
              fi
              "${home}/projects/dotfiles/bin/prove-launchers.sh" || exit 1
            } >>"${home}/.local/share/orbit/verify-machine.log" 2>&1
          ''
        ];
        RunAtLoad = false;
        StartCalendarInterval = [
          {
            Hour = 9;
            Minute = 0;
          }
        ];
        WorkingDirectory = home;
        EnvironmentVariables = {
          HOME = home;
          PATH = defaultPATH;
        };
        StandardOutPath = "${home}/.local/share/orbit/verify-machine-launchd.log";
        StandardErrorPath = "${home}/.local/share/orbit/verify-machine-launchd.log";
      };
    };

    # ladybug-pipeline: FROZEN 2026-07-21 — Neo4j is the sole knowledge store
    # (Portfolio ADR neo4j-sole-store). LadybugDB file retained read-only as a
    # migration source until knowledge-engine parity is proven. Do not re-enable
    # writers without reversing that ADR.
    # "com.jwalinshah.ladybug-pipeline" = {
    #   serviceConfig = {
    #     ProgramArguments = [
    #       "${home}/projects/bridge/.bridge/ladybug/pipeline.sh"
    #     ];
    #     RunAtLoad = true;
    #     StartInterval = 900;
    #     WorkingDirectory = home;
    #     EnvironmentVariables = {
    #       HOME = home;
    #       PATH = defaultPATH;
    #     };
    #     StandardOutPath = "${home}/.local/share/orbit/ladybug-pipeline.log";
    #     StandardErrorPath = "${home}/.local/share/orbit/ladybug-pipeline.log";
    #   };
    # };
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
