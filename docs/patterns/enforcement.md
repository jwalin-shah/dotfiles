# Agent Behavior Enforcement -- Design Notes

> How the three governance patterns wire into agent workflows.
> These are the mechanisms that turn "please follow the rules" into
> "the rules are enforced by the system."

---

## 1. Harness Pattern -- Run Manifests

### What It Enforces

Every agent session that changes code or produces artifacts must leave
behind a structured, machine-readable record of what happened. "I did
the thing" is not evidence. The run manifest is.

### Mechanism

**Enforcement point**: Session-end hook. The agent harness (Claude Code,
Codex, OpenCode) fires a hook at session end. The hook checks whether
the session changed code (git diff is non-empty) or produced artifacts.
If it did, and no run manifest exists, the hook warns and prompts the
agent to write one.

**Implementation**:

```bash
# ~/.local/bin/jw-run-manifest-check -- called by session-end hook
#
# 1. Check if repo has uncommitted changes or new commits since session start.
# 2. If yes, check for .jw/runs/<run_id>.json.
# 3. If missing, emit warning and prompt agent to produce manifest.
# 4. If present, validate schema (required fields present).
```

**Schema** (the contract every manifest must satisfy):

```json
{
  "schema_version": "1.0",
  "run_id": "run_20260703T143000Z_fix_timeout",
  "task": "Fix SQLite busy timeout in jw-core state.go",
  "repo": "jw-core",
  "branch": "fm/fix-sqlite-busy-timeout",
  "head_sha": "abc123def456",
  "status": "succeeded | failed | partial",
  "commands": [
    {
      "purpose": "build",
      "argv": ["go", "build", "-o", "jw", "."],
      "exit_code": 0,
      "stdout_path": null,
      "stderr_path": null
    },
    {
      "purpose": "validation",
      "argv": ["./scripts/check.sh"],
      "exit_code": 0,
      "stdout_path": ".jw/runs/run_20260703T143000Z/check-stdout.txt",
      "stderr_path": null
    }
  ],
  "validation_ref": {
    "status": "succeeded",
    "gate": "no-mistakes",
    "findings": 0
  },
  "evidence_refs": [
    {
      "kind": "diff",
      "path": ".jw/runs/run_20260703T143000Z/diff.patch",
      "description": "Full diff against main"
    }
  ],
  "risk_ref": {
    "external_write_allowed": false,
    "privacy_risk": "low",
    "destructive": false
  }
}
```

**Storage**: `.jw/runs/<run_id>.json` (gitignored). Evidence artifacts
alongside in `.jw/runs/<run_id>/`.

### Integration Points

| Harness | Hook Mechanism | Session-End Trigger |
|---------|---------------|---------------------|
| Claude Code | `~/.claude/settings.json` hooks | `after-session` hook runs `jw-run-manifest-check` |
| Codex | Codex hooks config | `post_session` hook |
| OpenCode | OpenCode config | `on_session_end` callback |

### Enforcement Level

**Warning (default)**: Missing manifest produces a warning. The agent
can proceed but the gap is recorded.

**Hard block (opt-in per project)**: A project's AGENTS.md can declare
`run_manifest: required`. Then the hook refuses to end the session
without a valid manifest. Use this for high-assurance projects.

---

## 2. Proof-of-Action Pattern -- Typed Projections

### What It Enforces

Internal data structures must never be serialized directly at API,
CLI, TUI, or log boundaries. Every consumer boundary gets a narrow
typed projection that carries only the fields that boundary needs.
Every field that crosses a boundary must be a conscious, auditable
decision.

### Mechanism

