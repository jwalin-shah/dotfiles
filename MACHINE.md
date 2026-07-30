# Machine Manifest

Single source of truth for everything installed on this machine. If it's not
declared here or in `configuration.nix`/`home.nix`, it doesn't survive a rebuild.

**How pieces connect (Orbit → Bridge → HomeBase → KE → Seatbelt):** see
[`docs/SYSTEM_MAP.md`](docs/SYSTEM_MAP.md). Portfolio living map:
`~/projects/portfolio/wayfinder/one-surface-system-2026-07-30/map.md`.

**Freshness gate:** `bin/prove-docs-freshness.sh` (also via `prove-launchers.sh`).
Update this file in the same change as any LaunchAgent / PATH / PARKED edit.

Status key: **OK** = declared + working. **GAP** = works but not declared.
**STALE** = declared but doesn't match reality.

## Homebrew (`configuration.nix` brews/casks)

41 brews + 13 casks. `homebrew.onActivation.cleanup = "zap"` auto-removes
anything not declared here. Run `brew list` for live state, not this file.

## Agent toolchain (exact pins in `config/agent-toolchain.tsv`)

| package | purpose |
|---|---|
| @earendil-works/pi-coding-agent | `pi` interactive cockpit; `pi-cockpit` hosts it in Mintmux |
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

`firectl` is a Homebrew-managed Fireworks account/quota CLI. It is declared in
`configuration.nix` and is intentionally not part of the npm/uv exact-version
receipt.

Formal proof tool ownership and the no-duplicate rule are recorded in
`docs/FORMAL_TOOLCHAIN.md`.

Neovim's current Treesitter plugin compiles parsers with the Home Manager
`tree-sitter` package (requires CLI 0.26.1 or newer; pinned Nixpkgs provides
0.26.9).

## Python (uv-managed by the same exact-version receipt)

| tool | purpose |
|---|---|
| mlx-lm | **PARKED** 2026-07-23 — was local chat (:8080); Neo4j+embeds only now. See `wayfinder/mlx-chat-parked-2026-07-23.md` |
| cocoindex | semantic code indexing |
| cocoindex-code (`ccc`) | optional CLI only — daemon LaunchAgent removed 2026-07-22; Neo4j is SoT |
| llm-tldr | code structure, call graphs |
| z3-solver | formal verification (bridge) |

## ML Models (`~/.cache/huggingface/hub/`, ~68 GB)

| Model | Consumer | Purpose |
|---|---|---|
| LiquidAI/LFM2.5-8B-A1B-MLX-4bit | **PARKED** (was mlx-chat :8080) | was primary local chat — daemon off 2026-07-23 |
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
| dotfiles | machine constitution, rebuild, LaunchAgents, proves | `./rebuild.sh` |
| orbit | captain CLI (thin shell over bridge-serve) | `go build ./cmd/orbit` |
| bridge | spawn / verify / deliver / ledger / Seatbelt | `go build ./cmd/bridge` |
| homebase | grant admission + receipts (**required for live spawn**) | see homebase AGENTS |
| mintmux | PTY multiplexer (bridge depends on it) | `go build ./cmd/...` |
| knowledge-engine | Neo4j pipelines (dumb pipe) | `./scripts/check.sh` |
| axioms | principle corpus → KE | data repo |
| portfolio | decisions / Wayfinder maps | markdown |
| trajectory | transcript normalize + claims evidence | `bun run check` |
| running-machine-contracts | joint schemas / conformance | `python3 fixtures/check_conformance.py` |
| inbox | daily driver: email, messages, calendar | `uv run python inbox.py` |
| m5tools | M5 hardware monitoring daemons | `make install` |
| voice-engine-swift | dictation menubar app | `swift build` |

Other repos (btw-v1, tensor-logic, ApplyPilot, collections-guide, rust-collections)
are cloned as needed.

## Agent skills (`.agents/` → Claude/Codex/Cursor on rebuild)

Source of truth: `dotfiles/.agents/` (not invent-in-chat). Required set proved by
`bin/prove-skills.sh`: preflight, wayfinder, grill-me, domain-modeling,
codebase-design, setup-matt-pocock-skills, research, prototype, code-review,
plus cocoindex / worktree-manager.

Durable projection into `~/.claude/skills` etc. needs `./rebuild.sh` (Tier 3).

## Isolation + HomeBase (spawn gates)

| Gate | Live rule |
|---|---|
| Seatbelt | `seatbelt-compat` write deny-default; **not** production confidentiality |
| Production | requires certified `vm` (or apple-container path) — VM backend **not** certified yet |
| Local drive only | `BRIDGE_ALLOW_UNSAFE_LOCAL_MODE=1` + `BRIDGE_ISOLATION_MODE=seatbelt-compat` |
| HomeBase | `BRIDGE_HOMEBASE_URL` + bridge private key + admission public key — **required** or spawn fails after pre_spawn |

Do not document “spawn just works” without those gates. See `docs/SYSTEM_MAP.md`.

## LaunchAgents (`configuration.nix` — `launchctl list | grep org.nixos`)

