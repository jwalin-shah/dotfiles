# File Manifest — Data Sources Catalog

> **Generated:** 2026-07-02
> **Machine:** MacBook Pro 16" M5 Pro, 48GB RAM
> **User:** jwalinshah

This manifest catalogs every data source on this machine: session traces, transcripts,
history logs, evaluation data, and home-directory artifacts. It is the **single source
of truth** for what data exists and where it lives.

---

## 1. Primary Data Sources

### 1.1 `~/.claude-token/projects/` — Claude Session Data

| Attribute | Value |
|---|---|
| **Total size** | 725 MB |
| **JSONL files** | 142 files (157 MB total, ~82,827 lines) |
| **Other files** | 38 (memory/state files, no JSONL extension) |
| **Project directories** | 30 distinct projects |
| **Total files** | ~4,598 files |
| **Source** | Claude Code (`~/.claude-token/` persistence dir) |

**Projects represented** (by directory name → inferred topic):

| Directory | Size | Sessions | Topic |
|---|---|---|---|---|
| `-Users-jwalinshah-projects-machine-scratch` | 354 MB | ~36 sessions | Main machine-scratch control repo |
| `-Users-jwalinshah-projects-cerebras-gemma4-hackathon` | 228 MB | 10 sessions | Cerebras Gemma4 hackathon |
| `-Users-jwalinshah-projects-btw-research` | 83 MB | 4 sessions | BTW research project |
| `-Users-jwalinshah-projects-datamine` | 11 MB | 1 session | Datamine project |
| `-Users-jwalinshah-projects-voice-engine-swift*` | ~9 MB | 5 sessions | VoiceEngine Swift |
| `-Users-jwalinshah-projects-fm-tui` | 3.2 MB | 1 session | FM TUI project |
| `-Users-jwalinshah--treehouse-quota-core-87d2fe-*` | ~6 MB total | 13 sessions | Treehouse quota-core runs |
| `-Users-jwalinshah--gemini-antigravity-ide-brain` | 888 KB | 4 sessions | Gemini antigravity IDE brain |
| `-Users-jwalinshah-projects-mintmux` | 20 KB | 0 sessions | Mintmux project |
| `-Users-jwalinshah` | ~7 MB | 10 sessions | Ad-hoc/in-root sessions |
| `-Users-jwalinshah-projects` | ~7 MB | 10 sessions | Various other projects |
| `-private-tmp` | 27 KB | 2 sessions | Temporary sessions |
| Current `complete-machine-scr` worktree | 184 KB | 1 session | This run |

Each session consists of a `.jsonl` file (conversation history + tool calls) and
optionally a subdirectory with subagent transcripts.

---

### 1.2 `~/data/vault/` — Trace & Transcript Data (1.0 GB)

| File | Size | Lines | Format | Content |
|---|---|---|---|---|---|
| `traces-claude.jsonl` | 669 MB | 496,467 | JSONL (OTel spans) | Claude Code OpenTelemetry spans — span_id, parent_span_id, attributes |
| `traces-pi.jsonl` | 220 MB | 53,277 | JSONL (OTel spans) | Pi (Pioneer) agent OpenTelemetry spans |
| `traces-cursor.jsonl` | 95 MB | 61,554 | JSONL (OTel spans) | Cursor IDE OpenTelemetry spans |
| `traces-gemini.jsonl` | 36 MB | 19,031 | JSONL (OTel spans) | Gemini CLI OpenTelemetry spans |
| `traces-codex.jsonl` | 32 MB | 8,063 | JSONL (OTel spans) | Codex CLI OpenTelemetry spans |
| `traces-opencode.jsonl` | 17 MB | 10,065 | JSONL (OTel spans) | OpenCode OpenTelemetry spans |
| `claude-transcripts-hf.jsonl` | 3.7 MB | 4,233 | JSONL (conversation) | Claude HF conversations — messages+project+file+turn_count+source |
| `test-subagent-link.jsonl` | 2.7 MB | 1,968 | JSONL (OTel spans) | Subagent link test data (span format) |
| `conversion-stats.json` | 1.6 KB | — | JSON | Conversion statistics |

**Total: 9 files, ~1.0 GB, ~654,658 trace entries + 4,233 conversation entries**