**Enforcement point**: Code review. There is no automated compiler
check for this (a lint rule could detect "serde::Serialize on internal
struct" but the real enforcement is architectural). The project's
AGENTS.md declares projection types in the "Contracts" section. A
reviewer (human or agent) checks that new code crossing a boundary
uses the declared projection, not the internal type.

**Pattern in Go**:

```go
// Internal -- never serialized directly
type ThreadRecord struct {
    ID          string
    Project     string
    Goal        string
    Phase       string
    Status      string
    Worktree    string
    ParentID    string
    CreatedAt   time.Time
    UpdatedAt   time.Time
    InternalMeta map[string]string  // never leaves the process
}

// CLI projection for "jw status" output
type ThreadStatusRow struct {
    ID      string
    Project string
    Goal    string
    Phase   string
    Status  string
}

// Explicit, auditable conversion
func (tr *ThreadRecord) ToStatusRow() ThreadStatusRow {
    return ThreadStatusRow{
        ID:      tr.ID,
        Project: tr.Project,
        Goal:    tr.Goal,
        Phase:   tr.Phase,
        Status:  tr.Status,
    }
}
```

**Pattern in Rust**:

```rust
// Internal
struct ThreadRecord {
    id: String,
    project: String,
    goal: String,
    phase: String,
    status: String,
    worktree: Option<PathBuf>,
    internal_meta: HashMap<String, String>,  // never serialized
}

// CLI projection
#[derive(Serialize)]
struct ThreadStatusRow {
    id: String,
    project: String,
    goal: String,
    phase: String,
    status: String,
}

impl From<&ThreadRecord> for ThreadStatusRow {
    fn from(t: &ThreadRecord) -> Self { ... }
}
```

**Pattern in TypeScript**:

```typescript
// Internal
interface ThreadRecord {
  id: string;
  project: string;
  goal: string;
  phase: string;
  status: string;
  worktree: string | null;
  internalMeta: Record<string, string>;  // never sent to client
}

// API projection
interface ThreadStatusResponse {
  id: string;
  project: string;
  goal: string;
  phase: string;
  status: string;
}

function toStatusResponse(t: ThreadRecord): ThreadStatusResponse {
  const { id, project, goal, phase, status } = t;
  return { id, project, goal, phase, status };
}
```

### Integration Points

| Boundary Kind | Enforcement |
|---------------|-------------|
| HTTP API response | Code review: handler returns projection type, not internal type |
| CLI stdout | Code review: command handler calls explicit `ToX()` method |
| TUI rendering | Code review: TUI model is a projection, not the internal model |
| JSONL event log | Code review: event struct is a projection, not the internal struct |
| Config file write | Code review: serialized config type is separate from runtime config |

### Enforcement Level

**Convention (default)**: Projects declare their projections in the
"Contracts" section of AGENTS.md. Code review enforces.

**Lint rule (where applicable)**: A custom lint rule can forbid
`Serialize`/`JsonSchema` derives on types marked as internal
(by comment annotation or naming convention). This is language-specific
and optional.

---

## 3. Memjuice Pattern -- Deterministic Context Injection

### What It Enforces

Every agent session on a project starts with a brief context block
injected into the agent's system prompt or preamble. This block
contains the most recent observations from the project's ledger:
decisions, errors, fixes, open PRs, and known sharp edges. The block
is deterministically extracted -- no LLM call, no API key, no
nondeterminism.

### Mechanism

**Enforcement point**: Session-start hook. Before the agent sees the
user's first message, a hook reads the project's observations ledger,
selects the most recent N observations (up to ~300 tokens), and
injects them into the session context.

**Ledger format** (plain JSONL at `~/.local/share/jw/projects/<name>/observations.jsonl`):

```jsonl
{"ts":"2026-07-03T10:15:00Z","kind":"decision","text":"Use busy_timeout=5000 for SQLite to avoid contention","file":"state.go","sha":null,"superseded":false}
{"ts":"2026-07-03T10:20:00Z","kind":"fix","text":"Fixed nil pointer in dispatch.go:142 when worktree fails to acquire","file":"dispatch.go","sha":"abc123","superseded":false}
{"ts":"2026-07-03T10:30:00Z","kind":"commit","text":"Fix SQLite busy timeout and worktree nil pointer","file":null,"sha":"def456","superseded":false}
{"ts":"2026-07-03T10:35:00Z","kind":"pr","text":"fix: SQLite busy timeout + worktree nil guard","file":null,"sha":null,"number":142,"superseded":false}
{"ts":"2026-07-03T11:00:00Z","kind":"discovery","text":"The circuitbreaker.go RetryWithBackoff caps at 30s but SQLite contention can last 60s under load","file":"circuitbreaker.go","sha":null,"superseded":false}
{"ts":"2026-07-03T14:00:00Z","kind":"error","text":"Build failed: undefined: sqlite.BusyTimeout -- need modernc.org/sqlite v1.32+","file":"state.go","sha":null,"superseded":false}
```

**Observation kinds**: `decision`, `fix`, `edit`, `commit`, `pr`,
`discovery`, `test_result`, `error`, `correction`.

**Supersession**: A `correction` observation within 6 events of a
`decision` marks that decision as superseded. Superseded observations
are not injected into context.

**Injection format** (the ~300-token block injected at session start):

```
## Recent Activity in jw-core

- 10:15 -- Decided: Use busy_timeout=5000 for SQLite to avoid contention (state.go)
- 10:20 -- Fixed: nil pointer in dispatch.go:142 when worktree fails (sha: abc123)
- 10:30 -- Committed: Fix SQLite busy timeout and worktree nil pointer (sha: def456)
- 10:35 -- PR #142 opened: fix: SQLite busy timeout + worktree nil guard
- 11:00 -- Discovered: RetryWithBackoff caps at 30s but SQLite contention can last 60s (circuitbreaker.go)
- 14:00 -- Error: Build failed: undefined sqlite.BusyTimeout -- need v1.32+ (state.go)
```

### Integration Points

| Harness | Injection Mechanism |
|---------|-------------------|
| Claude Code | `~/.claude/settings.json` `before-session` hook that reads ledger and writes to CLAUDE.md preamble or system prompt override |
| Codex | Codex `pre_session` hook |
| OpenCode | OpenCode `on_session_start` callback |
| Any agent that reads CLAUDE.md | Inject block at top of CLAUDE.md's session-context section (marked with `<!-- memjuice:start -->` / `<!-- memjuice:end -->` comments so the hook can replace it) |

### Implementation Sketch

```bash
# ~/.local/bin/jw-memjuice-inject -- called by session-start hook
#
# 1. Detect current project from $PWD or git remote.
# 2. Read ~/.local/share/jw/projects/<name>/observations.jsonl.
# 3. Select most recent N observations up to token budget.
# 4. Format as markdown context block.
# 5. Inject into session preamble (mechanism varies by harness).
# 6. Exit silently if no ledger exists (first session on project).

# ~/.local/bin/jw-memjuice-extract -- called by session-end hook
#
# 1. Read session transcript JSONL.
# 2. Apply deterministic regex rules to classify observations.
# 3. Append new observations to project ledger.
# 4. Apply supersession: if any new observation is a "correction",
#    mark the corresponding prior decision as superseded.
```

### Enforcement Level

**Advisory (default)**: Missing context injection produces no warning.
The agent simply lacks the memory boost. The ledger still accumulates.

**Required (opt-in per project)**: A project's AGENTS.md can declare
`memjuice: required`. Then the session-start hook warns if the ledger
is stale (> 7 days since last injection) or missing.

---

## 4. How the Three Patterns Fit Together

```
SESSION START
  │
  ├─ memjuice inject ── reads observations.jsonl, injects ~300-token context block
  │
  ├─ agent reads AGENTS.md ── build, test, architecture, contracts, quirks
  │
  ├─ agent reads ~/CLAUDE.md ── tool catalog, conventions, approval gates
  │
  ▼
AGENT DOES WORK
  │
  ├─ proof-of-action ── every boundary crossing uses typed projections,
  │                      enforced by code review and AGENTS.md contracts
  │
  ▼
SESSION END
  │
  ├─ harneess run manifest ── writes .jw/runs/<run_id>.json with commands,
  │                            validation, evidence, and risk
  │
  ├─ memjuice extract ── reads session transcript, classifies observations,
  │                       appends to observations.jsonl, applies supersession
  │
  ▼
NEXT SESSION STARTS ── loop closed, context injected
```

---

## 5. Adoption Path

### For an Existing Project

1. Copy the AGENTS.md template into the project root.
2. Fill in Build, Test, Architecture sections (30 minutes).
3. Fill in Contracts section -- list at least the primary API/CLI boundaries
   and their projection types (30 minutes).
4. Fill in Known Quirks -- the 3-5 things that surprise new contributors
   (15 minutes).
5. Fill in Verification Contract -- any project-specific checks beyond the
   global defaults (10 minutes).
6. Wire the session-end hook to produce run manifests (one-time setup per
   harness, ~10 minutes).
7. Wire the session-start hook for memjuice injection (one-time setup per
   harness, ~10 minutes).

### For a New Project

1. Create AGENTS.md from the template before writing code. Fill in Overview,
   Build, and Architecture as you go.
2. Add projection types as soon as the first API/CLI boundary is defined.
3. Add quirks as you discover them. Never let a painful debugging session
   go unrecorded.
4. Wire hooks at project init time.

### Lightweight Option

Not every project needs the full harness. A minimal adoption:

1. AGENTS.md with Overview, Build, Test, and Known Quirks sections.
2. Skip run manifests and memjuice for projects with low change frequency.
3. Add them when the project becomes actively developed.

---

*Last updated: July 3, 2026*
