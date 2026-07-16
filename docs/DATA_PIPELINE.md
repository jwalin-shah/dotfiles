# Data Pipeline

> **Last updated:** 2026-07-02

This document describes every data source on this machine, where it lives,
what format it's in, how it gets ingested, and whether it's suitable for
RAG / search.

---

## Pipeline Overview

```
                       ┌──────────────────┐
                       │   Data Sources    │
                       │  (see below)     │
                       └────────┬─────────┘
                                │
                 ┌──────────────┴──────────────┐
                 │          Format              │
                 │  JSONL (conversation)        │
                 │  JSONL (OTel spans)          │
                 │  Markdown (transcripts)      │
                 │  JSONL (history)             │
                 └──────────────┬──────────────┘
                                │
            ┌───────────────────┼───────────────────┐
            ▼                   ▼                   ▼
    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
    │  cognee RAG   │    │  cocoindex   │    │  Not ingested│
    │  Ladybug DB   │    │  Code Index  │    │  (spans,     │
    │  (conversation│    │  (code repos)│    │   binary,    │
    │   data)       │    │              │    │   archives)  │
    └──────────────┘    └──────────────┘    └──────────────┘
```

---

## Source-by-Source Breakdown

### 1. `~/.cognee_transcripts/` — Session Transcripts

| Attribute | Value |
|---|---|
| **Files** | 30 Markdown (`.md`) files + 3 summary files |
| **Total size** | ~1.7 MB |
| **Format** | Markdown with conversation text |
| **Format notes** | Plain text summaries of Claude sessions |

**Ingestion:**

**Suitable for:** ✅ RAG (conversational text)

---

### 2. `~/.claude-token/projects/` — Claude Session Data

| Attribute | Value |
|---|---|
| **Path** | `~/.claude-token/projects/` |
| **Files** | ~4,621 files across ~30 project directories |
| **Total size** | ~725 MB |
| **Format** | Per-project directories with `.jsonl` session files + metadata |

**Structure:**
```
~/.claude-token/projects/
├── -Users-jwalinshah-projects-machine-scratch/ (354 MB, ~36 sessions)
│   ├── <uuid>.jsonl        # Session conversation log
│   ├── <uuid>/             # Session metadata directory
│   │   ├── tokens.json     # Token usage data
│   │   └── messages.json   # Additional message data
├── -Users-jwalinshah-projects-fm-tui/      (24 sessions)
├── -Users-jwalinshah-projects-cerebras-.../ (20 sessions)
└── ... (25+ more project dirs)
```

**Format notes:** Each session is a `<uuid>.jsonl` file containing the
conversation between the user and Claude Code, with system messages, tool
calls, and user prompts. Metadata lives in sibling `<uuid>/` directories.

**Ingestion status:** ⬜ **Not yet indexed into cocoindex**
- These are per-project session files managed by Claude Code's own persistence
- ~36 machine-scratch sessions alone are 354 MB

**Suitable for:** ✅ Code context (cocoindex), ⬜ Maybe RAG

---

### 3. `~/.claude-token/history.jsonl` — Claude Session History

| Attribute | Value |
|---|---|
| **Path** | `~/.claude-token/history.jsonl` |
| **Size** | 676 KB |
| **Lines** | 1,856 |
| **Format** | JSONL — `{display, sessionId, timestamp, ...}` |

**Ingestion:**

**Suitable for:** ✅ RAG (session summaries)

---

### 4. `~/.claude-pioneer/history.jsonl` — Pioneer Session History

| Attribute | Value |
|---|---|
| **Path** | `~/.claude-pioneer/history.jsonl` |
| **Size** | 76 KB |
| **Lines** | 230 |
| **Format** | JSONL — `{display, sessionId, timestamp, ...}` |

**Ingestion:**

**Suitable for:** ✅ RAG (session summaries)

---

### 5. `~/.codex/history.jsonl` — Codex Session History

| Attribute | Value |
|---|---|
| **Path** | `~/.codex/history.jsonl` |
| **Size** | 4 KB |
| **Lines** | 2 |
| **Format** | JSONL — `{display, sessionId, timestamp, ...}` |

**Ingestion:**

**Suitable for:** ✅ RAG (session summaries)

---

### 6. `~/.gemini/antigravity-cli/history.jsonl` — Gemini Session History

