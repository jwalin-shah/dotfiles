# Ticket 002 — Pin and rationalize the agent toolchain

**Status:** implementation and local proof complete; live activation pending
**Opened:** 2026-07-23
**Owner:** dotfiles

## Goal

Make Pi a Mintmux-hosted interactive cockpit without replacing Bridge; pin the
agent toolchain; remove Kimi from the real TokenRouter wrapper; and replace the
machine-wide TLDR restart loop with native repository-local incremental cache
invalidation.

## Acceptance

- [x] Capability inventory written before integration.
- [x] One exact npm/uv version receipt with fail-closed reconciliation.
- [x] Pi project trust defaults to `ask`; no third-party Pi extension installed.
- [x] `pi-cockpit` starts, reattaches, and resumes Pi in a Mintmux session;
      the three lifecycle paths have a deterministic fake-backend prove.
- [x] Kimi absent from `ct-wrapper`; Flash owns routine/light routing.
- [x] TLDR LaunchAgent removed from declarative config and live prove list.
- [x] On-edit hook marks one repo-relative file dirty using TLDR's native API.
- [x] Integration prove demonstrates lazy one-file `calls` patching, fresh
      `impact`, and a bounded warm.
- [ ] Home Manager activation on the captain's dirty main checkout.
- [ ] Interactive Pi `/login` (human OAuth boundary).

## Non-goals

- Replacing Bridge with Pi, CrewAI, Cline, or LangChain.
- Installing `pi-mux-subagents` before a source review and Mintmux decision.
- Adding Graphify as a second shared graph producer.
- Automating OAuth or storing provider secrets in dotfiles.
