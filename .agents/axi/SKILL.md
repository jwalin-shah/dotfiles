---
name: axi
description: "Pre-code gates: assess blast radius, call graph, prior art, then decide on worktree isolation. Run BEFORE any code change."
---

# Axioms — Pre-Code Invariant Gates

These gates run before every code change. The hook enforces this mechanically.
The purpose: verify before you mutate. Know what you'll break before you touch it.

## Tools (all verified installed)

| Gate | Tool | Command |
|------|------|---------|
| Blast radius | `llm-tldr impact` | `llm-tldr impact <function> <dir>` — who calls this? |
| Call graph | `llm-tldr calls` | `llm-tldr calls <dir>` — cross-file call graph |
| Prior art | `githits example` | `githits example "<problem>" --lang <lang>` — OSS implementations |
| Diagnostics | `llm-tldr diagnostics` | `llm-tldr diagnostics <file>` — type/lint errors |
| Diff surface | `git diff` | `git diff --stat` or `git diff HEAD` |

## The full workflow

```
1. ASSESS
   └─ Run axiom gates:
      llm-tldr impact <function> <dir>
      llm-tldr calls <dir>
      githits example "<problem>"
      llm-tldr diagnostics <file>

2. DECIDE
   └─ Wide blast radius (>3 files touched)?
      Deep call graph (many callers)?
      Novel code (no prior art found)?
      → YES to any → USE WORKTREE ISOLATION
      → NO to all → edit in-place is fine

3. ISOLATE (if needed)
   └─ Create isolated worktree:
      worktree create <feature-name>
      # Or use the built-in EnterWorktree tool

4. IMPLEMENT
   └─ Write the change in the worktree
   └─ check-on-edit.sh runs type/lint checks automatically

5. VERIFY
   └─ Run tests: cargo test / npx vitest / pytest / go test
   └─ Run type checker: cargo check / npx tsc / pyright / go vet
   └─ Re-run blast radius: llm-tldr impact <function> <dir>

6. LAND
   └─ Commit, push, PR
   └─ Clean up: worktree remove <feature-name>
   └─ Or: ExitWorktree (keep or remove worktree)
```

## When to run

- Before any code change across any project (not just orbit/bridge)
- The hook enforces this — you shouldn't have to remember

## Integration

This wraps the pre-code assessment phase. The flow is:
```
/axi → /mattpocock-skills:implement → write code → verify → /mattpocock-skills:mp-code-review
```