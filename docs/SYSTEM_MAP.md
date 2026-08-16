# System map — how this machine links together

**Owner:** dotfiles (machine constitution)  
**Living detail (topology + intent):** `~/projects/portfolio/wayfinder/system-of-systems-2026-08-01/map.md`  
**Control plane / proves:** `~/projects/agent-os/` (`bin/prove-all.sh`)  
**Prove (this repo):** `bin/prove-docs-freshness.sh` (also run from `prove-launchers.sh`)  
**Day-to-day use / commits / worktrees:** [`OPERATING.md`](OPERATING.md)

This file is the **short** map. If MACHINE.md and this disagree, MACHINE.md wins for inventory; this file wins for *how pieces connect*. Fix both in the same change. OPERATING.md wins for *how humans and agents commit and use worktrees*.

## One sentence

Captain talks to **Pi** → Firstmate runs the fleet and/or **Bridge** admits/grants/spawns → **Mintmux** runs Bridge workers → Knowledge Engine/Neo4j feeds context → **HomeBase** must admit the grant → prove commands decide done. Dotfiles only decides **what may exist and run** on the Mac.

```text
YOU (captain)
  └─ Pi  (one surface)
        ├─ Firstmate (~/firstmate) — backlog, crewmates, tmux/herdr
        └─ Bridge CLI (~/.local/bin/bridge)
              ├─ freeze ← portfolio machine-capability-manifest.json
              ├─ Neo4j + embeds + KE   (context)
              ├─ Seatbelt / VM / container  (isolation)
              ├─ HomeBase URL+keys     (grant — REQUIRED for spawn)
              └─ mintmux               (worker PTY)
```

**Orbit** remains a thin CLI over Bridge (optional). It is **not** the captain home chat.  
**bridge-serve** LaunchAgent is **optional / often absent**; CLI Bridge is the spine.

## Who owns what

| Piece | Repo | Role on this machine |
|---|---|---|
| Dotfiles | `~/projects/dotfiles` | Constitution: packages, LaunchAgents, hooks, skills projection, prove scripts |
| Pi | pi-coding-agent | Captain-facing one surface |
| Firstmate | `~/firstmate` | Fleet router (crewmates / backlog) |
| Bridge | `~/projects/bridge` | Spawn/verify/deliver/ledger; Seatbelt; live binary `~/.local/bin/bridge` |
| HomeBase | `~/projects/homebase` | Contract/grant admission + receipts (**must be configured for spawn**) |
| Mintmux | `~/projects/mintmux` | Bridge worker sessions |
| Knowledge Engine | `~/projects/knowledge-engine` | Writes Neo4j (dumb pipe) |
| Axioms | `~/projects/axioms` | Principle corpus → KE |
| Portfolio | `~/projects/portfolio` | Decisions / Wayfinder maps (not a daemon) |
| Trajectory | `~/projects/trajectory` | Transcript normalize + claims evidence |
| agent-os | `~/projects/agent-os` | Frankenstein wiring + joint prove-all |
| Orbit | `~/projects/orbit` | Thin Bridge client only (non-primary) |
| RMC / RMF | `running-machine-*` | Joint contracts + disposable proofs |

## Always-on vs on-demand

**Always-on (declared LaunchAgents / brew services)** — see MACHINE.md:

- neo4j, llama-embed :8081, coderank-embed :8082, mintmux, homebase-drive :9847,
  inbox-server :9849, m5logd, ai.openai.life-ops-inbox-tunnel, …

**On-demand:**

- Bridge CLI, Pi, Firstmate, most of `~/projects/*`  
- Agent wrappers (`ca`/`ct`/…) — started per session  
- Codex → Inbox read-only MCP — local stdio child process; the private Inbox API remains on loopback
- bridge-serve — optional gRPC surface (not required for CLI spine)

**PARKED / REMOVED (do not re-enable without ticket + rebuild):**

- mlx-chat :8080 — PARKED  
- cocoindex-daemon — REMOVED  
- knowledge-engine daily LaunchAgent, bridge-serve, bridge-cdp-quota, voice-engine, overnight-harden, verify-machine — REMOVED 2026-07-31  
- Ladybug writers — frozen (Neo4j sole store)

## Isolation (do not confuse these)

| Mode | Meaning | When |
|---|---|---|
| `seatbelt-compat` | macOS `sandbox-exec` write deny-default to `allowed_paths` | Only with `BRIDGE_ALLOW_UNSAFE_LOCAL_MODE=1` for local drive |
| `vm` | Production confidentiality target | **Not certified yet** |
| `apple-container` | Typed container boundary | Needs certified probes |
| `--no-sandbox` | Forbidden when production isolation required | Do not use for real work |

**Live drive fact:** pre_spawn can pass and still fail closed if HomeBase URL+keys are missing. Source `~/projects/agent-os/bin/env-bridge.sh` before spawn.

## Spawn checklist (CLI spine)

1. `bridge freeze` green (manifest matches live dotfiles)  
2. `source ~/projects/agent-os/bin/env-bridge.sh` — sets `BRIDGE_HOMEBASE_URL` + key file paths  
3. Ticket has `tensor_equation`, `proof_method`, paths, accept criteria  
4. Isolation admitted (unsafe-local seatbelt **or** real VM/container)  
5. Neo4j + embeds healthy if context needed  
6. Watch: ledger + mintmux pane + trajectory (watching ≠ authorizing)  
7. `~/projects/agent-os/bin/prove-all.sh` exit 0  

## Incremental knowledge path

```text
file edit → fmt-on-edit → tldr-mark-dirty + neo4j-on-change
         → on-change-sync (structure + CALLS)
         → optional cocoindex embed catch-up (NOT cocoindex-daemon)
```

## Skills (craft layer)

Canonical source: `dotfiles/.agents/`.

```bash
bin/prove-skills.sh
```

## Doc freshness rule

- Inventory claims → MACHINE.md  
- Connection / authority claims → this file  
- Cross-project decisions → portfolio Wayfinder (`system-of-systems-2026-08-01`)  
- Joint substrate prove → `agent-os/bin/prove-all.sh`  
- Any change to LaunchAgents, isolation env, or spawn gates **must** update MACHINE.md and/or this file in the same change  
- CI/local gate: `bin/prove-docs-freshness.sh` must exit 0  

## Prove commands (machine bar)

```bash
bin/prove-docs-freshness.sh
bin/prove-skills.sh
bin/prove-launchers.sh
~/projects/agent-os/bin/prove-all.sh
bridge freeze
```
