# Project notes for agents

This repo is a fork of `kunchenguid/dotfiles` with a `captain/` overlay on top.

## Upstream decisions (do NOT revert)

- `homebrew.onActivation.cleanup = "zap"` in `configuration.nix` is intentional.
  It forces declaring every Homebrew package in the Nix config instead of installing ad-hoc.
  Do not soften it to `uninstall` or `none`.
- Never commit `.no-mistakes/` validation evidence to this public repo.
- Use `bin/audit-config-ownership.sh` to verify live config ownership and catch stale active references before calling the repo clean.
- Use `bin/audit-doc-freshness.sh` to verify active docs do not contain stale
  machine references or broken local links before treating the repo as current.
  It is for markdown docs only; config drift belongs in the ownership audit.

## Captain overlay structure

All captain-specific customizations live in `captain/` to keep upstream merge conflicts minimal:

```
captain/
  system.nix         nix-darwin module (LaunchAgents, extra Homebrew items)
  user.nix           home-manager module (extra packages, aliases, symlinks)
  config/
    opencode.json         OpenCode config (TokenRouter only)
    models.env            Local AI model config for MLX/cognee
```

Patched upstream files (minimal edits):
- `flake.nix` — user changed to "jwalinshah", added `./captain/system.nix` to modules
- `home.nix` — added `imports = [ ./captain/user.nix ]`

## Important

- The LaunchAgents in `captain/system.nix` reference binaries in `~/.local/bin/` and `~/bin/`
  that are NOT managed by Nix. They must be built separately by each project's build system.
- `start-mlx-server.sh` sources `~/.config/jw/models.env` (symlinked via captain/user.nix).
- When pulling upstream changes, only `flake.nix` and `home.nix` need conflict resolution.
  The `captain/` directory is entirely additive.
