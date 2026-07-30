# Domain context

> Produced / maintained via the `domain-modeling` skill. Required by portfolio universal-pocock-policy (2026-07-30).

## Purpose

Dotfiles is the **machine constitution** for the captain's Mac — not an application. One repo, one command (`./rebuild.sh`), and a fresh machine ends up configured the same way. It defines system settings, packages, shell, editor, terminal, agent configs, LaunchAgents, and launcher scripts that survive reinstall.

## Ubiquitous language

| Term | Meaning |
|---|---|
| Switch | `darwin-rebuild switch` applying flake config to live system |
| Bootstrap | First-time `bootstrap.sh`: Nix install → symlink → first switch |
| mkOutOfStoreSymlink | home-manager pattern pointing `~/.config/*` at repo `home/` files |
| LaunchAgent | macOS daemon plist (Neo4j, embeds, knowledge-engine sync, fmt-on-change) |
| Machine principles | `GLOBAL.md` → `~/CLAUDE.md` agent constitution |
| Audit | `audit-config-ownership.sh` verifies live configs match repo copies |

## Entities

| Entity | Invariants | Owner |
|---|---|---|
| flake.nix | Entry point; darwinConfigurations, home-manager, nix-homebrew | dotfiles |
| configuration.nix | System: macOS defaults, Homebrew brews/casks, LaunchAgents | dotfiles |
| home.nix | User packages, symlinks, shell aliases, agent config installs | dotfiles |
| home/ | Real config files (Neovim, WezTerm, AGENTS.md, agent settings) | dotfiles |
| bin/ | Launcher scripts symlinked to ~/bin (ct, openwiki, agent wrappers) | dotfiles |
| config/orbit/models.env | Single switch for all AI model selection | dotfiles |

## Boundaries

- **In scope:** nix-darwin + home-manager declarative config, agent policy symlinks, service LaunchAgents, audit scripts
- **Out of scope:** application business logic (lives in ~/projects/*); git identity (deliberately not set)
- **Upstream dependencies:** nixpkgs, nix-darwin 26.05, home-manager, Determinate Nix
- **Downstream consumers:** entire ~/projects stack (Neo4j, embed servers, knowledge-engine daily sync, fmt→neo4j-on-change)

## Events / lifecycle

1. **Bootstrap:** clone → review host/user/arch → `./bootstrap.sh` → first switch
2. **Daily:** edit config in repo → `./rebuild.sh` → kickstart changed LaunchAgents
3. **Audit:** `bin/audit-config-ownership.sh` + `bin/audit-doc-freshness.sh` on demand

## Open questions

- Homebrew `cleanup = "zap"` removes unlisted packages on every switch — captain must curate brews/casks list
- High-agency aliases (`cc`, `co`) are intentional but require informed use
