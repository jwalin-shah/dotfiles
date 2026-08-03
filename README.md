# dotfiles

**Captain entry (this machine):** nix-darwin + home-manager constitution for the
fleet. Start here:

1. [`docs/SYSTEM_MAP.md`](docs/SYSTEM_MAP.md) — how Pi / Bridge / HomeBase / KE / Firstmate link  
2. [`docs/OPERATING.md`](docs/OPERATING.md) — how to use it: commits, worktrees, daily loop  
3. [`MACHINE.md`](MACHINE.md) — what is installed, PARKED, REMOVED, WAIVER  
4. [`AGENTS.md`](AGENTS.md) — agent instructions for this repo  
5. `bin/prove-docs-freshness.sh` — **forced** doc freshness (also via `prove-launchers.sh`)
6. `~/projects/agent-os/bin/prove-all.sh` — joint frankenstein substrate prove

```sh
./rebuild.sh                          # apply nix (Tier 3)
bin/prove-docs-freshness.sh           # docs match live machine
bin/prove-launchers.sh                # PATH + LaunchAgents + nested proves
~/projects/agent-os/bin/prove-all.sh  # Pi/Bridge/HB/mintmux/Neo4j/trajectory
```

---

## What this is

One machine. One command: `./rebuild.sh`. This repo defines everything that
survives a fresh macOS install — system defaults, packages, LaunchAgents,
shell, agent configs, skills, and prove gates.

The repo is public at `https://github.com/jwalin-shah/dotfiles.git`.
It is **this machine's** constitution, not a template. Clone it to
understand the fleet, not to run it on your own Mac.

## Architecture

```
flake.nix              Entry point — nixpkgs, nix-darwin, home-manager, nix-homebrew
configuration.nix      System layer — macOS defaults, Homebrew, LaunchAgents
home.nix               User layer — packages, shell, symlinks, agent configs
home/                  Live config files (Neovim, Claude, Codex, Cursor, Gemini)
.agents/               Skill definitions (projected into agent configs on rebuild)
config/orbit/          models.env — single switch for all AI model providers
bin/                   Wrappers (ca, ct, cx) + prove-*.sh gates
docs/                  SYSTEM_MAP, OPERATING, and linkage docs
```

## Daily use

```sh
./rebuild.sh              # Apply all nix changes (Tier 3 — captain approved)
```

Edit files under `home/` directly — they're symlinked live via
`mkOutOfStoreSymlink`, no rebuild needed. Only rebuild when you change a
package list, system default, LaunchAgent, or skill definition.

### Fresh machine

```sh
./bootstrap.sh            # One-time: install Nix → symlink repo → first switch
```

`bootstrap.sh` installs Determinate Nix, symlinks the repo to `~/.dotfiles`,
matches the flake username to `whoami`, and runs the first
`darwin-rebuild switch`. After that, `./rebuild.sh` handles every later change.

## Agent configs

All agent configs live under `home/` and are nix-symlinked to their runtime
locations. **Never edit live files under `~/.claude/`, `~/.codex/`, etc.** —
change them in this repo and rebuild.

| Lane | Config dir | Purpose |
|---|---|---|
| `ca` | `home/.claude/` | Claude direct (OAuth) |
| `ct` | `home/.claude-token/` | TokenRouter — API key via Keychain `apiKeyHelper` |
| `cx` | `home/.codex/` | Codex CLI config + hooks |
| `cursor` | `home/.cursor/` | Cursor agent config |
| `agy` | `home/.gemini/` | Gemini CLI config |

Each Claude lane store is self-sufficient — its own `settings.json` carries
routing, model defaults, and `apiKeyHelper`. **This repo is public — no keys
are stored in it.** Keys come from the `bridge-secrets` Keychain at runtime.

## Prove gates

```sh
bin/prove-docs-freshness.sh    # MACHINE.md + SYSTEM_MAP match live reality
bin/prove-skills.sh            # Required skills present under .agents/
bin/prove-launchers.sh         # PATH + LaunchAgents + nested proves (includes docs)
bin/prove-harness-hooks.sh     # Hooks consistent across Claude/Codex/Cursor/Gemini
```

All prove commands must exit 0. If you change services, skills, or spawn gates,
update `MACHINE.md` and/or `docs/SYSTEM_MAP.md` in the same commit.

## Related

- [`docs/SYSTEM_MAP.md`](docs/SYSTEM_MAP.md) — how the fleet connects
- [`docs/OPERATING.md`](docs/OPERATING.md) — day-to-day: commits, worktrees, daily loop
- [`MACHINE.md`](MACHINE.md) — full inventory (packages, LaunchAgents, models, PARKED/WAIVER)
- [`GLOBAL.md`](GLOBAL.md) — machine principles projected to all agent configs
- `~/projects/portfolio/wayfinder/one-surface-system-2026-07-30/map.md` — living system detail

## License

This repo is licensed under MIT No Attribution.
See `LICENSE`.