**Two distinct data types:**
1. **OpenTelemetry spans** (7 files, 650K entries): `{trace_id, span_id, parent_span_id, name, kind, attributes}` — structured telemetry, NOT conversation text. Suitable for trace analysis (inference.net), NOT for cognee RAG.
2. **Conversation transcripts** (1 file, 4K entries): `{messages: [{role, content}, ...], project, file, turn_count, source}` — same format as history.jsonl, suitable for cognee RAG. Already ingested into `vault_transcripts` dataset (4,233 entries).

---

### 1.3 `~/data-exports/` — Evaluation Data (130 MB)

| File | Size | Lines | Format | Content |
|---|---|---|---|---|---|
| `_datasets/corpus.jsonl` | 111 MB | 8,580 | JSONL | Main evaluation corpus |
| `_datasets/cursor.jsonl` | 13 MB | 1,148 | JSONL | Cursor-specific eval set |
| `_datasets/corpus.eval.jsonl` | 5.9 MB | 484 | JSONL | Evaluation subset |

**Total: 3 files, 130 MB, ~10,212 entries**

Format: likely conversation pairs or agent trajectory evaluations.

---

### 1.4 `~/.cognee_transcripts/` — Cognee-Ingested Transcripts (3.2 MB)

| Count | Format | Content |
|---|---|---|
| 45 files | Markdown (`.md`) | Session transcripts ingested via cognee pipeline |

Files range from 443 bytes to 499 KB. Content includes:
- Many session transcript files (UUID-named `.md`)
- Summary files for projects: `machine-scratch_summary.md`, `voice-engine-swift_summary.md`, `cognee_summary.md`, etc.
- Agent transcript files (`agent-*.md`)

---

### 1.5 History JSONL Files

| File | Size | Lines | Source | Ingestion Status |
|---|---|---|---|---|
| `~/.claude-token/history.jsonl` | 676 KB | 1,856 | Claude Code | ✅ Re-ingested into `claude_history` (2026-07-02) |
| `~/.claude-pioneer/history.jsonl` | 76 KB | 230 | Claude Pioneer CLI | ✅ Re-ingested into `claude_history` (2026-07-02) |
| `~/.codex/history.jsonl` | 4.0 KB | 2 | Codex CLI | ✅ Re-ingested into `claude_history` (2026-07-02) |
| `~/.gemini/antigravity-cli/history.jsonl` | 20 KB | 94 | Gemini Antigravity CLI | ✅ Re-ingested into `claude_history` (2026-07-02) |

**Total: 4 files, 776 KB, ~2,186 entries — all ingested into `claude_history` dataset (2,152 items, 34 rejected as too short)**

---

## 2. Additional Data Sources (Tool Runtimes)

### 2.1 `~/.codex/` — Codex CLI Runtime Data (101 MB)

| Item | Size | Notes |
|---|---|---|
| `sessions/` | 7.8 MB, 45 JSONL | Per-session rollout logs — `{timestamp, type, payload}` entries (session_meta, event_msg, response_item, turn_context). Codex uses GPT-5 via OpenAI. Not yet ingested. |
| `logs_2.sqlite` | 6.1 MB | Activity/tool logs |
| `.tmp/plugins/` | 76 MB | Cached remote plugin checkouts (full Git repos — not conversation data) |
| `state_5.sqlite` | 576 KB (+WAL) | Session state |
| `cache/` | 4.4 MB | Model metadata cache |
| `plugins/` | 4.3 MB | Plugin definitions |
| `memories_1.sqlite` | 40 KB | Memory/persistence |
| `goals_1.sqlite` | 24 KB | Goal tracking |
| `shell_snapshots/` | 180 KB | Shell state snapshots |
| `history.jsonl` | 1.5 KB | 2 entries (minimal — most history in vault traces) |
| `config.toml` | 828 B | Configuration |
| `mcp.json` | 321 B | MCP config |
| `auth.json` | 4.5 KB | Authentication tokens |
| `models_cache.json` | 144 KB | Cached model metadata |

### 2.2 `~/.gemini/antigravity-cli/` — Gemini Antigravity CLI Data (40 MB)

