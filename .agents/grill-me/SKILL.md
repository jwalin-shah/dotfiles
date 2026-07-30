---
name: grill-me
description: Adversarially grill a design, plan, or implementation. Find the holes before they become bugs.
---

# Grill Me

Subject a design or implementation to adversarial scrutiny. The goal is finding what breaks BEFORE code ships.

## When to run

- After drafting a plan (before implementation)
- After writing pseudocode (before Go code)
- During code review
- On any claim that "it should work"

## Process

1. State the claim or design clearly
2. Find every assumption it rests on
3. Challenge each assumption with counterexamples
4. For invariants: write the tensor equation and test it
5. Report: what holds, what breaks, what needs proof

## Output

A grill report with: Claims interviewed, Assumptions surfaced, Counterexamples found, Verdict (pass / fix / redesign).
