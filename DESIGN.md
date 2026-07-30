# Design

> Produced / maintained via the `codebase-design` skill. Required by portfolio universal-pocock-policy (2026-07-30).  
> Dotfiles is **machine infrastructure**, not an app. Design describes config layers and activation seams.

## Module map

| Module | Responsibility | May depend on |
|---|---|---|
| `flake.nix` | Wires nixpkgs, nix-darwin, home-manager, nix-homebrew; declares `mac` host | nix ecosystem |
| `configuration.nix` | System defaults, Homebrew, LaunchAgents, Neo4j/embed daemons | homebrew |
| `home.nix` | User packages, symlinks, shell, AXI wrapper aliases | flake user var |
| `home/` | Source-of-truth agent + editor + terminal configs | — |
| `bin/` | ct, openwiki, daemon-wrapper, fmt-on-edit, audit scripts | home.nix symlinks |
| `config/orbit/` | models.env and orbit machine config | — |
| `GLOBAL.md` | Machine principles installed to ~/CLAUDE.md | — |
| `bootstrap.sh` / `rebuild.sh` | First-time and incremental apply | darwin-rebuild |

## Dependency rules

- Allowed directions: flake → configuration.nix + home.nix → home/ files; LaunchAgents → project scripts in ~/projects
- Forbidden: editing live `~/.claude/` etc. directly (must change repo + rebuild); assuming TMPDIR-stable paths for services

## Interfaces / seams

- **Activation:** `./rebuild.sh` → `darwin-rebuild switch --flake .#mac`
- **Symlinks:** `mkOutOfStoreSymlink` — edit `home/` in place; rebuild only for non-symlink changes
- **Agent configs:** single `home/AGENTS.md` shared by Claude, Codex, opencode
- **Knowledge chain:** configuration.nix provisions Neo4j, embeds, KE daily catch-up; fmt-on-change → neo4j-on-change
- **Acceptance:** post-bootstrap `command -v openwiki ct treehouse` + AXI aliases

## Test strategy

- `nix flake check --no-build` and `nix build .#darwinConfigurations.mac.system --dry-run` before apply
- `bin/audit-config-ownership.sh` — live vs repo config parity, stale path detection
- `bin/prove-docs-freshness.sh` — MACHINE.md / SYSTEM_MAP.md vs live launchctl, skills, PATH (forced)
- `bin/prove-skills.sh` — required agent skills present under `.agents/`
- `bin/prove-launchers.sh` — captains + LaunchAgents + nested proves (includes docs freshness)
- Fresh-machine acceptance checklist in README

## Migration notes

- Doc SoT split: inventory → MACHINE.md; linkage → docs/SYSTEM_MAP.md; decisions → portfolio Wayfinder
- `audit-doc-freshness.sh` name retired in favor of `prove-docs-freshness.sh` (exit 0 or fail closed)
- Host label `"mac"` must match in flake.nix, rebuild.sh, and bootstrap.sh
- `homebrew.onActivation.cleanup = "zap"` — first switch may uninstall unlisted brews
- Agent config changes MUST flow through dotfiles; never patch runtime copies directly
