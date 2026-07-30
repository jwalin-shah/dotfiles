---
name: simplify
description: Review changed code for reuse, simplification, efficiency, and altitude cleanups. Quality only — does not hunt for bugs.
---

# Simplify

Clean up code — reduce duplication, improve naming, simplify control flow. Quality only, no bug hunting.

## Process

1. Read the changed files
2. Find: duplicated logic, over-complicated flow, bad names, dead code
3. Apply the simplest fix that improves readability
4. Verify: tests still pass
5. Report: what was simplified and why