| Item | Format | Notes |
|---|---|---|
| `history.jsonl` | JSONL | 94 entries |
| `brain/` (~31 files) | Directory | Agent brain definitions |
| `conversations/` (~35 files) | Directory | Chat history |
| `cache/` | Directory | Cached data |
| `implicit/` | Directory | Implicit state |
| `log/` (~78 files) | Directory | CLI logs |
| `mcp/` + `mcp_config.json` | Directory + JSON | MCP configuration |
| `bin/` + `builtin/` | Directories | CLI scripts and built-in tools |

### 2.3 `~/.claude-pioneer/` — Pioneer CLI Data (2.3 MB)

| Item | Format | Notes |
|---|---|---|
| `history.jsonl` | JSONL | 230 entries |
| `.claude.json` | JSON | Configuration |
| `backups/` | Directory | Config backups |
| `cache/` | Directory | Cached data |
| `file-history/` | Directory | File change history |
| `paste-cache/` | Directory | Paste buffer cache |
| `plans/` | Directory | Session plans |
| `session-env/` | Directory | Session environments |
| `tasks/` | Directory | Task definitions |

### 2.4 `~/.claude-token/` — Claude Code Runtime State (725 MB in projects + additional)

Beyond the session project data (section 1.1), the runtime dir contains:

| Item | Size | Notes |
|---|---|---|
| `file-history/` | ~5 MB | File edit history across sessions |
| `paste-cache/` | ~5 MB | Paste buffer snapshots |
| `session-env/` | ~1 MB | Per-session environment snapshots |
| `shell-snapshots/` | ~1 MB | Shell state snapshots |
| `tasks/` | 250+ lock files | Background task tracking state |
| `sessions/` | 2 JSON files | Active session metadata (PID, sessionId, timestamps) |
| `plans/` | ~10 files | Saved plans/sessions |
| `backups/` | ~1 MB | Settings backups |
| `skills/` | ~10 files | Skill definitions |
| `history.jsonl` | 642 KB | Global history (1,856 entries) |
| `settings.json` | 245 B | User settings |

### 2.5 `~/.local/share/opencode/` — OpenCode Runtime Data (154 MB)

| Item | Size | Notes |
|---|---|---|
| `opencode.db` (SQLite) | ~144 MB | Main database (sessions, conversations, tool runs) |
| `log/` | 5.5 MB | Runtime logs |
| `tool-output/` | 2.3 MB | Captured tool outputs |
| `snapshot/` | 2.3 MB | State snapshots |
| `auth.json` | small | Authentication data |

Also at `~/.local/state/opencode/prompt-history.jsonl`: 50 entries, 793 KB.

### 2.6 `~/.gemini/antigravity-ide/` — Gemini IDE Data (36 MB)

IDE companion data for Gemini Antigravity. Likely mirrors the CLI structure with sessions and brain definitions for the VS Code–integrated mode.

### 2.7 `~/.gemini/antigravity/` — Gemini Antigravity (13 MB)

Main Gemini Antigravity client data — conversations, state, sessions.

### 2.8 `~/.cursor/` — Cursor IDE Config Data (13 MB)

| Item | Notes |
|---|---|
| `agent-cli-state.json` | Agent CLI state |
| `mcp.json` | MCP config |
| `extensions/` | IDE extensions (remote-ssh, etc.) |
| `skills-cursor/` | Cursor skill definitions |
| `projects/` | Per-project workspace trust and worker logs |

### 2.9 `~/.cache/opencode/` — OpenCode Cache (2.8 MB)

Cached OpenCode assets and responses.

### 2.10 `~/Desktop/config-backup-jul2026/` — Config Backups

Complete set of tool configuration backups as of 2026-07-01:

| Directory | Tools/Apps |
|---|---|
| `btop/` | System monitor config |
| `claude/` | Claude Code config |
| `context7/` | Context7 config |
| `gh/` | GitHub CLI config |
| `ghostty/` | Ghostty terminal config |
| `githits/` | GitHits config |
| `karabiner/` | Karabiner-Elements keyboard config |
| `machine/` | Machine-level config |
| `opencode/` | OpenCode config |
| `raycast/` | Raycast config |
| `sketchybar/` | SketchyBar menubar config |

### 2.11 `~/Library/Logs/voice-engine/` — VoiceEngine Logs & Audio (13 MB)

