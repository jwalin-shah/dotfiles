---
name: stow
description: Sweep the current session for uncaptured durable knowledge and file it to disk. Use mid-session to persist what you've learned before continuing, or at session end before a context reset.
user-invocable: true
---

# stow

Sweep this session for durable knowledge that only exists in conversation
right now, and write it to disk. The goal is a session that is safe to
reset because everything durable has already been captured.

## What it does

1. **Sweep the session for uncaptured durable knowledge.**
   Read back over this conversation and look for:
   - Operational learnings: facts and gotchas discovered this session
   - Captain preferences expressed in passing
   - Project-intrinsic facts: build, test, or architecture facts about a
     project that belong in that project's `AGENTS.md`
   - Decisions made that should outlive this session
   - Undone next steps

2. **Route each finding to the right location:**
   - Captain preferences → `data/captain.md` (hand-write, curate)
   - Operational learnings → `data/learnings.md` (dated, evidence-backed,
     rewrite/prune rather than appending forever)
   - Project-intrinsic knowledge → the project's `AGENTS.md` (update
     directly if you're working in that repo, or note as backlog)
   - Undone next steps → catalog as backlog items

3. **Curate, don't just append.**
   When a finding overlaps or supersedes something already on disk,
   rewrite or prune the existing entry over piling on a new one.

4. **Report to the captain.**
   Summarize: what was stowed and where, what was filed to backlog,
   and whether the session is safe to reset.

## Scope

This skill writes to:
- `data/captain.md` — captain preferences (gitignored)
- `data/learnings.md` — operational learnings (gitignored)
- Project `AGENTS.md` — project-intrinsic facts (tracked in git)
- Backlog — undone next steps

It never creates, edits, or stores findings as skills.
