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
      "fw-ai/firectl"
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
      "firectl"
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
      # macOS maintenance/health CLI (mo status/analyze --json → machine-health
      # proof + wake evidence). NOT wired into auto-running destructive clean.
      "mole"
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
    state = "${home}/.local/state";
    defaultPATH = "${localBin}:${dotfilesBin}:${brewBin}:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
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
    # mlx-chat (:8080) PARKED 2026-07-23 — local chat LLM idle after Neo4j
    # sole-store; knowledge path uses embed :8081/:8082 only. Re-enable by
    # restoring the LaunchAgent block from git history.
    # Ticket: wayfinder/tickets/001-park-mlx-chat.md
    # Notes: wayfinder/mlx-chat-parked-2026-07-23.md
    #        portfolio/wayfinder/mlx-chat-parked-2026-07-23.md





    # TLDR has no machine-wide LaunchAgent. fmt-on-edit marks one repository
    # file dirty and `tldr calls` patches that file lazily on its next query.

    # ── AI Stack (continued) ──────────────────────────────────────────

    # cognee-api: REMOVED 2026-07-17 — replaced by bridge Ladybug DB (290MB, 172K edges)
    # Was crash-looping since July 2 with missing Auth0 device client ID.
    # The uv tool and LaunchAgent config are both removed.

    # cocoindex-daemon: REMOVED 2026-07-22 — Neo4j is sole semantic+structure store
    # (knowledge-engine on-change + daily catch-up). Optional `ccc` CLI may remain
    # for bridge soft-fail SearchSource until Neo4j vector search replaces it.
    # Do not re-enable this LaunchAgent as a second sink.

    # knowledge-engine: REMOVED 2026-07-31 — captain cut the daily catch-up.
    # On-change path (fmt-on-edit → neo4j-on-change) still handles incremental
    # updates. Re-add if full daily sync is needed.

    # inbox-server: unified inbox API (Gmail/iMessage/Calendar/Sheets/Docs)
    # Launches the python interpreter DIRECTLY — no bash daemon-wrapper, no
    # run_server_daemon.sh. macOS TCC (Full Disk Access) keys on the
    # responsible-process chain; a bash hop between launchd and python makes
    # the FDA grant on python3.12 never attach, so iMessage/Notes/Reminders
    # reads silently return empty. The frozen interpreter at
    # ~/Applications/inbox-python312/bin/python3.12 is the FDA identity and
    # must never be re-signed/rebuilt. Env setup moved into
    # scripts/launch_server.py.
    "com.jwalinshah.inbox-server" = {
      serviceConfig = {
        ProgramArguments = [
          "${home}/Applications/inbox-python312/bin/python3.12"
          "${home}/projects/inbox/scripts/launch_server.py"
        ];
        KeepAlive.SuccessfulExit = false;
        RunAtLoad = true;
        ThrottleInterval = 30;
        WorkingDirectory = "${home}/projects/inbox";
        EnvironmentVariables = {
          HOME = home;
          PATH = defaultPATH;
        };
        StandardOutPath = "${home}/.local/share/orbit/inbox-server.log";
        StandardErrorPath = "${home}/.local/share/orbit/inbox-server.log";
      };
    };

    # OpenClaw gateway (:18789) — human surface / agent runtime.
    # Package: npm -g `openclaw` (not a Homebrew formula). Token stays in
    # ~/.openclaw/service-env/ai.openclaw.gateway.env (0600), sourced by the
    # OpenClaw-generated env wrapper — do NOT put OPENCLAW_GATEWAY_TOKEN in
    # this file or the nix store.
    #
    # TCC: this agent uses /bin/sh → wrapper → node. That hop is ACCEPTABLE
    # here because OpenClaw must NOT hold Full Disk Access. iMessage/Notes/
    # Reminders are inbox-server's frozen python3.12 identity only. Do not
    # "fix" this by exec'ing node directly in order to attach FDA to OpenClaw.
    # Computer-use / Accessibility is a later grant on a pinned node path,
    # behind Bridge, not FDA.
    #
    # CUTOVER: brew/openclaw still installs LaunchAgent ai.openclaw.gateway.
    # Two KeepAlive jobs on :18789 will fight (same lesson as neo4j dual
    # managers). Run bin/openclaw-adopt-nix.sh BEFORE darwin-rebuild, or
    # bootout ai.openclaw.gateway first.
    "com.jwalinshah.openclaw-gateway" = {
      serviceConfig = {
        ProgramArguments = [
          "/bin/sh"
          "${home}/.openclaw/service-env/ai.openclaw.gateway-env-wrapper.sh"
          "${home}/.openclaw/service-env/ai.openclaw.gateway.env"
          "/opt/homebrew/opt/node/bin/node"
          "/opt/homebrew/lib/node_modules/openclaw/dist/index.js"
          "gateway"
          "--port"
          "18789"
        ];
        KeepAlive = true;
        RunAtLoad = true;
        ProcessType = "Interactive";
        ThrottleInterval = 10;
        ExitTimeOut = 20;
        Umask = 63;
        WorkingDirectory = "${home}/.openclaw";
        EnvironmentVariables = {
          HOME = home;
          PATH = "/opt/homebrew/opt/node/bin:${defaultPATH}";
        };
        StandardOutPath = "${home}/Library/Logs/openclaw/gateway.log";
        StandardErrorPath = "/dev/null";
      };
    };

    # bridge-serve: REMOVED 2026-07-31 — captain cut it; orbit thin shell no longer
    # depends on a permanent bridge daemon. Re-add if bridge needs to serve
    # continuously.

    # bridge-cdp-quota: REMOVED 2026-07-31 — captain cut it. quota-axi handles
    # quota via API calls; no need to scrape billing sites via CDP Brave every 6h.

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

    # homebase: authority daemon — contract/grant admission + durable signed
    # receipt ledger. Binds 127.0.0.1:9102 only. This is the machine's
    # authority spine: bridge CLI talks to it; it is NOT an agent runtime.
    # Keys are provisioned once by bin/provision-authority-keys.sh (0600 under
    # ~/.local/state/homebase/keys) and never declared here (PUBLIC repo).
    "org.nixos.com.jwalinshah.homebase" = {
      serviceConfig = {
        ProgramArguments = [
          "${dotfilesBin}/daemon-wrapper"
          "${localBin}/homebase"
        ];
        KeepAlive.SuccessfulExit = false;
        RunAtLoad = true;
        ThrottleInterval = 10;
        ExitTimeOut = 10;
        WorkingDirectory = "${state}/homebase";
        EnvironmentVariables = {
          HOME = home;
          PATH = defaultPATH;
          DAEMON_NAME = "homebase";
          DAEMON_PORT = "9102";
          DAEMON_DISPLAY_NAME = "homebase:9102";
          DAEMON_TYPE = "foreground";
          DAEMON_HEALTH_URL = "http://127.0.0.1:9102/v1/status";
          DAEMON_WORKING_DIR = "${state}/homebase";
          # Local-only mode: NEO4J_URI is intentionally NOT set, so the Axiom
          # Firewall is disabled and no Neo4j password is required. Set
          # NEO4J_URI + NEO4J_PASSWORD to enable the firewall in a deployment.
          HOMEBASE_RECORD_JOURNAL = "${state}/homebase/homebase_records.journal";
          HOMEBASE_CAPTAIN_PUBLIC_KEY_FILE = "${state}/homebase/keys/captain.pub";
          HOMEBASE_BRIDGE_PUBLIC_KEY_FILE = "${state}/homebase/keys/bridge.pub";
          HOMEBASE_ADMISSION_PRIVATE_KEY_FILE = "${state}/homebase/keys/admission.priv";
          HOMEBASE_VERIFIER_PUBLIC_KEY_FILE = "${state}/homebase/keys/verifier.pub";
          HOMEBASE_VERIFIER_KEY_ID = "verifier";
          HOMEBASE_RECEIPT_PRIVATE_KEY_FILE = "${state}/homebase/keys/receipt.priv";
          PORT = "9102";
        };
        StandardOutPath = "${state}/homebase/homebase.log";
        StandardErrorPath = "${state}/homebase/homebase.log";
      };
    };

    # homebase-drive: admission driver (sidecar, optional). Same authority key
    # set; supplies drive-admit behavior next to the main engine.
    "org.nixos.com.jwalinshah.homebase-drive" = {
      serviceConfig = {
        ProgramArguments = [
          "${dotfilesBin}/daemon-wrapper"
          "${localBin}/drive-admit"
        ];
        KeepAlive.SuccessfulExit = false;
        RunAtLoad = false;
        ThrottleInterval = 10;
        WorkingDirectory = "${state}/homebase";
        EnvironmentVariables = {
          HOME = home;
          PATH = defaultPATH;
          DAEMON_NAME = "homebase-drive";
          DAEMON_PORT = "0";
          DAEMON_DISPLAY_NAME = "homebase-drive";
          DAEMON_TYPE = "foreground";
          DAEMON_HEALTH_URL = "pid-only";
          HOMEBASE_CAPTAIN_PUBLIC_KEY_FILE = "${state}/homebase/keys/captain.pub";
          HOMEBASE_ADMISSION_PRIVATE_KEY_FILE = "${state}/homebase/keys/admission.priv";
        };
        StandardOutPath = "${state}/homebase/homebase-drive.log";
        StandardErrorPath = "${state}/homebase/homebase-drive.log";
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

    # voice-engine: REMOVED 2026-07-31 — captain cut it. macOS dictation menubar
    # app not needed.

    # overnight-harden: REMOVED 2026-07-31 — captain cut it. Nightly prove+spawn
    # queue not needed.

    # verify-machine: REMOVED 2026-07-31 — captain cut it. Daily machine health
    # check not needed.

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
