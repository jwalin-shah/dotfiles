# dotfiles — Mac setup via nix-darwin + home-manager

This repo is a fork of `kunchenguid/dotfiles` with a `captain/` overlay. One
machine. One command: `./rebuild.sh`.

## Architecture

```
configuration.nix     nix-darwin — LaunchAgents, Homebrew brews/casks, system daemons
home.nix              home-manager — packages, aliases, config symlinks, all inline
captain/
  bin/                 launcher wrappers (all bash, all ≤5 lines, all exec to real binary)
    *-wrapper          claude, ca, ct, agy, cua, cx, ko, kt, oo, ot
    openwiki            npm openwiki launcher
    jw-restart          jw-* service restarter
  bin/tools/           personal tool wrappers (ctx7, brave-automation, cursor-login)
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
   Use the Bridge secret adapter backed by macOS Keychain.
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
~/bin/ct     → Nix → ct-wrapper      → Bridge Keychain → Claude Code + TokenRouter
~/bin/agy    → Nix → agy-wrapper     → /opt/homebrew/bin/agy
~/bin/cx     → Nix → cx-wrapper      → /opt/homebrew/bin/codex
~/bin/cua    → Nix → cua-wrapper     → Cursor.app
~/bin/ko     → Nix → ko-wrapper      → /opt/homebrew/bin/kilo
~/bin/kt     → Nix → kt-wrapper      → Bridge Keychain → /opt/homebrew/bin/kilo
~/bin/ot     → Nix → ot-wrapper      → Bridge Keychain → /opt/homebrew/bin/opencode
~/bin/oo     → Nix → oo-wrapper      → /opt/homebrew/bin/opencode
```

One symlink. One bash wrapper. One real binary. No loops.

### Binary sources (not built by Nix)

The LaunchAgents in `configuration.nix` reference pre-built binaries in
`~/.local/bin/` and `~/bin/`. These are NOT managed by Nix — each comes
from its own project and must be built separately.

| Binary | Source project | Language | Notes |
|--------|---------------|----------|-------|
| `m5fand` | `~/projects/m5tools` | C | Fan control daemon. m5tools has no AGENTS.md; binaries survive without the source repo being active. |
| `m5logd` | `~/projects/m5tools` | C | Hardware logging daemon. Same situation as m5fand. |
| `voice-engine` | `~/projects/voice-engine-swift` | Swift | Menubar dictation app. Built via `make` or `swift build`. |
| `jw` | `~/projects/jw-core` | Go | Orchestrator backend. Built via `make` or `go build`. |
| `treehouse` | `~/projects/treehouse` | Go | Git worktree pool manager. |
| `mintmux` / `mm-ctl` | `~/projects/mintmux` | Go | PTY multiplexer. |
| `cocoindex` | `~/projects/cocoindex` | Rust+Python | Semantic code index. |

Note: `jw-core`, `jw-agentd`, `jw-watcher`, `jw-adblock` exist on GitHub
(`jwalin-shah`) but are not currently cloned or built locally. The `jw`
binary in `~/.local/bin` was built from `jw-core` and survives independent
of the source repo.

After the July 2026 LaunchAgent cleanup: dead daemons were removed,
all remaining LaunchAgents reference direct binaries (no wrapper scripts),
and every referenced binary has a corresponding source project.

### Important

- The binary-source mapping is documented above. Each binary's source project
  must be built separately; Nix does not build them.
- When pulling upstream, only `flake.nix` and `home.nix` need conflict resolution.
  The `captain/` directory is entirely additive.

## Agent skills

### Issue tracker

GitHub issues. See `docs/agents/issue-tracker.md`.

### Triage labels

Default Matt Pocock vocabulary. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout. See `docs/agents/domain.md`.
