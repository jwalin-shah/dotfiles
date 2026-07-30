---
name: triage
description: Process incoming issues through the triage state machine — needs evaluation, waiting, ready-for-agent, ready-for-human, wontfix.
---

# Triage

Move issues through the triage pipeline.

## Prerequisites

- Per-repo config: reads `docs/agents/triage-labels.md` for label vocabulary
- Reads `docs/agents/issue-tracker.md` for where issues live

## State machine

```
New → needs-triage → needs-info (waiting on reporter)
                   → ready-for-agent (fully specified, AFK-ready)
                   → ready-for-human (needs human implementation)
                   → wontfix (will not be actioned)
```

## Process

1. Read open issues from the configured tracker
2. For each unlabeled issue: evaluate, apply triage label
3. For `needs-info`: check if reporter responded, advance if so
4. For `ready-for-agent`: the issue is ready for bridge spawn
5. Report: triage summary (counts per state)
