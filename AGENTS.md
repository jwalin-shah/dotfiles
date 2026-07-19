# dotfiles — Orbit machine config

One machine. One command: `./rebuild.sh`. This repo defines everything
that survives a fresh macOS install.

## Architecture

```
configuration.nix     nix-darwin — LaunchAgents, Homebrew, system daemons
home.nix              home-manager — packages, symlinks, agent configs
GLOBAL.md             Machine principles → ~/CLAUDE.md
home/.                Agent configs (Claude, Codex, Cursor, Gemini)
config/orbit/         models.env — single switch for all AI models
bin/                  Shell wrappers (ca, ct, ap, daemon-wrapper, fmt-on-edit)
```

## Rebuild

```bash
./rebuild.sh              # Apply all nix changes
```

After rebuild, restart services:
```bash
launchctl kickstart -k gui/$UID/org.nixos.<service-name>
```

## Adding a new tool

1. Declare in `configuration.nix` (brew) or `home.nix` (npm/uv)
2. Document in `MACHINE.md`
3. Run `./rebuild.sh`

## Agent config management

All agent configs in `home/` are nix-symlinked to their runtime locations.
Changes to agent configs MUST be made in dotfiles and applied via rebuild,
never edited directly in `~/.claude/`, `~/.codex/`, etc.
