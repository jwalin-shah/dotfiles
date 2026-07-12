# dotfiles — Mac setup via nix-darwin + home-manager

This repo is a fork of `kunchenguid/dotfiles` with a `captain/` overlay. One
machine. One command: `./rebuild.sh`.

## Architecture

```
configuration.nix     nix-darwin — LaunchAgents, Homebrew brews/casks, system daemons
home.nix              home-manager — packages, aliases, config symlinks, all inline
captain/
  bin/                 launcher wrappers (all bash, all ≤5 lines, all exec to real binary)
    *-wrapper          claude, ca, ct, agy, cu, cx, ko, kt, oo, ot
    openwiki            npm openwiki launcher
    jw-restart          jw-* service restarter
  bin/tools/           personal tool wrappers (c, rb, route, cognee, brave-*, etc.)
  config/
    models.env          ML model paths (sourced by mlx-chat-server)
    opencode.json       OpenCode provider config
home/                  agent configs — symlinked into ~/ by home.nix
bin/                   utility scripts — audit, prune, docs
docs/                  architecture docs, Theo principles
```

## Rules

### Upstream decisions (do NOT revert)

- `homebrew.onActivation.cleanup = "zap"` is intentional. It forces declaring every
  Homebrew package in `configuration.nix`. Do not soften.
- Never commit `.no-mistakes/` validation evidence.
- Run `bin/audit-config-ownership.sh` and `bin/audit-doc-freshness.sh` to verify
  the repo is clean before treating it as current.

### Design principles (from Theo Browne's AI Psychosis)

These apply to EVERY change in this repo:

1. **Skeuomorphism is dead.** No Python exec-wrappers. No config-layer frameworks.
   Every wrapper is ≤5 lines of bash with `exec` to the real binary.
2. **Delete ruthlessly.** Sunk cost is the enemy. The diff should be net-negative.
   If a file exists because "someone might need it" — delete it.
3. **The Markdown tier.** Start with a prompt. Only add code when the prompt breaks.
4. **Width over depth.** Thin wrappers covering the spectrum. No deep framework.
5. **Secrets in env/keychain, never in files.** No hardcoded keys. No .env files.
   Use `secret-cache` backed by macOS Keychain.
6. **One source of truth.** Dotfiles owns the machine. No competing Nix configs.
7. **verify before keep.** For every file: does it exist? Is it referenced? Is it
   still needed? If any answer is no, delete it.

Full talk: `docs/theo-browne-ai-psychosis.md`

### Cleanup standards

- `configuration.nix` owns all Homebrew packages. If you `brew uninstall` something,
  remove it from `configuration.nix` too or the next rebuild reinstalls it.
- Every `home.file."bin/..."` entry must have a matching source file in `captain/bin/`.
- Every LaunchAgent must reference a binary that exists.
- No Python exec-wrappers. All launchers are bash with `exec`.
- No hardcoded `/Users/jwalinshah/` paths — use `${user}` or `$HOME`.
- The `services.conf` in `~/.config/jw/` tracks runtime services; keep it current.
- Run `jw-watch` to verify all services are healthy.

### Launcher map

```
~/bin/claude → Nix → claude-wrapper → npx @anthropic-ai/claude-code
~/bin/ca     → Nix → ca-wrapper      → npx + OAuth config
~/bin/ct     → Nix → ct-wrapper      → secret-cache exec → npx + TokenRouter
~/bin/agy    → Nix → agy-wrapper     → /opt/homebrew/bin/agy
~/bin/cx     → Nix → cx-wrapper      → /opt/homebrew/bin/codex
~/bin/cu     → Nix → cu-wrapper      → Cursor.app
~/bin/ko     → Nix → ko-wrapper      → /opt/homebrew/bin/kilo
~/bin/kt     → Nix → kt-wrapper      → secret-cache exec → /opt/homebrew/bin/kilo
~/bin/ot     → Nix → ot-wrapper      → secret-cache exec → /opt/homebrew/bin/opencode
~/bin/oo     → Nix → oo-wrapper      → /opt/homebrew/bin/opencode
```

One symlink. One bash wrapper. One real binary. No loops.

### Important

- The LaunchAgents in `configuration.nix` reference binaries in `~/.local/bin/` and
  `~/bin/` that are NOT managed by Nix. They must be built separately by each project.
- When pulling upstream, only `flake.nix` and `home.nix` need conflict resolution.
  The `captain/` directory is entirely additive.

## Agent skills

### Issue tracker

GitHub Issues at `jwalin-shah/dotfiles`. Use the `gh` CLI for all operations. See `docs/agents/issue-tracker.md`.

### Triage labels

Default canonical labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context repo. Read `CONTEXT.md` at root and `docs/adr/` for architectural decisions. See `docs/agents/domain.md`.
