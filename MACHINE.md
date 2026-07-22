# Machine Manifest

Single source of truth for everything installed on this machine. If it's not
declared here or in `configuration.nix`/`home.nix`, it doesn't survive a rebuild.

Status key: **OK** = declared + working. **GAP** = works but not declared.
**STALE** = declared but doesn't match reality.

## Homebrew (`configuration.nix` brews/casks)

40 brews + 13 casks. `homebrew.onActivation.cleanup = "zap"` auto-removes
anything not declared here. Run `brew list` for live state, not this file.

## npm globals (declared via `home.activation.npmGlobalTools`)

| package | purpose |
|---|---|
| @anthropic-ai/claude-code | `ca` / `ct` CLI |
| @openai/codex | `codex` CLI |
| command-code | `cmd` CLI — web search + general tasks |
| gh-axi | GitHub operations |
| githits | code search |
| chrome-devtools-axi | browser automation |
| lavish-axi | review surfaces |
| tasks-axi | task management |
| @inference/cli | observability |
| gnhf | agent loops |

## Python (uv-managed via `home.activation.uvTools`)

| tool | purpose |
|---|---|
| mlx-lm | local chat server (:8080) |
| cocoindex | semantic code indexing |
| cocoindex-code (`ccc`) | cocoindex CLI |
| llm-tldr | code structure, call graphs |
| z3-solver | formal verification (bridge) |

## ML Models (`~/.cache/huggingface/hub/`, ~68 GB)

| Model | Consumer | Purpose |
|---|---|---|
| LiquidAI/LFM2.5-8B-A1B-MLX-4bit | mlx-chat :8080 | primary local chat |
| LiquidAI/LFM2.5-230M-MLX-bf16 | background tasks | fast auxiliary reasoning |
| openbmb/MiniCPM5-1B | fallback | edge reasoning |
| Qwen3-Embedding-0.6B-Q8_0 (GGUF) | llama-server :8081 | general embeddings |
| CodeRankEmbed-Q8_0 (GGUF) | llama-server :8082 | code embeddings (CocoIndex) |
| urchade/gliner_* | bridge build_kg.py | entity extraction (legacy Ladybug path; frozen) |
| microsoft/deberta-v3-* | bridge | zero-shot classification |
| moonshine*, parakeet-rnnt | voice-engine-swift | dictation ASR |
| kompress-v2-base | voice-engine-swift | prompt compression |

## Vector Databases + Knowledge Graphs

| Store | Location | Size / role |
|---|---|---|
| **Neo4j (sole store)** | `neo4j://localhost:7687` (Homebrew `brew services`) | Live: ~2183 Axiom, ~3153 Chunk, + File/CodeSymbol (parity in progress). Portfolio ADR: `portfolio/wayfinder/neo4j-sole-store.md` |
| CocoIndex state | `~/projects/knowledge-engine/cocoindex.db` + `~/.local/share/cocoindex/` | Pipeline bookkeeping / per-project indices — **not** the knowledge graph |
| LadybugDB (frozen) | `~/projects/bridge/.bridge/ladybug/bridge-knowledge` | ~6.75GB migration source only; writers disabled |
| Headroom | `~/projects/voice-engine-swift/.headroom/` | voice history vectors |

## Minimum Repos (clone from `jwalin-shah` GitHub)

| repo | purpose | build |
|---|---|---|
| dotfiles | machine config, rebuild, LaunchAgents | `./rebuild.sh` |
| bridge | orchestrator: spawn, verify, quota, orbit | `go build ./cmd/bridge` |
| mintmux | PTY multiplexer (bridge depends on it) | `go build ./cmd/...` |
| portfolio | control plane: decisions, maps, contracts | markdown |
| inbox | daily driver: email, messages, calendar | `uv run python inbox.py` |
| m5tools | M5 hardware monitoring daemons | `make install` |
| voice-engine-swift | dictation menubar app | `swift build` |

Other repos (btw-v1, tensor-logic, ApplyPilot, collections-guide, rust-collections)
are cloned as needed.

## LaunchAgents (`configuration.nix` — `launchctl list | grep org.nixos`)

| Service | Port | What |
|---|---|---|
| llama-embed-server | :8081 | Qwen3 0.6B embeddings |
| coderank-embed-server | :8082 | CodeRank code embeddings |
| mlx-chat-daemon | :8080 | liquid LFM2.5 8B chat |
| tldr-daemon | — | code structure auto-index |
| cocoindex-daemon | — | semantic code indexing |
| knowledge-engine | — | axiom/source/code → Neo4j pipeline |
| neo4j | :7687 | sole knowledge store — Homebrew `brew services` (not a nix LaunchAgent) |
| mintmux | — | PTY multiplexer |
| m5logd | — | M5 hardware logging |
| voice-engine | — | dictation menubar app (KV-cache decoder; re-enabled 2026-07-21) |

Ladybug pipeline LaunchAgent is **frozen** — Neo4j is the sole knowledge store.
The LadybugDB file under `bridge/.bridge/ladybug/` is retained read-only for migration.

## Agent Configs

| Agent | Config files | Managed? |
|---|---|---|
| ca (Claude direct) | `~/.claude/settings.json`, `settings.local.json` | nix symlink |
| ct (TokenRouter) | `~/.claude-token/` (shares ca settings) | nix symlink |
| codex | `~/.codex/config.toml`, `hooks.json`, `rules/` | nix symlink |
| cursor-agent | `~/.cursor/cli-config.json`, `hooks.json`, `mcp.json` | nix symlink (force) |
| agy (Gemini) | `~/.gemini/antigravity-cli/settings.json`, `settings.json` | nix symlink (force) |
| cmd (CommandCode) | self-managed | not in dotfiles |

## Not yet in nix (GAPs)

- `~/.local/bin/jw` — FirstMate binary. Dead project, binary still on PATH.
- `~/.local/bin/jw-heal` — dead health checker. LaunchAgent removed Jul 18.

*Last updated: July 18, 2026 — merged MODELS.md, removed dead references
(@kilocode/cli, ctx7, firstmate, treehouse, jw-desk, research-bridge, cognee),
updated npm list, added ML models, added minimum repos.*

## Cross-Repo Dependency Manifest (deps.json) & Neo4j

These are tracked by each project's `wayfinder/deps.json` (validated by
`bin/check-stale`) and are fully integrated into dotfiles:

- `bridge/knowledge/` Go package queries Neo4j at context assembly time
- `neo4j-go-driver/v5` depends on Neo4j :7687 being reachable
- knowledge-engine pipeline must run BEFORE bridge context assembly
  (data must exist in Neo4j before bridge queries it)
- Embedding servers (:8081/:8082) must be running for pipeline operations
- Bridge audit workflow depends on knowledge engine data being current