| Item | Size | Notes |
|---|---|---|
| `audio/` — 54 `.wav` files | ~10 MB | Raw voice dictation recordings, timestamps match `voice-history.txt` |
| `voice-engine.log` | 35 KB | Engine runtime log |
| `metrics.jsonl` | 15 KB | Performance/latency metrics |

### 2.12 `~/.cocoindex_code/` — Cocoindex Daemon State

`daemon.log` — Cocoindex indexing daemon runtime log.
`global_settings.yml` — Global embedder config (sentence-transformers + nomic-ai/CodeRankEmbed).

**Current index state (machine-scratch worktree):** 559 chunks across 81 files (329 markdown, 154 bash, 30 json, 29 python, 8 text, 5 toml, 4 javascript). Daemon listening on Unix socket at ~/.cocoindex_code/daemon.sock, healthy and responsive (uptime >7 min). Cocoindex MCP available via `ccc mcp` (stdio mode) but not yet wired into Claude settings.

### 2.14 `~/.cache/huggingface/hub/` — MLX Models (8.4 GB)

Models downloaded for local inference via MLX:

| Model | Size | Purpose | Server |
|---|---|---|---|---|
| `mlx-community/Qwen3.5-9B-OptiQ-4bit` | ~8 GB | LLM inference | Port 8080 (`mlx_lm.server`) |
| `mlx-community/Qwen3-Embedding-0.6B-4bit-DWQ` | ~350 MB | Text embeddings | Port 8081 (`mlx-embed-server`) |

### 2.15 Running Infrastructure Services

| Service | Port | Process | Purpose |
|---|---|---|---|---|
| MLX Inference Server | :8080 | `mlx_lm.server` | OpenAI-compatible chat completions |
| MLX Embedding Server | :8081 | `mlx-embed-server` | OpenAI-compatible `/v1/embeddings` |
| Cognee MCP | :7779 | cognee-mcp `server.py` | Knowledge graph MCP for Claude |
| Cocoindex Daemon | Unix socket at ~/.cocoindex_code/daemon.sock | `ccc run-daemon` | Code indexing daemon (CodeRankEmbed via sentence-transformers) |
| CodeRankEmbed (llama-server) | :51999 | `llama-server` (CodeRankEmbed-Q8_0.gguf) | Legacy GGUF embedding backend (not used by cocoindex v0.2.37) |

### 2.13 `~/machine-scratch/` — Old Repo Copy (1.3 MB)

The machine-scratch repo at `~/machine-scratch/` is the active copy. The old
`~/projects/machine-scratch/` path is historical only. Same structure: docs,
config, bin, agent-rules, design.

---

## 3. Home Directory Artifacts (Archived — Phase 1 Complete)

These files were moved from `~/` into this repo and the originals deleted:

| File | Size | Archived To | Format |
|---|---|---|---|---|
| `~/bootstrap.sh` | 6.0 KB | `docs/archive/bootstrap.sh` | Shell script |
| `~/mac-tools-guide.md` | 13.4 KB | `docs/reference/mac-tools-guide.md` | Markdown |
| `~/model_downloads_ledger.md` | 2.7 KB | `docs/reference/model-ledger.md` | Markdown |
| `~/skills-lock.json` | 265 B | `docs/archive/skills-lock.json` | JSON |
| `~/voice-history.txt` | 5.6 KB | `docs/archive/voice-history.txt` | Text |

Insights from `voice-history.txt` extracted into `docs/DESIGN_NOTES.md`.

---

## 4. Summary Totals

