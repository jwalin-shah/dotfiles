# Centralized service configuration for headroom, launchagents, and proxies
# Single source of truth for background services

{
  # Headroom proxy — context optimization gateway
  # Routes all TokenRouter clients through compression/caching layer
  # Port 8788 → port 18999 (TokenRouter)
  headroom = {
    enabled = true;
    port = 8788;
    upstream_url = "http://127.0.0.1:18999";
    mode = "token";  # compression-first mode
    features = {
      code_aware = true;
      intercept_tool_results = true;
      request_timeout_seconds = 300;
      no_rate_limit = true;
    };
    log_path = "~/.local/share/jw/headroom-tokenrouter.log";
  };

  # TokenRouter gateway — unified LLM provider routing
  # Port 18999 — routes to 100+ models via unified API
  tokenrouter = {
    enabled = true;
    port = 18999;
    mode = "routing-proxy";
    description = "Unified LLM provider gateway";
  };

  # MLX Chat Server — local inference
  # Port 8080 — local Gemma/Qwen models
  mlx_chat = {
    enabled = true;
    port = 8080;
    models = [
      "Gemma 4 4B"
      "Qwen3.5 9B"
      "Qwen2.5 1.5B"
    ];
  };

  # Embeddings services
  embeddings = {
    llama_embed = {
      enabled = true;
      port = 8081;
      model = "Qwen3-Embedding-0.6B (GGUF Q8)";
    };
    coderank_embed = {
      enabled = true;
      port = 8082;
      model = "CodeRankEmbed (GGUF Q8)";
    };
  };

  # Cognee — AI memory platform
  cognee = {
    enabled = true;
    port = 8000;
    version = "1.2.2";
    backend_llm = "Gemma 4 4B";
    backend_embed = "Qwen3 Embed";
  };

  # CocoIndex — semantic code search
  cocoindex = {
    enabled = true;
    chunks = 5148;
    files = 252;
  };

  # Launchers — CLI entry points for agents
  launchers = {
    ct = {
      name = "Claude Code via TokenRouter";
      uses = "headroom (port 8788)";
      fallback = "headroom (port 18999)";
      permission_mode = "auto";  # TODO: should be --dangerously-skip-permissions
      config = "~/.claude/settings.json";
    };
    cx = {
      name = "Codex (OpenAI)";
      uses = "direct OpenAI API";
      config = "~/.codex/config.toml";
    };
    ca = {
      name = "Claude direct (Anthropic)";
      uses = "direct Anthropic API (OAuth)";
      config = "~/.claude/settings.json";
    };
    ot = {
      name = "OpenCode via TokenRouter";
      uses = "headroom (port 8788)";
      config = "~/.config/opencode/opencode.json";
    };
    agy = {
      name = "Agy (Gemini)";
      uses = "Google Gemini API";
      config = "~/.gemini/antigravity-cli/settings.json";
    };
  };
}
