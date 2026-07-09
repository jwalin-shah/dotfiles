# Separation Policy — What to Canonicalize vs. What to Keep Apart

The symlink architecture (`SYMLINK_ARCHITECTURE.md`) makes shared things canonical.
This doc is its counterweight: the things that MUST stay separate. Symlinking these
would silently break account isolation, leak secrets, or destroy project identity.

Core rule: **symlink the contract, isolate the identity and the secrets.**

There are two layers. Keep them distinct.

---

## Layer 1 — Shared Contract (CANONICAL, symlink to ~/.agent-rules/)

These are rules everyone follows. One source, many symlinks. Editing once
propagates everywhere — that is the goal.

| File | Why canonical |
|------|---------------|
| GLOBAL.md | The contract is identical for every agent |
| TOOL_REGISTRY.md | Tool routing policy is universal |
| AGENTS.md | Cross-agent routing table is shared |
| ROUTING_GUIDE.md | Launcher reference is the same everywhere |
| CLAUDE.md template body | The instruction skeleton is shared |
| hooks/ logic | Hook behavior should be consistent across agents |

---

## Layer 2 — Identity & State (SEPARATE, never symlink)

These are what make each agent, project, and machine distinct. If you symlink
them you erase the distinction. They look duplicative but the differences are
load-bearing.

| File / dir | Why it MUST stay separate | What breaks if merged |
|------------|---------------------------|------------------------|
| `~/.claude-*/settings.json` | Different model, statusLine tag `[ca]`/`[cb]`, Keychain dir, Infisical path per account | All accounts collapse to one identity; rollover can't tell them apart |
| Per-account OAuth tokens / Keychain | Each account authenticates separately | Auth corruption, cross-account token bleed |
| `~/.pioneer/config.json` | Live API key | **Secret leak** if shared/committed |
| `settings.local.json` | Machine-specific local overrides (gitignored) | Local quirks leak to other machines |
| `~/STATE.md` | Live session state, machine-specific, time-sensitive | Stale/foreign state injected into wrong session |
| Project `CONTEXT.md` | Domain language is project-local BY DESIGN | orbit's consensus vocabulary bleeds into m3lab's swarm vocabulary |
| Project `docs/adr/` | Each project's architectural decisions | Decisions from one project misapplied to another |
| Project `axioms/AXIOMS.md` | Project-scoped rule ledger | Orbit axioms wrongly enforced on unrelated code |
| Data files (`*.jsonl`, `*-runs/`) | Never tracked, never shared (see .gitignore) | Repo bloat, run-data cross-contamination |

---

## Layer 3 — The Bridge (per-project, NOT symlinked, but DISCOVERED)

This is how separated project state still reaches any agent that walks in,
without merging it. The project broadcasts; the agent reads on entry.

| File | Role |
|------|------|
| `<project>/.claude/config.json` | Project's self-description: name, domain, which local files to load |

The discovery hook reads this on `cd` and injects `CONTEXT.md` / `AXIOMS.md`
**by reference, into that session only**. The project's identity stays local;
the agent just learns where to look. Separation preserved, knowledge shared.

---

## Decision Test (apply before symlinking anything)

Ask three questions. Any "yes" → keep it SEPARATE:

1. **Does it contain a secret or credential?** → separate, and check .gitignore.
2. **Does it encode identity** (which account, which project, which machine)? → separate.
3. **Is it live/mutable state** that changes within a session? → separate.

If all three are "no" and it's a rule/contract/template → canonicalize it.

---

## Why This Matters (the failure mode it prevents)

The tempting mistake is "symlink everything to one source for consistency."
That works for contracts and destroys everything else:

- Symlink the per-account `settings.json` → `ca` and `cb` become indistinguishable,
  rollover routing breaks, the statusLine lies about which account you're on.
- Symlink project `CONTEXT.md` → every project speaks orbit's domain language;
  the whole point of per-project domain modeling is gone.
- Symlink/commit secrets → key leak.

Consistency is for the contract. Isolation is for identity. The bridge layer
(`.claude/config.json` discovery) is what lets you have both at once.
