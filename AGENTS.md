# Dotfiles — agent instructions

This repo is the **machine constitution** (nix-darwin + home-manager).

## Read first

1. [`docs/SYSTEM_MAP.md`](docs/SYSTEM_MAP.md) — how Pi / Bridge / HomeBase / KE / Firstmate link  
2. [`MACHINE.md`](MACHINE.md) — inventory, PARKED, REMOVED  
3. [`GLOBAL.md`](GLOBAL.md) — five non-negotiable principles  
4. [`docs/OPERATING.md`](OPERATING.md) — commits, worktrees, lanes  

Living topology (portfolio):  
`~/projects/portfolio/wayfinder/system-of-systems-2026-08-01/map.md`

Joint prove: `~/projects/agent-os/bin/prove-all.sh`

## Rules for agents in this repo

- Do not re-enable PARKED/REMOVED services (mlx-chat, cocoindex-daemon, Ladybug writers).  
- Do not invent LaunchAgents without updating MACHINE.md + SYSTEM_MAP in the same change.  
- `bin/prove-docs-freshness.sh` must pass after doc/inventory edits.  
- Tier-3 (`./rebuild.sh`) only with explicit captain approval.  
- Captain surface is **Pi**, not Orbit.

## Prove

```bash
bin/prove-docs-freshness.sh
bin/prove-skills.sh
bin/prove-launchers.sh
```

After rebuild, restart services if needed:
```bash
launchctl kickstart -k gui/$UID/org.nixos.<service-name>
```

## Adding a new tool or daemon

1. Declare in `configuration.nix` (brew/LaunchAgent) or `home.nix` (npm/uv/skill)
2. Document in `MACHINE.md` (+ `docs/SYSTEM_MAP.md` if it changes how pieces link)
3. Run `bin/prove-docs-freshness.sh` then `./rebuild.sh`

## Agent config management

All agent configs in `home/` are nix-symlinked to their runtime locations.
Changes MUST be made in this repo and applied via rebuild — never edited only
under `~/.claude/`, `~/.codex/`, etc.

Skills: edit `dotfiles/.agents/<name>/`, prove with `bin/prove-skills.sh`, rebuild
to project durably.

Claude lanes: each store (`home/.claude`, `.claude-a`, `.claude-token`,
`.claude-pioneer`) owns its own `settings.json` and carries its own routing, so a
bare `claude` with only `CLAUDE_CONFIG_DIR` set behaves like its `bin/*-wrapper`.
**This repo is public — never write a key into one.** Keys come from the
`bridge-secrets` Keychain via `apiKeyHelper`; see the lane table in `MACHINE.md`.
Editing an already-declared `mkOutOfStoreSymlink` target is live with no rebuild;
declaring a *new* file in `home.nix` needs `./rebuild.sh`.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
