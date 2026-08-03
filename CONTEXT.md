# dotfiles — Machine constitution

One machine. One command: `./rebuild.sh`. This repo defines everything
that survives a fresh macOS install.

**Read first:** [`docs/SYSTEM_MAP.md`](docs/SYSTEM_MAP.md) — how Orbit, Bridge,
HomeBase, Knowledge Engine, Seatbelt, and LaunchAgents link.  
**Day-to-day (commits, worktrees):** [`docs/OPERATING.md`](docs/OPERATING.md).  
Inventory: [`MACHINE.md`](MACHINE.md). Principles: [`GLOBAL.md`](GLOBAL.md).

**Freshness is forced:** `bin/prove-docs-freshness.sh` (also from `prove-launchers.sh`).
If you change services, skills, or spawn gates, update MACHINE.md / SYSTEM_MAP in
the same change or the prove fails.

## Architecture

```
configuration.nix     nix-darwin — LaunchAgents, Homebrew, system daemons
home.nix              home-manager — packages, symlinks, agent configs, skills
GLOBAL.md             Machine principles → ~/CLAUDE.md
MACHINE.md            Inventory SoT (what is installed / PARKED / WAIVER)
docs/SYSTEM_MAP.md    How the fleet connects + spawn checklist
home/.                Agent configs (Claude, Codex, Cursor, Gemini)
.agents/              Skill source (projected on rebuild)
config/orbit/         models.env — single switch for all AI models
bin/                  Wrappers + prove-*.sh gates
```

## Rebuild

```bash
./rebuild.sh              # Apply all nix changes (Tier 3 — captain approved)
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
