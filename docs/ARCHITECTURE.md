# Architecture — Machine Scratch

> **Last updated:** 2026-07-02
> **Machine:** MacBook Pro 16" M5 Pro, 48GB RAM, macOS 15.x

This document describes how all the services, launchers, data sources, and MCP
servers connect on this machine. It is the **top-level reference** for
understanding the system as a whole.

---

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    USER INTERFACES (Harnesses)                   │
│  Claude Code  │  OpenCode  │  Codex  │  Cursor  │  Antigravity  │
│  (c/ct/ca)    │  (oo/ot/op)│  (cx)   │  (cu)    │  (agy)        │
└──────────┬───────┴─────┬────┴────┬────┴────┬────┴───────────────┘
           │             │         │         │
           ▼             ▼         ▼         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      MCP / INFRASTRUCTURE                        │
│                                                                  │
│  ┌─────────────────────────┐  ┌──────────────────────────────┐  │
│  │   COGNEE MCP (:7779)    │  │   COCOINDEX (daemon)          │  │
│  │   Knowledge Graph RAG   │  │   Code semantic indexer       │  │
│  │   + session memory      │  │   CodeRankEmbed embeddings    │  │
│  └───────────┬─────────────┘  └──────────────────────────────┘  │
│              │                                                   │
│              ▼                                                   │
│  ┌─────────────────────────┐  ┌──────────────────────────────┐  │
│  │   MLX INFERENCE (:8080)  │  │   MLX EMBEDDING (:8081)      │  │
│  │   Qwen3.5-9B-OptiQ-4bit │  │   Qwen3-Embedding-0.6B-DWQ  │  │
│  │   OpenAI-compatible API  │  │   1024-dim vectors           │  │
│  └─────────────────────────┘  └──────────────────────────────┘  │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │   LADYBUG DB (cognee system DB)                             │ │
│  │   SQLite-backed graph database for RAG                      │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DATA SOURCES                                  │
│                                                                  │
│  ~/.cognee_transcripts/        30 markdown files (1.7 MB)       │
│  ~/.claude-token/projects/     4621 session files (725 MB)      │
│  ~/.claude-token/history.jsonl Claude session history           │
│  ~/data/vault/                 9 trace/transcript files (1 GB)  │
│  ~/data-exports/_datasets/     3 corpus files (130 MB)          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Service Architecture

### 1. MLX Inference Server (`:8080`)

| Detail | Value |
|---|---|
| **Model** | mlx-community/Qwen3.5-9B-OptiQ-4bit |
| **Path** | `~/.cache/huggingface/hub/models--mlx-community--Qwen3.5-9B-OptiQ-4bit/` |
| **Port** | 8080 |
| **Launch** | `nohup uv tool run --from mlx-lm mlx_lm.server --model <path> --host 127.0.0.1 --port 8080` |
| **API** | OpenAI-compatible (`/v1/chat/completions`, `/v1/completions`) |
| **Max tokens** | 8192 |
| **Autostart** | Via `~/bin/start-cognee-mcp` |
| **Log** | `/tmp/mlx-inference.log` |

**Used by:** cognee MCP (LLM for entity extraction + query), any local OpenAI-compatible client.

### 2. MLX Embedding Server (`:8081`)

| Detail | Value |
|---|---|
| **Model** | mlx-community/Qwen3-Embedding-0.6B-4bit-DWQ |
| **Port** | 8081 |
| **Launch** | `mlx-embed-server --port 8081` (via `bin/mlx-embed-server`) |
| **API** | `/v1/embeddings` (OpenAI-compatible) |
| **Dimensions** | 1024 |
| **Autostart** | Via `~/bin/start-cognee-mcp` |
| **Log** | `/tmp/mlx-embed-server.log` |

**Used by:** cognee MCP (embedding provider for doc ingestion and search).

### 3. Cognee MCP Server (`:7779`)

| Detail | Value |
|---|---|
| **Type** | SSE (Server-Sent Events) MCP |
| **Port** | 7779 |
| **URL** | `http://127.0.0.1:7779/sse` |
| **Backend** | Ladybug DB (SQLite graph database) |
| **Provider** | `openai_compatible` (MLX embedding on :8081) |
| **LLM** | `openai/mlx-community/Qwen3.5-9B-OptiQ-4bit` (litellm routing) |
| **Launch** | `uv run --directory ~/projects/cognee/cognee-mcp python src/server.py` |
| **Log** | `/tmp/cognee-mcp.log` |

