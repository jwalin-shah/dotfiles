---
name: wayfinder
description: Create or update a Wayfinder map — the living source of truth for what's actually fixed vs. still open. Always run before starting work on any project.
---

# Wayfinder

Before ANY code changes, create or read the Wayfinder map for the project you're touching.

## When to run

- Starting new work on any project
- After discovering a gap, bug, or missing piece
- Before implementing anything that touches shared infrastructure

## Process

1. Read `portfolio/wayfinder/<project>/map.md` if it exists
2. If it doesn't exist, create it from the current state
3. Read `portfolio/wayfinder/bridge-loop-architecture/map.md` if the work touches bridge or spawn
4. Document findings, decisions, and what's not yet specified
5. Get captain sign-off before code changes

## Output

A Wayfinder map with: Destination, Findings, Decisions, Not yet specified, Out of scope.

See `portfolio/wayfinder/` for examples.
