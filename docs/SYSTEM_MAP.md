# System map — how this machine links together

**Owner:** dotfiles (machine constitution)  
**Living detail:** `~/projects/portfolio/wayfinder/one-surface-system-2026-07-30/map.md`  
**Prove:** `bin/prove-docs-freshness.sh` (also run from `prove-launchers.sh`)  
**Day-to-day use / commits / worktrees:** [`OPERATING.md`](OPERATING.md)

This file is the **short** map. If MACHINE.md and this disagree, MACHINE.md wins for inventory; this file wins for *how pieces connect*. Fix both in the same change. OPERATING.md wins for *how humans and agents commit and use worktrees*.

## One sentence

Captain talks to **Orbit** → Bridge admits/grants/spawns → Mintmux runs the worker → Knowledge Engine/Neo4j feeds context → HomeBase must admit the grant → prove commands decide done. Dotfiles only decides **what may exist and run** on the Mac.

```text
YOU (captain)
  └─ orbit status | orbit "atom" [--yes]
        └─ bridge-serve :9100/:9101  (LaunchAgent)
              ├─ Neo4j + embeds + KE   (context)
              ├─ Seatbelt / VM / container  (isolation)
              ├─ HomeBase URL+keys     (grant — REQUIRED for spawn today)
              └─ mintmux               (worker PTY)
```

## Who owns what

| Piece | Repo | Role on this machine |
|---|---|---|
| Dotfiles | `~/projects/dotfiles` | Constitution: packages, LaunchAgents, hooks, skills projection, prove scripts |
| Orbit | `~/projects/orbit` | Captain-facing thin CLI over Bridge gRPC |
| Bridge | `~/projects/bridge` | Spawn/verify/deliver/ledger; Seatbelt profiles; live binary `~/.local/bin/bridge` |
| HomeBase | `~/projects/homebase` | Contract/grant admission + receipts (**must be configured for spawn**) |
| Mintmux | `~/projects/mintmux` | Worker sessions |
| Knowledge Engine | `~/projects/knowledge-engine` | Writes Neo4j (dumb pipe) |
| Axioms | `~/projects/axioms` | Principle corpus → KE |
| Portfolio | `~/projects/portfolio` | Decisions / Wayfinder maps (not a daemon) |
| Trajectory | `~/projects/trajectory` | Transcript normalize + claims evidence |
| RMC / RMF | `running-machine-*` | Joint contracts + disposable proofs |

## Always-on vs on-demand

**Always-on (declared LaunchAgents / brew services)** — see MACHINE.md:

- `bridge-serve`, neo4j, llama-embed :8081, coderank-embed :8082, mintmux, knowledge-engine sync, verify-machine, overnight-harden, …

**On-demand (no random daemons):**

- Most of `~/projects/*` — CLIs and spawns only  
- Agent wrappers (`ca`/`ct`/…) — started per session  

**PARKED / REMOVED (do not re-enable without ticket + rebuild):**

- mlx-chat :8080 — PARKED  
- cocoindex-daemon — REMOVED  
- Ladybug writers — frozen (Neo4j sole store)

## Isolation (do not confuse these)

| Mode | Meaning | When |
|---|---|---|
| `seatbelt-compat` | macOS `sandbox-exec` write deny-default to `allowed_paths` | Only with `BRIDGE_ALLOW_UNSAFE_LOCAL_MODE=1` for local drive |
| `vm` | Production confidentiality target | **Not certified yet** — Bridge rejects until a disposable VM backend exists |
| `apple-container` | Typed container boundary | Separate path; needs certified probes |
| `--no-sandbox` | Forbidden when production isolation required | Do not use for real work |

**Live drive fact (2026-07-30):** pre_spawn can pass and still fail closed if HomeBase URL+keys are missing. Seatbelt unit tests ≠ live worker constraint prove.

## Spawn checklist (interim one-surface)

Before expecting `orbit "…" --yes` to run a worker:

1. Ticket has `tensor_equation`, `proof_method`, `specification_id/digest`, `approval_decision_id/digest`, `forbidden_paths`  
2. Isolation admitted (unsafe-local seatbelt **or** real VM/container)  
3. `BRIDGE_HOMEBASE_URL` + bridge private key + admission public key configured  
4. Neo4j + embeds healthy if context needed (`orbit status` / `bridge knowledge`)  
5. Watch: ledger + mintmux pane + trajectory (watching ≠ authorizing)

Detail: `portfolio/wayfinder/one-surface-system-2026-07-30/DRIVE_LOG.md`

## Skills (craft layer)

Canonical source: `dotfiles/.agents/` (home.nix projects into Claude/Codex/Cursor on rebuild).

Required for prove: preflight, wayfinder, grill-me, domain-modeling, codebase-design, setup-matt-pocock-skills, research, prototype, code-review.

```bash
bin/prove-skills.sh
```

Interim live links may exist under `~/.agents/skills` / `~/.cursor/skills-cursor`; **durable** projection needs captain-approved `./rebuild.sh` (Tier 3).

## Doc freshness rule

- Inventory claims → MACHINE.md  
- Connection / authority claims → this file  
- Cross-project decisions → portfolio Wayfinder  
- Any change to LaunchAgents, isolation env, or spawn gates **must** update MACHINE.md and/or this file in the same commit  
- CI/local gate: `bin/prove-docs-freshness.sh` must exit 0  

## Prove commands (machine bar)

```bash
bin/prove-docs-freshness.sh
bin/prove-skills.sh
bin/prove-launchers.sh
orbit status
bridge verify-machine   # daily LaunchAgent also runs this
```