**Ingested datasets:**

| Dataset | Source | Entries | Status |
|---|---|---|---|
| `cognee_transcripts` | ~/.cognee_transcripts/ (30 .md files) | 30 | ✅ |
| `claude_history` | 4 history.jsonl files | 2,176 | ✅ |
| `vault_transcripts` | ~/data/vault/claude-transcripts-hf.jsonl | 4,233 | ✅ |
| `vault_corpus` | ~/data-exports/_datasets/corpus.jsonl | 8,580 | 🔄 |
| `vault_corpus_eval` | ~/data-exports/_datasets/corpus.eval.jsonl | 484 | 🔄 |
| `vault_cursor` | ~/data-exports/_datasets/cursor.jsonl | 1,148 | 🔄 |

**Cognify (knowledge graph build) is BLOCKED** by:
- Qwen3.5 structured output incompatibility with `instructor` library
- GPU OOM on M5 Pro under concurrent large-context requests

### 4. Cocoindex Daemon

| Detail | Value |
|---|---|
| **Type** | Code semantic indexer |
| **Backend** | sentence-transformers + CodeRankEmbed |
| **Launcher** | `ccc run-daemon` / `ccc` CLI |
| **Watcher** | `code-watcher` monitors ~/projects |
| **Scope** | machine-scratch repo (485 chunks, 74 files) |

**Used by:** Claude Code via MCP (code context retrieval for active projects).

---

## Launcher Architecture

Each harness tool has wrapper scripts in `~/bin/` that inject secrets and
configure the correct environment.

```
~/bin/c    -> Claude Code (OAuth account A)
~/bin/ct   -> secret-cache exec -> Claude Code (TokenRouter key)
~/bin/ca   -> claude-launch -> Claude Code (compatibility OAuth)

~/.local/bin/oo -> OpenCode (ChatGPT Plus OAuth, no secret-cache)
~/.local/bin/ot -> secret-cache exec -> OpenCode (TokenRouter key)
~/.local/bin/op -> secret-cache exec -> OpenCode (Pioneer key)

~/.local/bin/cx -> Codex CLI (bare, no secret-cache)
~/bin/ko   -> Kilo (OpenAI/ChatGPT)
~/bin/kt   -> secret-cache exec -> Kilo (TokenRouter key)
~/bin/cu   → cursor-agent
~/bin/agy  → Antigravity CLI
```

Secret management:
- **Infisical** → `secret-cache` (cached in ~/.local/share/secret-cache/)
- **LaunchAgent** `com.jwalinshah.secret-cache-refresh.plist` refreshes daily
- Keys are never exported in shell startup files

---

## Data Flow

### RAG Pipeline

```
Data Source → ingest-all.py / cognee.add() → Ladybug DB → cognee MCP query
                                                                ↓
Data Source → cocoindex.index() → Vector Index → cocoindex MCP query
```

cognee handles **conversation/session data** for Q&A about past work.
cocoindex handles **code context** for active project retrieval.

### MLX Model Pipeline

```
start-cognee-mcp
    ├── mlx_lm.server (:8080) — Qwen3.5-9B inference
    └── mlx-embed-server (:8081) — Qwen3-Embedding
            │
            ▼
    cognee MCP (:7779)
            │
            ▼
    Claude Code ← SSE connection
```

---

## Agent Rules & Skills

```
~/.agent-rules/              (symlink → machine-scratch/agent-rules/)
├── GLOBAL.md                Top-level agent instructions
├── TOOL_REGISTRY.md         Approved tool catalogue
└── KNOWN_ISSUES.md          Cross-harness known issues

~/.agents/skills/            (symlink → machine-scratch/skills/)
├── pioneer-api/             Pioneer API workflows
├── inference-net/           Catalyst/inf CLI
└── find-docs/               Context7 library docs
```

---

## Related Documents

| Document | Content |
|---|---|
| `FILE_MANIFEST.md` | Complete data catalog with sizes, format descriptions |
| `SETUP_INVENTORY.md` | Active tools, configs, and policies on this machine |
| `ACTIVE_MACHINE_SETUP.md` | Summary of active repos, policies, secrets |
| `OPERATING_MODEL.md` | How capabilities get promoted to active state |
| `DESIGN_NOTES.md` | VoiceEngine architecture and known issues |
| `DATA_PIPELINE.md` | Where each data source lives and how it's ingested |
