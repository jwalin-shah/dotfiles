# Local AI Model & Data Manifest

Single source of truth for every machine learning model, vector database, and persistent agent cache on this machine. If a model or dataset is not declared here, it is considered dead weight and is subject to immediate deletion.

Status key: **ACTIVE** = actively used by a defined tool. **DEPRECATED** = safe to delete.

## 1. The Core Hugging Face Cache (`~/.cache/huggingface/hub/`)

This is the primary storage hub for all downloaded weights.

| Model / Dataset | Active User | Purpose | Status |
|---|---|---|---|
| `LiquidAI/LFM2.5-8B-A1B-MLX-4bit` | `mlx-chat-server` | Primary Chat/Reasoning SLM (Port 8080) | ACTIVE |
| `LiquidAI/LFM2.5-230M-MLX-bf16` | Background Tasks | Fast auxiliary reasoning / summarization | ACTIVE |
| `openbmb/MiniCPM5-1B` | Fallback | Fast edge-reasoning | ACTIVE |
| `UsefulSensors/moonshine*` | `voice-engine-swift` | Native CoreML voice transcription (local dictation) | ACTIVE |
| `nvidia/parakeet-rnnt-0.6b` | `voice-engine-swift` | High-accuracy secondary voice transcription | ACTIVE |
| `Qwen/Qwen3-Embedding-0.6B-GGUF` | `llama-embed-server` | General text embedding model (Port 8081) | ACTIVE |
| `handwoven8588/CodeRankEmbed-GGUF` | `coderank-embed-server` | Specialized codebase indexing (Port 8082) | ACTIVE |
| `nomic-ai/CodeRankEmbed` | `cocoindex-daemon` | Codebase semantic mapping | ACTIVE |
| `urchade/gliner_*` | `bridge` (Extractors) | Fast Named Entity Recognition (NER) | ACTIVE |
| `microsoft/deberta-v3-*` | `bridge` | Zero-shot classification and extraction | ACTIVE |
| `chopratejas/kompress-v2-base` | `voice-engine-swift` (`.headroom`) | Prompt/token compression | ACTIVE |

## 2. Persistent RAG and Vector Databases (`~/.local/share/`)

This tracks where agents store their memories permanently.

| Store | Location | Purpose | Status |
|---|---|---|---|
| **Cognee Graph** | `~/.local/share/cognee/` | Long-term cross-session knowledge graph and memories | ACTIVE |
| **CocoIndex** | `~/.local/share/cocoindex/` | Semantic embedding indices for all `~/projects/` | ACTIVE |
| **Llama Server** | `~/.local/share/llama-embed-server/` | Log and runtime state for local embedding servers | ACTIVE |

## 3. Project-Specific Ephemeral States

| Store | Location | Purpose | Status |
|---|---|---|---|
| **Headroom** | `~/projects/voice-engine-swift/.headroom/` | Self-contained SQLite vector database for voice history | ACTIVE |
| **Bridge State** | `~/projects/bridge/.bridge/` | Local orchestrator session data and task tracking | ACTIVE |

---
**Quota Architecture Rule (Adopted July 2026):**
We do **not** use background polling daemons (`quota-core`). Claude and other modern APIs literally return their token usage in the API response block (`usage: {input_tokens: X, output_tokens: Y}`). 
`bridge` must natively intercept these API responses, extract the token data, and log it synchronously to SQLite. Polling is strictly banned.
