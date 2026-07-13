# Global Agent Contract
1. Read the project AGENTS.md first for build, test, architecture.
Behavioral rules for coding agents on this machine.

---

## Section 1: Tool Hierarchy

Use these in order and stop when the result is sufficient.

1. Structure first. If `llm-tldr` is installed, use it before opening many files in an unfamiliar repo.
3. GitHub uses `gh-axi` when available; otherwise use narrow `gh` JSON queries.
4. Public code examples use `githits`.
5. Structured data edits use `jq` or `yq`.

Avoid raw `cat`, `ls`, `grep`, `find`, `git`, and `gh` from agent shell unless a task specifically requires exact native output.

---

## Section 2: File Mutation

- Native harness write/edit tools (Edit, Write, apply_patch, etc.) are
  allowed and preferred — corrected 2026-07-13, this previously said the
  opposite and referenced `apply_patch`/`fastedit` as the required path,
  neither of which reflects actual practice.
- Touch only files required by the task.

---

## Section 3: Validation Discipline

- Run the smallest test that proves the change works.
- For counters and hooks, prove wiring with before -> action -> after, not just static config.

---

## Section 4: LLM Coding Behavior

- State assumptions before implementing.
- Ask when the request has multiple materially different interpretations.
- Implement the minimum code that solves the problem.
- Do not add speculative features or one-use abstractions.
- Do not revert user changes.

---

## Section 5: Collaboration Style

Be direct, concrete, and opinionated. Surface confusion instead of hiding it.

---

## Section 6: Secret And Provider Policy

- Provider keys come from the local secret adapter through `secret-cache exec -- <command>`.
- `TOKENROUTER_API_KEY` is the only TokenRouter key name.
- Do not export provider keys globally or write them into shell startup files.
- Launchers should not call Infisical directly except for explicit refresh flows.
- If a required provider key is missing, report the missing canonical env var and the launcher that needs it.

---

## Section 7: Launchers

Use these short names instead of bare `claude`, `opencode`, `codex`, `cursor-agent`, or `kilo`.

### Claude Code

| Command | Route | Notes |
|---|---|---|
| `c` | Account A OAuth | Primary Claude launcher; no gateway key |
| `ct` | TokenRouter gateway | Uses `TOKENROUTER_API_KEY` through `secret-cache exec` |
| `ca` | Account A via `claude-launch` | Compatibility alias; prefer `c` |

OAuth account A needs `/login` once in `~/.claude-a`.

### OpenCode

Global config: `~/.config/opencode/opencode.json` for permissions, instructions, and providers.

Each launcher sets `OPENCODE_CONFIG` to a profile overlay:

| Command | Auth | Default model | Profile |
|---|---|---|---|
| `oo` | ChatGPT Plus OAuth | `openai/gpt-5.5` | `profiles/oo.json` |
| `ot` | TokenRouter API key | `deepseek/deepseek-v4-flash` | `profiles/ot.json` + `secret-cache` |
| `op` | Pioneer API key | `pioneer/auto` | `profiles/op.json` + `secret-cache` |

`oo` does not use TokenRouter. It uses OpenAI OAuth in `~/.local/share/opencode/auth.json`.

### Kilo

| Command | Auth | Notes |
|---|---|---|
| `ko` | OpenAI/ChatGPT Plus | Kilo through OpenAI provider |
| `kt` | TokenRouter API key | Kilo through TokenRouter and `secret-cache exec` |

### Other Agents

| Command | Tool | Secrets |
|---|---|---|
| `cx` | Codex CLI | Codex/ChatGPT account |
| `cu` | Cursor Agent CLI | Cursor account auth |
| `agy` | Antigravity CLI | Own auth |

`ccp` is not an active launcher.

---

## Section 8: Known Issues

Read `~/.agent-rules/KNOWN_ISSUES.md` before any bash-heavy session.

---

## Section 9: Active Tools


Skills in `~/.agents/skills/`: `find-docs`, `tool-policy`, `pioneer-api`, `inference-net`.

Deprecated names: `githits-axi` -> `githits`, `coco-axi` -> `cocoindex-code`, `cognee-axi` -> `cognee-cli`, `context7`/`c7` -> `ctx7`.
