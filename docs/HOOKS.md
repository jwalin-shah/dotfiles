# Hook Configuration Reference

Cross-harness SoT: `portfolio/wayfinder/harness-activation-matrix-2026-07-22.md`.
Prove all harnesses: `bin/prove-harness-hooks.sh`.

All agent hooks route through `dotfiles/bin/fmt-on-edit.sh`. That script is
the single extension point — add a new formatter there, all agents pick it up.

## What hooks do

After any file edit by an agent, the hook runs `fmt-on-edit.sh` with the
edited file path. The script dispatches by extension, then fans in Neo4j
on-change sync via `neo4j-on-change.sh` → `knowledge-engine/scripts/on-change-sync.sh`
(async, factory repos only).

| Extension | Formatter | Command |
|---|---|---|
| `.go` | gofmt | `gofmt -w "$FILE"` |
| `.py` | ruff | `ruff format --quiet "$FILE"` |
| `.swift` | swift-format | `swift-format -i "$FILE"` |

Add new entries to `bin/fmt-on-edit.sh` to support more languages.

## Support matrix

| Agent | Config file | Hook key | Status |
|---|---|---|---|
| `ca` / `ct` | `~/.claude/settings.json` | `PostToolUse` | ✅ wired |
| `ca` (account A) | `~/.claude-a/settings.json` | `PostToolUse` | ✅ wired |
| `ca` (token) | `~/.claude-token/settings.json` | `PostToolUse` | ✅ wired |
| `agy` | `~/.gemini/settings.json` | `PostToolUse` | ✅ wired |
| `cx` (Codex) | `~/.codex/hooks.json` | `post-edit` | ✅ wired |
| `cua` (Cursor Agent) | `~/.cursor/hooks.json` | **`afterFileEdit`** + **`preToolUse`** | ✅ fixed 2026-07-22 |

OpenCode and Kilo removed from machine (Jul 2026). Not in home.nix.

### Cursor ≠ Claude (do not copy keys)

Cursor schema uses camelCase events (`afterFileEdit`, `preToolUse`, …).
Claude Code uses `PostToolUse` / `PreToolUse`. Copying Claude keys into
`~/.cursor/hooks.json` is a **silent no-op** — fmt and enforce never run.

Prove:

```bash
~/projects/dotfiles/bin/prove-cursor-hooks.sh
```

Cursor `afterFileEdit` sends `{ "file_path": "..." }` on stdin. Wrapper:
`bin/cursor-after-file-edit.sh` → `fmt-on-edit.sh`. After editing
`home/.cursor/hooks.json`, run `./rebuild.sh` so HM reasserts
`force = true` out-of-store links for hooks + AGENTS.md.

## Bridge workflow gate (all harnesses)

One script: `bin/enforce-bridge-workflow.sh`.

**Policy:** any mutation under `~/projects/<repo>` needs `ORBIT_TASK.md` or
`.bridge-task` in that repo. Applies to **every** project dir, not a 3-name
allowlist. Shell write-forms (`>`, heredoc, `tee`, `rm`, …) are mutations —
no Write-tool bypass via shell.

| Harness | Event | Matcher / notes |
|---------|-------|-----------------|
| Cursor | `preToolUse` | `Write\|Edit\|Delete\|TabWrite\|Shell`; `failClosed: false` in this worker (hook runner cannot spawn shell — `failClosed:true` + crash = total lockout). Do **not** use `beforeShellExecution` here until Cursor can exec hooks without nesting failure. |
| Claude | `PreToolUse` | `Edit\|Write\|Bash` |
| Codex | `pre-edit` | file edits only today — **shell bypass still open on Codex** until a shell pre-hook exists |
| Gemini/agy | `PreToolUse` | `edit_file` via `enforce-bridge-workflow-antigravity.sh` |

Prove: `bin/prove-bridge-workflow-gate.sh`

Lesson (2026-07-22): Cursor `failClosed: true` when the worker cannot execute
the hook command (`Shell execution is not available in the worker extension
host`) blocks **all** Write/Shell, including gate self-repair. That is not
“stricter security” — it is a dead agent. Policy deny = exit 2 from a running
hook; infrastructure crash must not be conflated with policy deny.

## Hook limitation: agent-level only

PostToolUse only fires when an agent edits a file. Manual edits in a terminal
or editor bypass all hooks. The pre-commit hook is the backstop for those.

For a true OS-level formatter (model-independent), add an fswatch LaunchAgent
to configuration.nix — same pattern as tldr-daemon and cocoindex-daemon.
Not yet implemented: `fswatch` is not installed. Add via `homebrew.extraPackages`
in configuration.nix when needed.


## Hook format by harness

### Claude Code / Antigravity CLI (agy)

File: `~/.claude/settings.json` or `~/.gemini/settings.json`

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "/Users/jwalinshah/projects/dotfiles/bin/fmt-on-edit.sh"
          }
        ]
      }
    ]
  }
}
```

Environment variable available inside the hook: `CLAUDE_TOOL_INPUT_FILE_PATH`

### Codex / cx

File: `~/.codex/hooks.json`

```json
{
  "hooks": {
    "post-edit": [
      {
        "command": "/Users/jwalinshah/projects/dotfiles/bin/fmt-on-edit.sh"
      }
    ]
  }
}
```

### OpenCode / Kilo

Not yet documented. Check vendor docs and update this file when confirmed.

## Three-layer defense

```
Layer 1: PostToolUse / post-edit hook   ← fires on every agent file edit
Layer 2: pre-commit git hook            ← blocks unformatted commits
Layer 3: make fmt-check / make ci       ← explicit CI gate
```

Layers 1 and 2 are automatic. Layer 3 is on-demand.

## Adding a new agent harness

1. Find its hook config file (usually in `~/.agentname/`)
2. Add the `fmt-on-edit.sh` reference in the agent's hook format
3. Add a row to the support matrix above
4. Run `bin/prove-harness-hooks.sh` (docs-backed event names + gate/fmt refs)

## Updating fmt-on-edit.sh

The script is at `dotfiles/bin/fmt-on-edit.sh`. It is symlinked into
`~/.local/bin/` by home.nix (or copied by bootstrap-projects.sh).

All agents share the same script. A change here takes effect immediately
for all agents — no per-harness config update needed.
