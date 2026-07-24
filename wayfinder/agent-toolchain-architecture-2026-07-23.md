# Agent toolchain architecture — 2026-07-23

**Status:** implementation complete; live Home Manager activation and Pi login
remain operator actions because the main dotfiles checkout contains unrelated
dirty work.

## Decision

Pi is an interactive cockpit, not a replacement for Bridge. Mintmux owns Pi's
PTY and session persistence. Bridge continues to own admitted worker execution,
worktrees, sandboxing, verification, ledger outcomes, and eventual delivery
mediation.

```text
captain -> pi-cockpit -> Mintmux pane -> Pi TUI
                                      -> discussion / planning / small local work
                                      -> Bridge for admitted long-running work

Bridge -> ct / ca / codex / other adapters -> isolated worktree -> verify
```

The first slice uses Pi interactively. Pi's SDK and JSONL RPC mode are real
native integration surfaces, but Bridge does not need either to host the TUI.
Use them only when a concrete Bridge-to-Pi contract exists.

## Service capability inventory (AX-017)

| Service | Native capability | Assigned role | Decision / prove |
|---|---|---|---|
| Pi 0.81.1 | TUI, project trust, extensions, skills, sessions, SDK, strict-JSONL RPC | Human cockpit | Pin in `config/agent-toolchain.tsv`; `pi --version` |
| Mintmux | Named PTY sessions, attach/detach, capture, send, signal | Host the Pi process | `mm-ctl ping`; `pi-cockpit` reattaches a live pane and resumes after an empty pane |
| Bridge | Admission, quota gate, deny-default worker sandbox, worktrees, verify, ledger | Execution engine | Existing Bridge real-`ct` acceptance; do not bypass it for shipping work |
| TLDR 1.5.2 | Structure, calls, impact, dead-code analysis, cached `calls` graph, dirty-file incremental patching | Local structural query cache | No machine daemon; edit hook calls native `tldr.dirty_flag.mark_dirty`; `prove-tldr-incremental.sh` |
| CocoIndex 1.0.17 + knowledge-engine | Incremental semantic transform and Neo4j ingestion | Semantic retrieval producer | Existing on-change sync plus daily catch-up; Neo4j remains the sole shared graph |
| CocoIndex Code 0.2.37 | Per-project semantic index/search and structural grep | Optional interactive search | No always-on daemon and no second shared store |
| Graphify | Local AST graph, incremental `--update`, query/path/explain, optional Neo4j push | Unassigned | Not installed. A Neo4j schema/identity mapping and distinct consumer are required first |
| pi-mux-subagents 0.4.0 | Pi/Claude/Codex workers, guarded policies, headless or supported mux panes | Candidate only | Not installed: full-permission third-party extension, two-star repo, and no Mintmux adapter (supports Herdr/cmux/tmux/zellij/WezTerm) |
| CrewAI / LangChain | Agent/application frameworks | Unassigned | Not installed; they would duplicate Bridge orchestration without a missing requirement |
| Cline | IDE agent surface | Unassigned | Not installed; Cursor/Codex/Claude/Pi already cover the interaction surface |

Primary references:

- Pi: <https://pi.dev/docs/latest>
- Pi security: <https://pi.dev/docs/latest/security>
- Pi SDK and RPC: <https://pi.dev/docs/latest/sdk> and <https://pi.dev/docs/latest/rpc>
- Pi subagent candidate: <https://pi.dev/packages/%40aphotic/pi-mux-subagents>
- Graphify: <https://github.com/Graphify-Labs/graphify>

Prior-art check: GitHits returned a custom-multiplexer Pi worker pattern and an
exact-version Home Manager activation pattern on 2026-07-23. The implementation
uses Mintmux's existing `new-session`/`list-panes`/`attach` commands and a single
line-oriented receipt rather than adding a second session manager or package
database.

## Representation-first ownership

`config/agent-toolchain.tsv` is the primary version receipt. Installed package
state is derived and checked; `MACHINE.md` explains roles but does not duplicate
versions. This keeps the common operation dense and line-oriented while the
reconciler computes current state from npm and uv metadata.

TLDR stores a repository-local dirty-file set, not a permanently running global
object. On an edit, the hook records one relative path. On the next `tldr calls`
query, TLDR patches only those paths and clears the marker. In 1.5.2, `impact`
does not consume this cache; it rebuilds directly from current source. The older
ticket premise that a warm cache made `impact` stale was therefore wrong.
CocoIndex separately owns semantic transforms into Neo4j. These are different
representations for different access patterns, not competing sources of truth.

## Model and security rules

- `ct` heavy: `deepseek/deepseek-v4-pro`.
- `ct` routine and light: `deepseek/deepseek-v4-flash`. Kimi is removed from
  the actual wrapper, not merely from documentation.
- Pi starts without a default provider and requires `/login`. Prefer ChatGPT
  Plus/Pro or GitHub Copilot for the cockpit. Pi's current official provider
  documentation warns that Claude Pro/Max authentication through third-party
  harnesses uses paid extra usage rather than Claude plan limits.
- Pi project trust stays `ask`. Trust controls project-local extensions; it is
  not a sandbox. Pi and its extensions run with the starting user's permissions.
- `pi-mux-subagents` is not granted full access automatically. If adopted later,
  `guarded` is mandatory and a Mintmux adapter or explicit headless decision is
  required.

## Axiom and proof mapping

| Concern | Axiom | Proof form |
|---|---|---|
| Do not grant a new extension ambient machine authority without a task | `AX-ORACLE-AUTHZ-016` least privilege | trust remains `ask`; extension absent |
| Version reconciliation must not silently pass a mismatch | `AX-ORACLE-MONITOR-021` fail closed | reconciler exits nonzero on missing/mismatched packages |
| Rebuilds converge to the same approved versions | `AX-ORACLE-FRAMEWORK-012` idempotency | run reconciler twice; second run performs no installs |
| Warm/index work cannot hang indefinitely | `AX-OST-027` bounded blocking | fixture warm has a 30-second subprocess deadline |
| Adding/changing one tool has bounded ownership | `AX-SAIP-006` change localization | one TSV receipt + one reconciler |

The edit marker serializes updates to TLDR's upstream `dirty.json` with a
one-second bounded lock. The integration prove launches two markers
concurrently and requires both relative paths to survive.

Formal proof is not the default for every change. Use a model/proof for temporal
or state-machine invariants, property tests for broad input spaces, integration
tests for process boundaries, and direct receipts for configuration/runtime
facts. A proof of the wrong abstraction is not stronger evidence.

## Operator handoff after merge

1. Reconcile the unrelated dirty dotfiles checkout, then run `./rebuild.sh`.
2. Run `reconcile-agent-toolchain.sh check` and `prove-tldr-incremental.sh`.
3. Run `pi-cockpit`. In Pi, use `/login` and complete ChatGPT or Copilot OAuth.
4. Approve project trust only for repositories whose project-local resources
   have been reviewed.
5. Do not install the subagent extension until its source and Mintmux boundary
   have a separate accepted ticket.
