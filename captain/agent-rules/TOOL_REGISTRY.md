# Tool Registry

Source of truth: `~/.agent-rules/`.
Vendor harness schemas: `ctx7 docs` — see `docs/vendor/agent-harnesses/llms.txt`.

## Status Key

- **ACTIVE** — installed and on PATH; use by default.
- **PLANNED** — approved after review; use fallback until installed.

## The Stack (use in order)

| Tool | Status | What it does | Agent-facing use |
|---|---|---|---|
| `llm-tldr` | ACTIVE | Structure/arch/search on local code | Before opening many files |
| `fastedit` | ACTIVE | AST-aware file edits | `edit`/`rename` need `tldr references` (tldr-code dispatcher) |
| `jq` / `yq` | ACTIVE | Structured data | Direct bash OK |
| `du -s` / `du -sh` | ACTIVE | Parseable disk usage | Direct bash OK — not `dust` |
| `lavish-axi` | ACTIVE | Human review surface for HTML artifacts | When agent ships review artifacts |
| `chrome-devtools-axi` | ACTIVE | Browser automation | UI testing / scraping |
| `ctx7` | ACTIVE | Context7 library docs lookup + `find-docs` skill | Library docs / API references |
| `cognee-cli` | ACTIVE | Graph-based session memory | Cross-session memory |
| `cocoindex-code` / `ccc` | ACTIVE | Incremental code indexing | Build code indexes |
| `treehouse` | ACTIVE | Pool of reusable git worktrees | Parallel agents on one repo |
| `githits` | ACTIVE | Indexed search/grep/read across open-source code (CLI, no MCP) | Real-world code examples, dependency source |
| `inf` (inference.net) | ACTIVE | Catalyst gateway/tracing/evals/training | Observability + fine-tuning workflow |
| `pioneer` (fastino) | ACTIVE | Pioneer datasets/training/inference | SLM fine-tuning, NER, GLiNER |
| `bun` | INFRA | Runtime for Pioneer CLI | Don't call directly |
| `gtimeout` / `timeout` | ACTIVE | Bound long-running live smoke tests | Use only around tests/agent probes |
| `githits-axi`, `coco-axi`, `cognee-axi` | UNVERIFIED | Not found in public registries | Use base tools |

## Skills installed (`~/.agents/skills/`)

| Skill | Source | When it triggers |
|---|---|---|
| `find-docs` | `ctx7 setup --cli --opencode` (Context7) | Any library/framework/SDK/cloud-service docs question |
| `tool-policy` | House skill, `skills/tool-policy/` | Tool policy edits, hook debugging, harness verify |
| `pioneer-api` | House skill, symlinked from `skills/pioneer-api/` (content copied from Pioneer's official `guides/agent-skills.md`) | Pioneer dataset/training/eval/inference work |
| `inference-net` | House skill, symlinked from `skills/inference-net/` | Catalyst gateway/tracing, HALO, `inf` CLI work |

## Launchers

| Command | Tool | Secrets | Purpose |
|---|---|---|---|
| `c` | Claude Code | OAuth account | Primary Claude Code launcher |
| `ct` | Claude Code | TokenRouter key | Claude via TokenRouter |
| `ca` | Claude Code | OAuth account | Compatibility alias; prefer `c` |
| `oo` | OpenCode | ChatGPT Plus OAuth | GPT 5.5 fast via OpenAI provider |
| `ot` | OpenCode | TokenRouter key | Default cheap TokenRouter |
| `op` | OpenCode | Pioneer key | Pioneer provider |
| `cx` | Codex | None (yet) | Codex CLI |
| `cu` | Cursor Agent | None (Cursor auth) | Cursor agent CLI |
| `agy` | Antigravity | None (own auth) | Antigravity CLI |
| `ko` | Kilo | ChatGPT Plus OAuth | Kilo via OpenAI provider |
| `kt` | Kilo | TokenRouter key | Kilo via TokenRouter |
```bash

# du — parseable disk usage (dust is for humans, denied for agents)
du -s path
du -sh path

jq '.key' file.json
yq '.key' file.yaml

# gtimeout / timeout — direct OK only to bound live tests or agent probes
```

## Writes and Confirmations

Always confirm before:
- Destructive git ops (force-push, branch delete, PR close)
- Paid or external compute runs
- Bulk writes to Drive, Linear, Notion, or similar
| Blocked | Use instead |
|---|---|
| `dust`, bare `du` | `du -s` or `du -sh` |

| `export` | `secret-cache exec -- <command>` |
| `rm`, `sudo`, `security` | ask the captain |

GNU coreutils are installed for `gtimeout`; do not use GNU aliases like `gcat`, `gls`, `ggrep`, or `gfind` to bypass policy. The allowed GNU tool is `gtimeout` for bounding tests.
