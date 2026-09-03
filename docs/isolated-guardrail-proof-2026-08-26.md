# Isolated mutation guardrail proof

**Date:** 2026-08-26 America/Los_Angeles
**Status:** active in the live dotfiles hook path; re-verified after activation
**Purpose:** prevent ordinary agent work from starting in a shared primary
checkout while retaining an explicit, disposable prototype exception.

## Exact tree binding

| Field | Value |
|---|---|
| Repository | `/Users/jwalinshah/.dotfiles` (live path; primary resolves to `/Users/jwalinshah/projects/dotfiles`) |
| Base ref | `main` |
| Base commit | `92701e374ab99410f386f1ccd034699d65aef934` |
| Implementation worktree | `/Users/jwalinshah/orca/workspaces/.dotfiles/lifeops-isolation-guardrail` |
| Implementation branch | `jwalin-shah/lifeops-isolation-guardrail` |
| Implementation commits | `d2724ceed9e6d4bbfa8d292ef04d6873204bb16b`, `42f9bda84cea1542293928fe29a4fd443578215b` |
| Live activation commits | `c13f90b`, `2f0eaba`, `c74f580` |
| Live HEAD at re-verification | `c74f5805e3133d628af0ffde437c6a92cdf17914` |
| Proof-refresh worktree | `/Users/jwalinshah/orca/workspaces/.dotfiles/lifeops-guardrail-proof-refresh-2026-08-26` |
| Changed files | `bin/enforce-bridge-workflow.sh`, `bin/prove-bridge-workflow-gate.sh`, `docs/HOOKS.md`, this record |

The live primary checkout was already dirty before this work. Only the three
guardrail activation commits were cherry-picked into live `main`; the
pre-existing unrelated changes remain unmodified. The implementation and
proof-refresh worktrees were created by Orca as separate git worktrees.

## Verified behavior

`bin/prove-bridge-workflow-gate.sh` passed **19/19** cases, including:

- primary/shared mutation denied with or without a stale task marker;
- existing and new files both mapped to the correct checkout;
- isolated checkout denied until it has a task marker, then admitted;
- prototype admitted only with explicit purpose, allowed paths, future expiry,
  `disposable=true`, and `no_delivery=true`;
- prototype writes outside `.scratch`/`.prototype`, outside `allowed_paths`, or
  with missing purpose denied;
- shell redirection uses the same policy as file-edit inputs;
- invalid JSON hook input denied instead of receiving inferred permission;
- existing Cursor, Claude, Codex, and Gemini hook wiring remains present.

Additional proof commands and results:

```text
bash -n bin/enforce-bridge-workflow.sh bin/prove-bridge-workflow-gate.sh  PASS
./bin/prove-bridge-workflow-gate.sh                                  PASS=19 FAIL=0
./bin/prove-docs-freshness.sh                                        PASS
git diff --check                                                     PASS
```

A direct live-primary probe for
`/Users/jwalinshah/projects/dotfiles/MACHINE.md` returned exit `2` with the
structured `PreToolUse` deny contract.

After activation, the same repository-native proof was rerun from the live
checkout with these results:

```text
./bin/prove-bridge-workflow-gate.sh  PASS=19 FAIL=0
./bin/prove-docs-freshness.sh        PASS
live primary probe                   exit=2, structured deny
```

The live hook configs still point at
`/Users/jwalinshah/.dotfiles/bin/enforce-bridge-workflow.sh`. Cursor's
pre-existing `beforeShellExecution` hook was detected and left unchanged.

## Boundaries still open

- Codex shell mutation interception remains a documented vendor-hook gap.
- Hooks do not govern manual edits that bypass the harness; the pre-commit
  backstop remains separate.
- A generic `bridge verify` run is not a valid proof for this shell-only repo;
  its Go and `ccc` gates are inapplicable. The repository-native proof above is
  the evidence counted for this change.
