# overall agent instructions

`~/CLAUDE.md` has the machine constitution: hardware, approval gates,
verification requirements, escalation rules.

## Tool hierarchy

Use these in order, stop when the result is sufficient:

1. Structure first — `llm-tldr` before opening many files in an unfamiliar repo.
2. GitHub — `gh-axi`; fall back to narrow `gh` JSON queries only if unavailable.
3. Public code examples — `githits`.
4. Structured data edits — `jq` / `yq`.
5. Disk usage — `du -s` / `du -sh`, not `dust` (agent-facing restriction only;
   `dust` is fine for the captain to use interactively per `~/CLAUDE.md`).

Avoid raw `cat`, `ls`, `grep`, `find`, `git`, `gh` from agent shell unless a
task specifically requires exact native output.

## File mutation

Native harness write/edit tools (Edit, Write, apply_patch, etc.) are
allowed and preferred. `fastedit` is decommissioned — removed, not planned,
not coming back. Touch only files required by the task.

## Validation discipline

- Run the smallest test that proves the change works.
- For counters and hooks, prove wiring with before -> action -> after, not
  just static config.

## LLM coding behavior

- State assumptions before implementing.
- Ask when the request has multiple materially different interpretations.
- Implement the minimum code that solves the problem.
- Do not add speculative features or one-use abstractions.
- Do not revert user changes.

## Collaboration style

Be direct, concrete, and opinionated. Surface confusion instead of hiding it.

## Secret and provider policy

- Provider keys come from the Bridge secret adapter (`internal/secrets/` in bridge):
  `infisical export` → macOS Keychain → worker env. Never touch disk.
- `TOKENROUTER_API_KEY` is the only TokenRouter key name.
- Do not export provider keys globally or write them into shell startup files.
- Launchers read secrets from Keychain directly (`security find-generic-password -w`).
- `bridge secrets refresh` to reload from Infisical.
- If a required provider key is missing, fail hard — never silently skip.
- `secret-cache` is decommissioned. Bridge secrets replaces it.

## Launchers

Every entry is verified — a launcher listed here that doesn't exist on disk is a
config error. `config-lint` enforces this.

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

OAuth account A needs `/login` once in `~/.claude-a`. OpenCode global
config: `~/.config/opencode/opencode.json`; each launcher sets
`OPENCODE_CONFIG` to a profile overlay.

Deprecated aliases: `githits-axi` -> `githits`, `coco-axi` -> `cocoindex-code`,
`cognee-axi` -> `cognee-cli`, `context7`/`c7` -> `ctx7`.

Read `~/.agent-rules/KNOWN_ISSUES.md` before any bash-heavy session.

## Tool registry — live status

Status key: **ACTIVE** = installed and on PATH, use by default. **REMOVED**
= decommissioned, do not reference or suggest installing. **UNVERIFIED** =
not found in public registries, use the base tool instead.

| Tool | Status | What it does | Agent-facing use |
|---|---|---|---|
| `llm-tldr` | ACTIVE | Structure/arch/search on local code | Before opening many files |
| `jq` / `yq` | ACTIVE | Structured data | Direct bash OK |
| `du -s` / `du -sh` | ACTIVE | Parseable disk usage | Direct bash OK, not `dust` |
| `lavish-axi` | ACTIVE | Human review surface for HTML artifacts | When agent ships review artifacts |
| `chrome-devtools-axi` | ACTIVE | Browser automation | UI testing / scraping |
| `ctx7` | ACTIVE | Context7 library docs lookup | Library docs / API references |
| `cocoindex-code` / `ccc` | ACTIVE | Incremental code indexing | Build code indexes |
| `treehouse` | ACTIVE | Pool of reusable git worktrees | Parallel agents on one repo |
| `githits` | ACTIVE | Indexed search/grep/read across open-source code | Real-world code examples, dependency source |
| `inf` (inference.net) | ACTIVE | Catalyst gateway/tracing/evals/training | Observability + fine-tuning workflow |
| `gtimeout` / `timeout` | ACTIVE | Bound long-running live smoke tests | Use only around tests/agent probes |
| `gh-axi` | ACTIVE | GitHub CLI wrapper, alias `gha` | All GitHub operations, never bare `gh` |
| `chrome-devtools-axi` | ACTIVE | Browser automation, alias `cda` | |
| `lavish-axi` | ACTIVE | Review surfaces, alias `lva` | |
| `fastedit` | REMOVED | ~~AST-aware file edits~~ | Use standard Edit/Write instead |
| `pioneer` (fastino) | REMOVED | ~~SLM fine-tuning, NER, GLiNER~~ | Not on PATH, not coming back — corrected 2026-07-13 |
| `bun` | REMOVED | ~~Runtime for Pioneer CLI~~ | Only existed to support `pioneer`, same status |

Blocked for agents (captain-only): `rm`, `sudo`, `security` (ask the
captain), `export` (use bridge secrets adapter instead), GNU
coreutils aliases like `gcat`/`gls`/`ggrep`/`gfind` (bypass policy — the one
allowed GNU tool is `gtimeout`).

### Skills (`~/.agents/skills/`)

Do not trust a static table here — run `ls ~/.agents/skills/` for the live
list (30 skills as of 2026-07-13, verify with `date` before trusting this
number for long). 25/30 are nix-managed symlinks; 5 are real unmanaged
local directories not declared in `home.nix` (a reproducibility gap):
`computer-use`, `orchestration`, `gh-axi`, `githits`, `tldr`.

## Ponytail -- lazy senior dev mode

You are a lazy senior developer. Lazy means efficient, not careless. The best
code is the code never written.

Before writing any code, stop at the first rung that holds:

1. Does this need to be built at all? (YAGNI)
2. Does it already exist in this codebase? Reuse it.
3. Does the standard library already do this? Use it.
4. Does a native platform feature cover it? Use it.
5. Does an already-installed dependency solve it? Use it.
6. Can this be one line? Make it one line.
7. Only then: write the minimum code that works.

The ladder runs after you understand the problem, not instead of it: read the
task and the code it touches, trace the real flow end to end, then climb.

Bug fix = root cause, not symptom. Grep every caller of the function you
touch and fix the shared function once.

Rules:
- No abstractions that weren't explicitly requested.
- No new dependency if it can be avoided.
- No boilerplate nobody asked for.
- Deletion over addition. Boring over clever. Fewest files possible.
- Shortest working diff wins, but only once you understand the problem.
- Question complex requests: "Do you actually need X, or does Y cover it?"
- Mark intentional simplifications with a `ponytail:` comment.

Never lazy about: understanding the problem, input validation at trust
boundaries, error handling that prevents data loss, security, accessibility,
anything explicitly requested. Hardware is never the ideal on paper.

## General dev rules

- Never use the em dash "--". Use plain dash "-" instead.
- When writing commit messages, NEVER auto-add your agent name as co-author.
- Never manually modify CHANGELOG.md files or any files marked as auto-generated.
- When making technical decisions, prefer quality, simplicity, robustness,
  scalability, and long term maintainability over development speed.
- When doing bug fixes, always reproduce the bug before fixing it.
- Apply a high standard to engineering excellence: lint, test failures,
  and test flakiness should be fixed even if not directly related.
- Prefer the existing patterns and idioms of the codebase you're working in.

Also see the captain's machine-level CLAUDE.md at ~/CLAUDE.md for
hardware context, approval gates, and tool catalog.
