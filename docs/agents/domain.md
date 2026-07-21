# Domain Docs

**Layout:** Single-context

**Files:**
- `GLOBAL.md` at repo root — machine constitution (symlinked to ~/CLAUDE.md)
- `AGENTS.md` at repo root — agent-specific instructions
- `MACHINE.md` — hardware and OS specifics
- `docs/` — hooks, setup, and customization docs

**Dotfiles-specific domain:**
- `configuration.nix` — nix-darwin system config (LaunchAgents, Homebrew, daemons)
- `home.nix` — home-manager config (packages, symlinks, agent configs, skills)
- `home/` — agent configs for Claude, Codex, Cursor, Gemini
- `config/` — model selection, linter configs, keyboard, window manager
- `bin/` — shell wrappers (ca, ct, daemon-wrapper, enforce-bridge-workflow)
- `.agents/` — skill definitions distributed to all agent targets