| Attribute | Value |
|---|---|
| **Path** | `~/.gemini/antigravity-cli/history.jsonl` |
| **Size** | 20 KB |
| **Lines** | 94 |
| **Format** | JSONL — `{display, sessionId, timestamp, ...}` |

**Ingestion:**

**Suitable for:** ✅ RAG (session summaries)

---

### 7. `~/data/vault/` — Trace & Transcript Data

**Two distinct data types live here:**

#### 7a. OpenTelemetry Spans (7 files)

| File | Lines | Size | Source |
|---|---|---|---|
| `traces-claude.jsonl` | 496,467 | 670 MB | Claude Code |
| `traces-pi.jsonl` | 53,277 | 220 MB | Pioneer |
| `traces-cursor.jsonl` | 61,554 | 95 MB | Cursor IDE |
| `traces-gemini.jsonl` | 19,031 | 36 MB | Gemini CLI |
| `traces-codex.jsonl` | 8,063 | 32 MB | Codex CLI |
| `traces-opencode.jsonl` | 10,065 | 17 MB | OpenCode |
| `test-subagent-link.jsonl` | 1,968 | 2.7 MB | Subagent test |

**Format:** `{trace_id, span_id, parent_span_id, name, kind, start_time, end_time, status, resource, scope, attributes}`

These are structured telemetry spans, not
conversational text. Suitable for:
- **inference.net Catalyst** trace analysis
- Custom span analysis scripts
- Agent performance monitoring

#### 7b. Conversation Transcript (1 file)

| File | Lines | Size |
|---|---|---|
| `claude-transcripts-hf.jsonl` | 4,233 | 3.7 MB |

**Format:** `{messages: [{role, content}, ...], project, file, turn_count, source}`

**Ingestion:**
- Tool: `bin/ingest-all.py` with `--dataset vault_transcripts`

**Suitable for:** ✅ RAG (conversational text)

---

### 8. `~/data-exports/_datasets/` — Evaluation Data (3 files)

| File | Lines | Size | Format |
|---|---|---|---|
| `corpus.jsonl` | 8,580 | 111 MB | `{messages: [{role, content}], meta: {...}}` |
| `corpus.eval.jsonl` | 484 | 5.9 MB | `{messages: [{role, content}], meta: {...}}` |
| `cursor.jsonl` | 1,148 | 13 MB | `{messages: [{role, content}], meta: {...}}` |

**Ingestion:** 🔄 In progress
- `corpus.jsonl` → `vault_corpus` dataset
- `corpus.eval.jsonl` → `vault_corpus_eval` dataset
- `cursor.jsonl` → `vault_cursor` dataset

**Suitable for:** ✅ RAG (conversational text with metadata)

---

## Ingestion Tools

### `bin/ingest-all.py` — Generalized JSONL Ingester

Auto-detects data format and ingests:

```
python3 bin/ingest-all.py [--dataset NAME] FILE [FILE ...]
python3 bin/ingest-all.py --list   # preview what would be ingested
```

**Required env vars** (set by runner):
- `LLM_PROVIDER=openai`
- `LLM_ENDPOINT=http://localhost:8080/v1`
- `LLM_MODEL=openai/mlx-community/Qwen3.5-9B-OptiQ-4bit`
- `LLM_API_KEY=sk-local`
- `EMBEDDING_PROVIDER=openai_compatible`
- `EMBEDDING_ENDPOINT=http://127.0.0.1:8081`
- `EMBEDDING_MODEL=default`
- `EMBEDDING_DIMENSIONS=1024`
- `COGNEE_SKIP_CONNECTION_TEST=true`

**Run via:** `uv run --directory ~/projects/cognee/cognee-mcp python3 bin/ingest-all.py`

### `bin/ingest-history.py` — History JSONL Ingester

Specialized for Claude history format (`{display, sessionId, timestamp}`).
Reads from `~/.claude-token/history.jsonl`, `~/.claude-pioneer/history.jsonl`,
`~/.codex/history.jsonl`, `~/.gemini/antigravity-cli/history.jsonl`.

---

## Known Pipeline Issues

| Issue | Impact | Status |
|---|---|---|
| **Cognify blocked** | Knowledge graph build from ingested data fails | Qwen3.5 `instructor` incompatibility |
| **GPU OOM** | Entity extraction fails under concurrent requests | M5 Pro memory ceiling reached |
| **Trace spans unsuitable for RAG** | ~650K trace lines skipped | Not a bug — different analysis tool needed |
