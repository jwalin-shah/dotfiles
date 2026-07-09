---
name: agent-visibility-architecture
description: How agents get visibility into other agents — the correct approach vs the wrong one
metadata:
  type: reference
---

# Agent Visibility: JSONL Transcripts, Not PTY Scraping

## The wrong way

`mintmux` + `herdr` provide a read/wait API on agent PTY panes. This is PTY
scraping — fragile, unstructured, imprecise. You're parsing terminal escape
sequences from a TUI to extract structured data. Every format change breaks it.
Every resize corrupts it. The agent output is intermixed with ANSI codes and
cursor movements.

## The right way (already running)

`jw-sessiond` uses kqueue to watch Claude Code JSONL transcript files directly.
Every message, tool call, cost, and error is emitted as a structured JSONL event
into `~/.local/share/jw/events.jsonl`. This is:

1. **Structured** — JSONL, not terminal escape codes
2. **Real-time** — kqueue fires on every `write()` to the transcript
3. **Complete** — user messages, assistant responses, tool calls, costs, errors
4. **Parseable** — any consumer can read the event stream
5. **Already running** — LaunchAgent, KeepAlive, production since day 1

## Why this is better

| Approach | mintmux/herdr PTY | jw-sessiond JSONL |
|----------|-------------------|-------------------|
| Data quality | Terminal scraping | Structured JSONL |
| Resilience | Breaks on TUI changes | API contract stability |
| Completeness | What's visible on screen | Every message in the session |
| Latency | Wait for screen render | kqueue fires on filesystem write |
| Consumers | herdr read/wait API | events.jsonl (any consumer) |
| Agent overhead | Extra PTY layer | Zero — Claude Code writes transcripts natively |

## What mintmux is actually for

Mintmux is the PTY multiplexer — it CREATES the PTYs that agents run in. It's
the infrastructure layer. Agents need a terminal to run in, and mintmux provides
that with Unix socket control, Lua scripting, per-pane isolation, and restart
semantics.

Herdr is the session provider — it gives the CAPTAIN visibility into agent
sessions through a TUI. It's for humans, not for programmatic consumption.

For programmatic visibility: use `jw-sessiond` → `events.jsonl`.

## Architecture

```
Agent session (Claude Code)
    |
    |-- TTY → mintmux PTY (terminal interface for the agent)
    |
    |-- Transcript → JSONL file (structured event log)
            |
            v
        jw-sessiond (kqueue watch)
            |
            v
        events.jsonl (event bus)
            |
            +-- jw-sentry (quality checks, notifications)
            +-- jw-core (state tracking)
            +-- memjuice (observations ledger → cognee)
            +-- Any other consumer
```

The JSONL transcript is the canonical record. The PTY is just the terminal.
Don't scrape the terminal when you already have the structured data.

---

*Discovered during the July 8, 2026 machine audit. The herdr read/wait API
for agent panes is redundant with the already-running jw-sessiond pipeline.*
