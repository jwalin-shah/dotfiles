---
name: domain-modeling
description: Model the domain — entities, relationships, boundaries, invariants. Creates CONTEXT.md and ADRs.
---

# Domain Modeling

Map the domain: what entities exist, how they relate, what invariants hold, where the boundaries are.

## Prerequisites

- Per-repo config: reads `docs/agents/domain.md` for layout

## Process

1. Read existing CONTEXT.md and ADRs
2. Identify: entities, relationships, boundaries, invariants, events
3. Write/update CONTEXT.md with the domain language
4. Write ADRs for architectural decisions
5. Link ADRs to domain entities

## Output

Updated CONTEXT.md, new ADRs in `docs/adr/`.
