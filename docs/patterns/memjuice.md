# memjuice: Deterministic Memory Extraction from Transcripts

**Source**: `jwalin-shah/memjuice` (archived) -- `/tmp/audit-memjuice`

## Problem

Coding agents (Claude Code, Codex, Cursor, etc.) write session JSONL to disk
with every decision, fix, error, and discovery they make. But that history is
siloed per harness, per session -- invisible when you start a new session.
Existing memory tools require LLM calls (slow, costly, nondeterministic) or
are harness-specific.

## How It Works

1. **Normalize**: Parse session JSONL from multiple harnesses into a uniform
   `Event` type (ts, session_id, project, harness, kind, payload, source).
2. **Extract**: Apply deterministic regex + structural rules to classify events
   into typed `Observation` kinds: `decision`, `fix`, `edit`, `commit`, `pr`,
   `discovery`, `test_result`, `error`, `correction`.
3. **Store**: Append observations to a plain-text JSONL ledger at
   `~/.memjuice/<project>/observations.jsonl` -- `cat`, `grep`, `git diff` friendly.
4. **Supersede**: Types A/B/C supersession keeps the ledger from going stale
   when decisions evolve (e.g., a user correction within 6 events of a decision
   marks it as superseded).
5. **Inject**: A session-start hook reads the most recent observations and
   injects a ~300-token context block into the next session.

Zero LLM dependency. Zero API keys. Works offline. Single binary.

## Interface / Contract

```rust
/// Normalized cross-harness event.
struct Event {
    ts: DateTime<Utc>,
    session_id: String,
    project: Option<PathBuf>,
    harness: Harness,           // ClaudeCode | Codex | Aider | Continue | Cursor
    kind: EventKind,            // UserMessage | AssistantMessage | ToolUse | ToolResult
    payload: serde_json::Value, // { text, tool_name, tool_input, tool_output, is_error }
    source: String,             // "<file>:<line>" back to originating JSONL
}

/// One observation in the ledger.
struct Observation {
    ts: DateTime<Utc>,
    kind: String,               // "decision" | "fix" | "commit" | "pr" | "discovery" | ...
    project: String,
    file: Option<String>,
    text: Option<String>,       // The decision text, commit message, etc.
    command: Option<String>,
    error_excerpt: Option<String>,
    source: String,             // backlink to session JSONL
    harness: String,
    superseded_by_correction: Option<bool>,
    sha: Option<String>,        // for commit observations
    number: Option<i64>,        // for PR observations
}
```

Deterministic rule example (decision detection):
```rust
// Match: "let's", "we should", "decided", "going with", "switch to", "pick"
fn re_decision() -> &'static Regex { ... }
// Antipattern: trailing "??", rambling with 3+ "and" chains, hedged questions
fn re_decision_antipattern() -> &'static Regex { ... }
```

## Applying to jw-*

- **jw-sentry**: Agent sessions that work on jw-sentry produce JSONL transcripts.
  Memjuice can extract decisions, fixes, and errors from those transcripts into a
  project-level ledger. When a new session starts on jw-sentry, it gets a context
  block with the last N observations -- "last time we fixed X, decided Y."
- **jw-agentd**: The orchestrator could consult the memjuice ledger before
  launching a worker on a repo, giving the worker context about recent decisions
  and errors without burning tokens on full session replay.
- **Any jw-* repo**: Deterministic regex rules are fast, free, and predictable.
  The pattern of extract-on-session-end + inject-on-session-start can be wired
  into any agent harness hook system.
