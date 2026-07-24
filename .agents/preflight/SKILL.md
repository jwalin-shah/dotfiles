---
name: preflight
description: "Pre-code gates: blast radius, call graph, prior art, then worktree isolation if needed. Run BEFORE any code change. (Renamed from axi — do not say axi.)"
---

# Preflight — Pre-Code Gates

**Canonical name: preflight.** Never call this “axi” (collides with the axioms corpus).
See `portfolio/wayfinder/preflight-rename-axi-2026-07-23.md`.

These gates run before every code change. Know what you’ll break before you touch it.

## Tools

| Gate | Tool | Command |
|------|------|---------|
| Blast radius | `tldr impact` / `llm-tldr impact` | `tldr impact <function>` — who calls this? |
| Call graph | `tldr calls` | `tldr calls <dir>` |
| Prior art | `githits example` | `githits example "<problem>"` |
| Change impact | `tldr change-impact` | files → affected tests |
| Diff surface | `git diff` | `git diff --stat` / `git diff HEAD` |
| Callers (fallback) | `rg` | if tldr graph cold |

## Workflow

```text
1. ASSESS — impact / calls / githits / rg callers
2. DECIDE — wide blast or novel? → worktree isolation
3. ISOLATE — worktree create if needed
4. IMPLEMENT — only after assess
5. VERIFY — project tests + re-check blast
6. LAND — commit / PR / release worktree
```

## When

- Before any code change (any language / any project)
- Cursor-direct edits **and** before claiming a spawn override is done
- Does **not** replace bridge packets; packets feed the worker, preflight forces proof before blind edits

## Integration

```text
preflight → implement → verify → review
```

Old `/axi` invocations mean **preflight**.
