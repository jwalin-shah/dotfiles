# External Tools — Patterns to Steal

## 1. no-mistakes Pipeline (adopt fully)

**What it is:** Local git proxy that validates work through a fixed pipeline: intent → rebase → review → test → document → lint → push → PR → CI.

### Patterns to steal:
- **TOON format output** — structured stdout + progress stderr, agent-parseable
- **Gate/respond loop** — `axi run` blocks until decision, captain `axi respond`, loops until outcome
- **Intent propagation** — user intent as first-class field through every pipeline stage
- **Auto-fix thresholds** — configurable fix levels (0=off, N=auto-fix up to N findings)
- **Process-tree isolation** — Setpgid for all subprocesses, prevents orphaned grandchildren

### Integration with jw:
- TOON output for jw CLI commands
- Gate loop maps to `jw approve`/`jw answer` captain commands
- Process isolation for jw spawn subprocesses

## 2. gnhf Autonomous Loop (adopt selectively)

**What it is:** Runs a coding agent in a loop. Each successful iteration = git commit. Three failures → abort.

### Patterns to steal:
- **Structured AgentOutput** — `{success, summary, key_changes_made, key_learnings, should_fully_stop}`
- **Commit-per-iteration with repair** — failed commit preserves work for next iteration
- **PermanentAgentError vs transient** — exponential backoff for transient, immediate abort for permanent
- **Renderer as separate concern** — event-emitter pattern enables live TUI updates
- **Run metadata directory** — `.gnhf/runs/<id>/` for resumable, inspectable runs

### Already have:
- jw-tui event-emitter pattern (reads events.jsonl)
- jw-core phase dispatch (similar to iteration loop)

## 3. ACP Agent Abstraction (adopt pattern, not package)

**What it is:** Single agent interface supporting Claude, Codex, Copilot, Pi, OpenCode, Rovo Dev, and ACP targets through one abstraction.

### Pattern to steal:
- **acp:<target> resolution** — one interface for all agents
- **JSON events from stdout** — structured output from agent subprocess
- **Token usage accumulation** — per-iteration cost tracking

### jw protocol (our version):
- Go-native agent abstraction layer (no npm dependency)
- mintmux Unix socket as transport
- events.jsonl as audit trail
- We own the entire stack

## 4. Symphony (study for reference)

- Declarative WORKFLOW.md as pipeline definition
- PR cluster detection (group similar PRs before review)
- We can implement both on top of cocoindex + no-mistakes

## 5. Pi CLI / oh-my-pi (not installed, patterns nonetheless)

- JSON-mode output with schema injection into prompt
- SSE streaming with structured event parsing
- "Append schema at end" trick for reliable structured output
