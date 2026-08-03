---
name: implement
description: Implement a feature from a spec or plan. Write code that passes the gates.
---

# Implement

Write code against a proven design. Do not start until the plan has been grilled and pseudocode reviewed.

## Prerequisites

- Wayfinder map read
- Plan grilled and approved
- Pseudocode reviewed (20 reviewers, P0=0, P1=0)
- ORBIT_TASK.md active with current step

## Process

1. Read the spec/plan/pseudocode
2. Write the minimum code that satisfies it
3. Run P0 gate: `go build ./... && go test -race ./... && golangci-lint run`
4. If P0 fails, fix and re-gate
5. When P0 passes, mark step complete

## Rules

- Never write Go before pseudocode is clean
- Match existing code patterns
- Deletion over addition
- Boring over clever
