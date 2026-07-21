---
name: to-tickets
description: Convert a brain dump, wayfinder finding, or feature request into structured tickets.
---

# To Tickets

Convert unstructured ideas into actionable tickets.

## Prerequisites

- Per-repo config: reads `docs/agents/issue-tracker.md` to know where tickets live
- Reads `## Agent skills` block from CLAUDE.md for issue tracker config

## Process

1. Read the brain dump / request
2. Decompose into independent, scoped tickets
3. Each ticket: goal, scope (files), acceptance criteria, verification commands
4. File tickets in the configured issue tracker
5. Report ticket IDs/links

## Ticket format

Each ticket must specify: goal (one sentence), files (list), acceptance criteria (testable), adapter (optional, dispatch picks if omitted), timeout, retry limit.