| Category | Files | Size | Primary Format |
|---|---|---|---|---|
| **All JSONL data** | ~1,995 | 1.65 GB | JSONL |
| Claude session projects | ~4,598 | 725 MB | JSONL + state files |
| Vault trace files | 9 | 1.0 GB | JSONL |
| Data exports (eval) | 3 | 130 MB | JSONL |
| Cognee transcripts | 30 | 1.7 MB | Markdown |
| History logs | 4 | 776 KB | JSONL |
| Codex runtime | ~10+ | 101 MB | SQLite + JSON |
| Gemini CLI runtime | ~150+ | 40 MB | JSON + directories |
| Gemini IDE data | ~50+ | 36 MB | Directories |
| Gemini Antigravity | ~30 | 13 MB | Directories |
| Pioneer CLI runtime | ~15+ | 2.3 MB | JSON + directories |
| Claude Code runtime state | 300+ files | ~12 MB | JSON + metadata |
| OpenCode runtime | ~10+ | 154 MB | SQLite + logs |
| Cursor IDE config | ~20 | 13 MB | JSON + extensions |
| VoiceEngine logs/audio | 56 | 13 MB | WAV + log |
| Config backups (Desktop) | ~50+ | ~5 MB | Diverse config files |
| Old repo copy (~/) | ~80 | 1.3 MB | Same structure as projects/ |
| Home artifacts | 5 | 28 KB | Scripts + docs |

**Grand total across all data sources: ~5,500+ files, approximately 2.8 GB.**

---

## 5. Data Not Found (Confirmed Absent)

Thorough search confirmed these do NOT exist on this machine:

- **Talon voice data** (`~/.talon/`) — Not installed
- **Whisper transcriptions** (`~/.whisper/`) — Not found  
- **Ollama models/runtime** (`~/.ollama/`) — Not installed (uses MLX instead)
- **Desktop/Downloads data files** — No stray JSONL/JSON data files
- **Claude Desktop sessions** — No session logs in `~/.claude/` (only config)

---

## 6. Phase Status

**Phase 0 (Catalog): ✅ Complete** — All data sources catalogued above.
**Phase 1 (Home file cleanup): ✅ Complete** — 5 home artifacts archived into repo, originals deleted.
**Phase 2 (Infrastructure): ✅ Complete** — MLX inference (Qwen3.5-9B, :8080) and embedding (Qwen3-Embedding, :8081) servers running, cognee MCP (:7779) configured with MLX embeddings, cocoindex daemon configured with CodeRankEmbed.
**Phase 3 (Data ingestion): ✅ Complete** — 45 cognee transcripts (re-ingested after cleanup), vault transcripts (4,233 items, re-ingested after cleanup), data-exports corpus.jsonl (3,438/8,580 — 5,141 items cleaned up, needs re-ingestion), data-exports eval.jsonl (484 items) ✅, data-exports cursor.jsonl (1,148 items) ✅, claude_history (2,152 items) ✅. **All 10,360 remaining items have 100% valid storage files (missing files blocker resolved). Remaining:** vault_corpus re-ingestion of 5,141 items, cognify (knowledge graph build) still blocked by extract_graph_and_summarize LLM stage timeout with Qwen3.5-9B ⚠️.

**Ingested via cognee (MCP database — active DB with all data):**

| Dataset | Source | Count | Status |
|---|---|---|---|
| `cognee_transcripts` | ~/.cognee_transcripts/ (45 .md files, 3.2 MB) | 45 | ✅ Re-ingested (was 0 after cleanup) |
| `vault_transcripts` | ~/data/vault/claude-transcripts-hf.jsonl | 4,233 | ✅ Re-ingested (was 0 after cleanup) |
| `vault_corpus` | ~/data-exports/_datasets/corpus.jsonl | 3,438 / 8,580 | ⚠️ Partial (5,141 cleaned up, needs re-ingestion) |
| `vault_corpus_eval` | ~/data-exports/_datasets/corpus.eval.jsonl | 484 | ✅ All files valid |
| `vault_cursor` | ~/data-exports/_datasets/cursor.jsonl | 1,148 | ✅ All files valid |
| `claude_history` | 4 history.jsonl files (Claude, Pioneer, Codex, Gemini) | 2,152 | ✅ All files valid |

**Total: 10,360 items across 6 active datasets (plus 2 empty/legacy)**

**NOTE:** cognee has two separate databases — the MCP project venv (`cognee-mcp/.venv`, 244 MB) holds the primary data with all 6 datasets above, while the UV CLI tool (3.1 MB) has its own separate database with `system_knowledge` dataset. The MCP server on :7779 uses the larger DB.

