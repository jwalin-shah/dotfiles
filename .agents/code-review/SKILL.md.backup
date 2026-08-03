---
name: code-review
description: Review code changes for correctness, safety, and invariants. All P1 findings must cite tensor equations with line numbers.
---

# Code Review

Review changed code for correctness, not style. Every P1 finding must cite a tensor equation and line number.

## Process

1. Read the diff
2. Read the wayfinder map for context
3. Read the invariants (invariants.tl, tensor equations)
4. Review each changed file:
   - Blast radius: `llm-tldr impact <file>`
   - Call graph: `aider-axi calls <file> <function>`
   - Test coverage: `aider-axi tests <pkg>`
5. Classify every finding: P0 (build/test fails), P1 (invariant violation with equation + line), P2 (style/opinion)
6. Verify each P1 with a counterexample

## Output

Findings sorted by severity: P0 > P1 > P2. ACCEPT only if P0 passes AND no P1 with line-level evidence.
