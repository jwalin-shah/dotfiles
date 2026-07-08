{ lib, user, ... }:

{
  nix-homebrew.autoMigrate = true;

  homebrew.brews = [
    "bat"
    "borders"
    "btop"
    "clang-format"
    "cmake"
    "coreutils"
    "direnv"
    "dust"
    "eza"
    "fastfetch"
    "fd"
    "ffmpeg"
    "fswatch"
    "fzf"
    "gh"
    "go"
    "golangci-lint"
    "node"
    "opencode"
    "llama.cpp"
    "infisical"
    "jq"
    "lazygit"
    "llvm"
    "ncdu"
    "ruff"
    "rustup"
    "shellcheck"
    "spotify_player"
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
  homebrew.casks = [
    "aerospace"
    "antigravity-cli"
    "brave-browser"
    "claude-code"
    "cursor"
    "ghostty"
    "hiddenbar"
    "karabiner-elements"
    "lulu"
    "monitorcontrol"
    "raycast"
  ];

  launchd.user.agents = {
    # ── Core AI Infrastructure ──────────────────────────────────────────────────
    "com.jwalinshah.mlx-chat-server" = {
      serviceConfig = {
        ProgramArguments = [ "/Users/${user}/bin/start-mlx-server.sh" ];
        KeepAlive = true;
        RunAtLoad = true;
        ThrottleInterval = 10;
        EnvironmentVariables = {
          HOME = "/Users/${user}";
          PATH = lib.mkForce "/Users/${user}/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin";
        };
        StandardOutPath = "/Users/${user}/.local/share/jw/mlx-chat.log";
        StandardErrorPath = "/Users/${user}/.local/share/jw/mlx-chat.log";
      };
    };

    "com.jwalinshah.llama-embed-server" = {
      serviceConfig = {
        ProgramArguments = [ "/Users/${user}/.local/bin/jw-llama-embed" ];
        KeepAlive = true;
        RunAtLoad = true;
        ThrottleInterval = 10;
        EnvironmentVariables = {
          PATH = lib.mkForce "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin";
        };
        StandardOutPath = "/Users/${user}/.local/share/jw/llama-embed.log";
        StandardErrorPath = "/Users/${user}/.local/share/jw/llama-embed.log";
      };
    };

    "com.jwalinshah.coderank-embed-server" = {
      serviceConfig = {
        ProgramArguments = [ "/Users/${user}/.local/bin/jw-coderank-embed" ];
        KeepAlive = true;
        RunAtLoad = true;
        ThrottleInterval = 10;
        EnvironmentVariables = {
          PATH = lib.mkForce "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin";
        };
        StandardOutPath = "/Users/${user}/.local/share/jw/coderank-embed.log";
        StandardErrorPath = "/Users/${user}/.local/share/jw/coderank-embed.log";
      };
    };

    "com.jwalinshah.cognee-api" = {
      serviceConfig.ProgramArguments = [
        "/Users/${user}/.local/share/uv/tools/cognee/bin/python"
        "-m"
        "cognee.api.client"
      ];
      serviceConfig = {
        KeepAlive = true;
        RunAtLoad = true;
        ThrottleInterval = 10;
        EnvironmentVariables = {
          PATH = lib.mkForce "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin";
          CACHING = "true";
          COGNEE_SKIP_CONNECTION_TEST = "true";
          ENABLE_BACKEND_ACCESS_CONTROL = "false";
          HTTP_API_HOST = "127.0.0.1";
          HTTP_API_PORT = "8000";
          EMBEDDING_API_KEY = "local";
          EMBEDDING_DIMENSIONS = "1024";
          EMBEDDING_ENDPOINT = "http://127.0.0.1:8081/v1";
          EMBEDDING_MODEL = "mlx-community/Qwen3-Embedding-0.6B-4bit-DWQ";
          EMBEDDING_PROVIDER = "openai_compatible";
          LLM_API_KEY = "local";
          LLM_ARGS = "{\"extra_body\": {\"thinking\": {\"type\": \"disabled\"}}, \"max_tokens\": 4096}";
          LLM_ENDPOINT = "http://127.0.0.1:8080/v1";
          LLM_INSTRUCTOR_MODE = "markdown_json_mode";
          LLM_MAX_COMPLETION_TOKENS = "32768";
          LLM_MODEL = "openai/mlx-community/Qwen2.5-1.5B-Instruct-4bit";
          LLM_PROVIDER = "openai";
        };
        StandardOutPath = "/Users/${user}/.local/share/jw/cognee-api.log";
        StandardErrorPath = "/Users/${user}/.local/share/jw/cognee-api.log";
      };
    };

    # ── Session & Daemon Infrastructure ────────────────────────────────────────
    "com.jwalinshah.mintmux" = {
      serviceConfig = {
        ProgramArguments = [ "/Users/${user}/.local/bin/mintmux" ];
        KeepAlive = true;
        RunAtLoad = true;
        EnvironmentVariables = {
          PATH = lib.mkForce "/opt/homebrew/bin:/Users/${user}/.local/bin:/usr/local/bin:/usr/bin:/bin";
        };
        StandardOutPath = "/Users/${user}/.cache/mintmux/launchd-stdout.log";
        StandardErrorPath = "/Users/${user}/.cache/mintmux/launchd-stderr.log";
      };
    };

    "com.jwalinshah.jw-sessiond" = {
      serviceConfig = {
        ProgramArguments = [ "/Users/${user}/.local/bin/jw-sessiond" ];
        KeepAlive = true;
        RunAtLoad = true;
        EnvironmentVariables = {
          HOME = "/Users/${user}";
          PATH = lib.mkForce "/opt/homebrew/bin:/Users/${user}/.local/bin:/usr/local/bin:/usr/bin:/bin";
        };
        StandardOutPath = "/Users/${user}/.local/share/jw/sessiond-stdout.log";
        StandardErrorPath = "/Users/${user}/.local/share/jw/sessiond-stderr.log";
      };
    };

    "com.jwalinshah.jw-sentry" = {
      serviceConfig = {
        ProgramArguments = [ "/Users/${user}/.local/bin/jw-sentry" ];
        KeepAlive = true;
        RunAtLoad = true;
        ThrottleInterval = 5;
        EnvironmentVariables = {
          PATH = lib.mkForce "/Users/${user}/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin";
        };
        StandardOutPath = "/Users/${user}/.local/share/jw/sentry-stdout.log";
        StandardErrorPath = "/Users/${user}/.local/share/jw/sentry-stderr.log";
      };
    };

    "com.jwalinshah.jw-agentd" = {
      serviceConfig.ProgramArguments = [
        "/Users/${user}/.local/bin/jw-agentd"
        "--no-mlx"
      ];
      serviceConfig = {
        KeepAlive = true;
        RunAtLoad = true;
        ThrottleInterval = 5;
        EnvironmentVariables = {
          PATH = lib.mkForce "/Users/${user}/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin";
        };
        StandardOutPath = "/Users/${user}/.local/share/jw/agentd-stdout.log";
        StandardErrorPath = "/Users/${user}/.local/share/jw/agentd-stderr.log";
      };
    };

    # ── Monitoring & Health ────────────────────────────────────────────────────
    "com.jw.heal" = {
      serviceConfig = {
        ProgramArguments = [ "/Users/${user}/.local/bin/jw-heal" ];
        RunAtLoad = true;
        StartInterval = 300;
        StandardOutPath = "/Users/${user}/.local/share/jw/heal-stdout.log";
        StandardErrorPath = "/Users/${user}/.local/share/jw/heal-stderr.log";
      };
    };

    "com.jwalinshah.m5logd" = {
      serviceConfig = {
        ProgramArguments = [ "/Users/${user}/.local/bin/m5logd" ];
        KeepAlive = true;
        RunAtLoad = true;
        EnvironmentVariables = {
          HOME = "/Users/${user}";
          PATH = lib.mkForce "/Users/${user}/.local/bin:/usr/local/bin:/usr/bin:/bin";
        };
        StandardOutPath = "/Users/${user}/Library/Logs/m5logd-stdout.log";
        StandardErrorPath = "/Users/${user}/Library/Logs/m5logd-stderr.log";
      };
    };

    "com.jwalinshah.quota-keychain-sync" = {
      serviceConfig = {
        ProgramArguments = [ "/Users/${user}/.local/bin/jw-quota-keychain-sync" ];
        RunAtLoad = true;
        StartInterval = 3600;
        EnvironmentVariables = {
          PATH = lib.mkForce "/opt/homebrew/bin:/Users/${user}/.local/bin:/usr/local/bin:/usr/bin:/bin";
        };
        StandardOutPath = "/Users/${user}/.cache/quota-core/keychain-sync.log";
        StandardErrorPath = "/Users/${user}/.cache/quota-core/keychain-sync.log";
      };
    };

    "com.jwalinshah.jw-cred-canary" = {
      serviceConfig = {
        ProgramArguments = [ "/bin/bash" "/Users/${user}/bin/jw-cred-canary.sh" ];
        StartCalendarInterval = [
          { Hour = 9; Minute = 0; }
          { Hour = 21; Minute = 0; }
        ];
        StandardOutPath = "/Users/${user}/.local/share/jw/cred-canary.log";
        StandardErrorPath = "/Users/${user}/.local/share/jw/cred-canary.log";
      };
    };

    # ── Desktop Utilities ──────────────────────────────────────────────────────
    "com.jwalinshah.voice-engine" = {
      serviceConfig = {
        ProgramArguments = [ "/Users/${user}/.local/bin/voice-engine" ];
        KeepAlive = true;
        RunAtLoad = true;
        ThrottleInterval = 10;
        EnvironmentVariables = {
          HOME = "/Users/${user}";
          PATH = lib.mkForce "/Users/${user}/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin";
        };
        StandardOutPath = "/tmp/voice-engine.log";
        StandardErrorPath = "/tmp/voice-engine.log";
      };
    };

    "com.jwalinshah.brave-automation" = {
      serviceConfig = {
        ProgramArguments = [ "/Users/${user}/bin/brave-automation" ];
        RunAtLoad = true;
        StartInterval = 900;
        EnvironmentVariables = {
          PATH = lib.mkForce "/opt/homebrew/bin:/Users/${user}/.local/bin:/usr/local/bin:/usr/bin:/bin";
          BRAVE_AUTOMATION_BACKGROUND = "1";
          BRAVE_AUTOMATION_MODE = "ensure";
        };
        StandardOutPath = "/Users/${user}/.cache/quota-core/brave-automation.log";
        StandardErrorPath = "/Users/${user}/.cache/quota-core/brave-automation.log";
      };
    };
  };

  launchd.daemons."com.jwalinshah.m5fand" = {
    serviceConfig = {
      ProgramArguments = [ "/Users/${user}/.local/bin/m5fand" ];
      KeepAlive = true;
      RunAtLoad = true;
      EnvironmentVariables = {
        HOME = "/Users/${user}";
        PATH = lib.mkForce "/Users/${user}/.local/bin:/usr/local/bin:/usr/bin:/bin";
      };
      StandardOutPath = "/Users/${user}/Library/Logs/m5fand.log";
      StandardErrorPath = "/Users/${user}/Library/Logs/m5fand.log";
    };
  };
}