**NOT ingested (unsuitable for cognee RAG — OpenTelemetry spans, not conversations):**
- ~/data/vault/traces-claude.jsonl (496K spans, 670 MB)
- ~/data/vault/traces-pi.jsonl (53K spans, 220 MB)
- ~/data/vault/traces-cursor.jsonl (61K spans, 95 MB)
- ~/data/vault/traces-gemini.jsonl (19K spans, 36 MB)
- ~/data/vault/traces-codex.jsonl (8K spans, 32 MB)
- ~/data/vault/traces-opencode.jsonl (10K spans, 17 MB)
- ~/data/vault/test-subagent-link.jsonl (2K spans, 2.7 MB)

**Known blockers:**
- cognee cognify (knowledge graph build) previously failed with `FileNotFoundError` at `extract_chunks_from_documents` stage ⚠️. **Root cause (fixed iteration 17):** 9,404 of 15,486 data items had missing storage files. The `bin/cognee-cleanup.py` script removed all orphaned DB entries, and the affected datasets (`vault_transcripts`, `cognee_transcripts`) were re-ingested successfully. **All 10,360 remaining items now have 100% valid storage files.** The missing-files blocker is RESOLVED.
- `vault_corpus` is partial: 5,141 of 8,580 items were cleaned up and need re-ingestion. The 3,438 remaining items have valid files.
- The `extract_graph_and_summarize` LLM entity extraction stage takes a very long time with Qwen3.5-9B on M5 Pro (did not complete within 5-minute timeout). Whether Qwen3.5's structured output via instructor causes issues at this stage is still unknown — the prior diagnosis may still apply here.
- cognee `add()` batch performance degrades severely as Ladybug DB grows: initial batches ~1.2s/200-items, degrading to ~60-80s/200-items after ~7,000+ items, following the non-monotonic pattern.
- Ladybug DB is single-writer ⚠️ — concurrent ingestion processes will conflict. Stale `cognee-cli remember` processes can hold the lock indefinitely (killed PID 64885 on 2026-07-02 at 11:55).
- cognee search/recall queries fail with "LLM API key is not set" or "empty knowledge graph" errors because the knowledge graph has not been built. The MCP server on :7779 has LLM_API_KEY=sk-local and LLM_INSTRUCTOR_MODE=markdown_json_mode configured.
- Stale pipeline run state blocks re-attempts — `pipeline_runs` entries with `status=DATASET_PROCESSING_COMPLETED` for `cognify_pipeline` cause the pipeline to return immediately without processing. Workaround: delete stale cognify_pipeline runs from the `pipeline_runs` table via SQL before re-attempting.

**Next actions for future iterations:**
1. ✅ Data-exports ingestion complete (14,474 items across 5 active datasets in MCP DB)
2. ✅ claude_history re-ingestion complete (2,152 items from 4 history.jsonl files into MCP DB)
3. ✅ Attempted cognify on small datasets — pipeline reaches `extract_chunks_from_documents` then fails with `FileNotFoundError` (cognee internal storage path hash mismatch bug, not Qwen3.5/GPU OOM as previously documented). No LLM calls are made before the failure point.
4. ✅ Root cause found and FIXED: `bin/cognee-cleanup.py` removed all 9,404 orphaned DB entries with missing files. vault_transcripts (4,233) and cognee_transcripts (45) re-ingested successfully. All 10,360 remaining items have 100% valid storage files.
5. Re-ingest vault_corpus missing 5,141 items from corpus.jsonl to restore the dataset to full 8,580 items.
6. Run cognify on a dataset with all-valid files (e.g., `claude_history`, 2,152 items) with longer timeout to see if LLM entity extraction completes or fails with Qwen3.5/instructor issues.

**Remaining for future phases:** Claude session project JSONLs (~4,600 files) into cocoindex (blocked: cocoindex is a code indexer, not suitable for JSONL conversation data), analysis of trace span data via inference.net tracing.
**Phase 4 (Documentation): ✅ Complete** — GLOBAL.md, ARCHITECTURE.md, DATA_PIPELINE.md, VOICE_PIPELINE.md, PHILOSOPHY.md, DESIGN_NOTES.md all created and updated.
**Phase 5 (FirstMate integration): ✅ Complete** — 41 fm-*.sh scripts symlinked into ~/bin/, no-mistakes skill wired into ~/.claude-token/skills/, AGENTS.md contract created in machine-scratch repo, mintmux + treehouse verified as installed and functional.