| Service | Port | What |
|---|---|---|
| llama-embed-server | :8081 | Qwen3 0.6B embeddings |
| coderank-embed-server | :8082 | CodeRank code embeddings |
| mlx-chat-daemon | :8080 | **PARKED** 2026-07-23 — do not re-enable without ticket; Neo4j sole-store uses :8081/:8082 only |
| tldr incremental cache | — | no LaunchAgent; edit hook marks changed file dirty, next `tldr calls` query patches only that file |
| cocoindex-daemon | — | **REMOVED** 2026-07-22 — do not re-enable as second sink |
| knowledge-engine | — | on-change + daily 03:15 catch-up → Neo4j |
| bridge-cdp-quota | — | CDP scrape → `~/.bridge/cdp-cache.json` every 6h |
| prove-launchers | — | PATH orbit/bridge, LaunchAgents, overnight PATH,/usr/sbin, **CDP offline prove**, **factory e2e schema prove** |
| **verify-machine** | — | daily 09:00 `bridge verify-machine` + `prove-launchers.sh` |
| factory-e2e | — | `wayfinder/factory-e2e-readiness-2026-07-23.md` + `prove-factory-e2e-scorecard.sh` |
| **bridge-serve** | :9100 / :9101 | Orbit HTTP + authenticated gRPC surface (`org.nixos.com.jwalinshah.bridge-serve`, KeepAlive). Token file owner: `~/.local/state/bridge/grpc-auth-token` (0600). Prove: `prove-launchers.sh`, `orbit status` |
| **overnight-harden** | — | every 15m prove+spawn (LaunchAgent); Cursor Layer A continuous ~5m while chat awake |
| neo4j | :7687 | sole knowledge store — Homebrew `brew services` (not a nix LaunchAgent) |
| mintmux | — | PTY multiplexer |
| m5logd | — | M5 hardware logging |
| voice-engine | — | dictation menubar app |
| inbox-server | :9849 | unified inbox API |

Ladybug pipeline LaunchAgent is **frozen** — Neo4j is the sole knowledge store.
The LadybugDB file under `bridge/.bridge/ladybug/` is retained read-only for migration.

Canonical inventory: `portfolio/wayfinder/launcher-inventory-2026-07-23.md`
Prove: `dotfiles/bin/prove-launchers.sh`

## Agent Configs

| Agent | Config files | Managed? |
|---|---|---|
| pi | `~/.pi/agent/settings.json`; auth remains runtime-owned | nix symlink for settings; `/login` owns auth |
| ca (Claude direct) | `~/.claude/settings.json`, `settings.local.json` | nix symlink |
| ca (OAuth lane) | `~/.claude-a/settings.json` — no routing (subscription auth) | nix symlink |
| ct (TokenRouter) | `~/.claude-token/settings.json` — own file; carries `ANTHROPIC_BASE_URL` + deepseek/kimi defaults + `apiKeyHelper` | nix symlink |
| pio (Pioneer) | `~/.claude-pioneer/settings.json` — own file; carries `ANTHROPIC_BASE_URL` + claude-sonnet-5/opus-5 defaults + `apiKeyHelper` | nix symlink |
| codex | `~/.codex/config.toml`, `hooks.json`, `rules/` | nix symlink |
| cursor-agent | `~/.cursor/cli-config.json`, `hooks.json`, `mcp.json` | nix symlink (force) |
| agy (Gemini) | `~/.gemini/antigravity-cli/settings.json`, `settings.json` | nix symlink (force) |
| cmd (CommandCode) | self-managed | **WAIVER** — not in dotfiles hooks |

**Lane stores are self-sufficient.** Each Claude store's own `settings.json`
carries its lane routing, so a bare `claude` launched with only
`CLAUDE_CONFIG_DIR` set (a detached supervisor pane inherits no other env)
routes exactly like `bin/ct-wrapper` / `bin/pio-wrapper`. Keys are never in the
repo: `apiKeyHelper` runs
`/usr/bin/security find-generic-password -a <ACCOUNT> -s bridge-secrets -w`
at request time — the same `bridge-secrets` Keychain service
`~/.local/lib/keychain.bash` reads. An explicit `ANTHROPIC_API_KEY` in the
environment still wins over `apiKeyHelper`, so the wrappers keep working
unchanged.

## Not yet in nix (GAPs / WAIVERS)

- `~/bin/chrome-ai-tools`, `chrome-main`, `chrome-third` — unmanaged wrappers (WAIVER).
- `cmd` — Homebrew npm tool; no mutation gate (WAIVER).
- `com.jwalinshah.reconcile-outcomes` — hand LaunchAgent, not in configuration.nix (WAIVER; separate job-application owner).
- `org.orbit.bridge-cdp-quota` — retired duplicate of the Nix-managed CDP quota agent; unloaded and archived under `~/Library/LaunchAgents/archive/` on 2026-07-29.

*Last updated: 2026-07-30 — SYSTEM_MAP, skills prove, HomeBase/isolation spawn gates, fleet repos, self-sufficient Claude lane stores (ct split from default; pioneer declared).*

## Cross-Repo Dependency Manifest (deps.json) & Neo4j

These are tracked by each project's `wayfinder/deps.json` (validated by
`bin/check-stale`) and are fully integrated into dotfiles:

- `bridge/knowledge/` Go package queries Neo4j at context assembly time
- `neo4j-go-driver/v5` depends on Neo4j :7687 being reachable
- knowledge-engine pipeline must run BEFORE bridge context assembly
  (data must exist in Neo4j before bridge queries it)
- Embedding servers (:8081/:8082) must be running for pipeline operations
- Bridge audit workflow depends on knowledge engine data being current
- Live spawn also requires HomeBase admission (see SYSTEM_MAP) — KE alone is not enough
