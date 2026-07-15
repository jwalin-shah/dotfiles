# Tool Registry

Source of truth: `~/.agent-rules/`. Live list: `ls ~/.agents/skills/`.
Vendor harness schemas: `ctx7 docs` — see `docs/vendor/agent-harnesses/llms.txt`.

## Status Key

- **ACTIVE** — installed and on PATH; use by default.
- **REMOVED** — decommissioned; do not reference or suggest installing.
- **UNVERIFIED** — not found in public registries; use the base tool instead.

## The Stack (use in order)

| Tool | Status | What it does | Agent-facing use |
|---|---|---|---|
| `llm-tldr` | ACTIVE | Structure/arch/search on local code | Before opening many files |
| `jq` / `yq` | ACTIVE | Structured data | Direct bash OK |
| `du -s` / `du -sh` | ACTIVE | Parseable disk usage | Direct bash OK, not `dust` |
| `lavish-axi` | ACTIVE | Human review surface for HTML artifacts | When agent ships review artifacts |
| `chrome-devtools-axi` | ACTIVE | Browser automation | UI testing / scraping |
| `ctx7` | ACTIVE | Context7 library docs lookup | Library docs / API references |
| `cognee-cli` | ACTIVE | Graph-based session memory | Cross-session memory |
| `cocoindex-code` / `ccc` | ACTIVE | Incremental code indexing | Build code indexes |
| `treehouse` | ACTIVE | Pool of reusable git worktrees | Parallel agents on one repo |
| `githits` | ACTIVE | Indexed search/grep/read across open-source code | Real-world code examples, dependency source |
| `inf` (inference.net) | ACTIVE | Catalyst gateway/tracing/evals/training | Observability + fine-tuning workflow |
| `gtimeout` / `timeout` | ACTIVE | Bound long-running live smoke tests | Use only around tests/agent probes |
| `gh-axi` | ACTIVE | GitHub CLI wrapper, alias `gha` | All GitHub operations, never bare `gh` |
| `chrome-devtools-axi` | ACTIVE | Browser automation, alias `cda` | |
| `lavish-axi` | ACTIVE | Review surfaces, alias `lva` | |
| `fastedit` | REMOVED | ~~AST-aware file edits~~ | Use standard Edit/Write instead |
| `pioneer` (fastino) | REMOVED | ~~SLM fine-tuning, NER, GLiNER~~ | Not on PATH. Fetcher wired in Bridge for quota tracking (fails open until reinstated). |
| `bun` | REMOVED | ~~Runtime for Pioneer CLI~~ | Only existed to support `pioneer`, same status |
| `githits-axi`, `coco-axi`, `cognee-axi` | UNVERIFIED | Not found in public registries | Use the deprecated-alias mapping above instead |

## Skills (`~/.agents/skills/`, 26 total)

All 26 nix-managed symlinks, verified 2026-07-14. 0 unmanaged directories.
5 `.backup` orphans cleaned up. Run `ls ~/.agents/skills/` for live list.

## Launchers

| Command | Tool | Auth | Routing (task → model) |
|---|---|---|---|
| `ca` | Claude Code | Account A OAuth | Heavy: Opus 4.8. Light: Haiku 4.5. |
| `ct` | Claude Code | TokenRouter | Heavy: deepseek-v4-pro. Medium: deepseek-v4-flash. Light: kimi-k2.7-code. |
| `cx` | Codex CLI | Codex/ChatGPT account | OpenAI models via ChatGPT Plus. |
| `oo` | OpenCode | ChatGPT Plus OAuth | gpt-5.5 for heavy work (profile `oo.json`). |
| `ot` | OpenCode | TokenRouter | deepseek-v4-flash for routine work (profile `ot.json`). |
| `ko` | Kilo | ChatGPT Plus OAuth | Kilo via OpenAI provider. |
| `kt` | Kilo | TokenRouter | Kilo via TokenRouter. |
| `cua` | Cursor Agent | Own auth | Cursor's built-in agent. |
| `agy` | Antigravity CLI | Own auth | |

Deprecated aliases: `githits-axi` -> `githits`, `coco-axi` -> `cocoindex-code`,
`cognee-axi` -> `cognee-cli`, `context7`/`c7` -> `ctx7`.

Read `~/.agent-rules/KNOWN_ISSUES.md` before any bash-heavy session.

## Blocked for agents (captain-only)

`rm`, `sudo`, `security` (ask the captain), `export` (use bridge secrets
adapter instead), GNU coreutils aliases like `gcat`/`gls`/`ggrep`/`gfind`
(bypass policy — the one allowed GNU tool is `gtimeout`).
