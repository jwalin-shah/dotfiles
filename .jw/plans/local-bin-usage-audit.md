# ~/.local/bin Audit Report
Date: 2026-07-13 | Task #12 Cleanup Effort

## Overview
Audited 67 binaries/scripts in ~/.local/bin. Categorized by:
- Active use in LaunchAgents (configuration.nix)
- Source repository availability
- Recent file modification time
- References in scripts/dotfiles

**Exclusions (per task scope):** mintmux (4.0M), m5tools binaries (m5fand, m5logd, m5mon - 3.6M total)

## KEEP (Active LaunchAgents or Core Infrastructure)

### LaunchAgents Declared in ~/dotfiles/configuration.nix
- **jw-heal** (2.5K shell script, Jul 8)
  - Health check daemon. Runs every 5min via launchd.
  - Monitors service health, kills stale processes, truncates logs.
  - **Status:** ACTIVE - declared in config, runs as service.

- **voice-engine** (686K binary, Jul 8)
  - macOS dictation menubar app.
  - **Status:** ACTIVE - LaunchAgent declared, heavy use.

- **m5logd** (52K binary, Jun 30)
  - Part of m5tools per Makefile. Hardware logging daemon.
  - **Status:** ACTIVE - root daemon declared.

- **mintmux** (6.0M binary, Jul 3)
  - PTY multiplexer. Core infrastructure per ~/CLAUDE.md.
  - **Status:** ACTIVE - LaunchAgent declared, explicitly marked to keep.

- **m5fand** (53K binary, Jul 8)
  - Part of m5tools. Fan control daemon.
  - **Status:** ACTIVE - root daemon declared, explicitly marked to keep.

- **m5mon** (3.6M binary, Jun 30)
  - Part of m5tools (verified in ~/projects/m5tools/Makefile).
  - **Status:** ACTIVE - part of m5tools ecosystem, explicitly marked to keep.

### Python Tools via uv (Symlinks to ~/.local/share/uv/tools/*)
These are managed by `uv` package manager and are safely recoverable via `uv install`.
- cocoindex, cocoindex-code, ccc (semantic code search daemon, in LaunchAgent)
- cognee-cli (AI memory platform, in LaunchAgent)
- mlx_lm, mlx_lm.* variants (17 symlinks, model service, in LaunchAgent)
- llm-tldr, llm-tldr variants (code context tool, in LaunchAgent)
- scrapling (web scraper tool)

**Status:** KEEP - all are LaunchAgents or dependency chains.

### Go Infrastructure Binaries
- **jw** (15M binary, Jul 8)
  - Orchestrator backend. Core to ~/CLAUDE.md jw-* ecosystem.
  - Multiple scripts wrap it (jw-*.sh in ~/bin).
  - **Status:** KEEP - core ecosystem binary.

- **no-mistakes** (20M binary, Jul 2)
  - Automated PR pipeline tool. Source: ~/projects/no-mistakes.
  - **Status:** KEEP - active project, in ~/projects.

- **treehouse** (13M binary, Jul 6)
  - Git worktree pool manager. Source: ~/projects/treehouse.
  - Referenced in auto-save.sh.backup.
  - **Status:** KEEP - active project, in ~/projects.

- **mm** (4.6K shell script, Jul 2)
  - Mintmux orchestration wrapper. Coordinates with mm-ctl, mm-orch, etc.
  - **Status:** KEEP - core mintmux CLI.

### mintmux Binary Suite (all from ~/projects/mintmux)
- mm-ctl, mm-attach, mm-edit, mm-enforcer (3.4-4.0M each, Jul 3)
- mm-registry, mm-review, mm-route, mm-send, mm-orch (3.3-8.7M, Jul 2-3)
- **Status:** KEEP - all part of mintmux orchestration system.

### Supporting Scripts
- **jw-status** (7.2K shell script, Jul 3)
  - Service status monitor. Reads LaunchAgents, checks health.
  - Heavy LaunchAgent configuration parsing.
  - **Status:** KEEP - core monitoring tool.

- **quota, quota-core** (symlinks to ~/projects/quota-core/bin)
  - Quota collection/validation CLI.
  - **Status:** KEEP - source available at ~/projects/quota-core.

## UNCLEAR (Requires Captain Decision)

### jw-* Daemon Binaries (No source repos found locally or on GitHub)
- **jw-sentry** (3.5M binary, Jul 6)
  - Referenced in worktree config only (not main config.nix).
  - Per ~/CLAUDE.md, is part of "core jw-* ecosystem" but captain noted may not need active daemons.
  - No build source found in ~/projects (no jw-sentry, jw-core repo).
  - **Decision needed:** Is this still required? Source recoverable from GitHub if git history exists.

- **jw-sessiond** (3.4M binary, Jul 6)
  - Referenced in worktree config only (not main config.nix).
  - Per ~/CLAUDE.md, is part of "core jw-* ecosystem" but captain noted may not need active daemons.
  - No build source found in ~/projects.
  - **Decision needed:** Is this still required? Source recoverable from GitHub if git history exists.

### Large Code Intelligence Binary
- **jw-code-intel** (265M binary, Jul 4 - LARGEST FILE)
  - Purpose unclear. No references in configuration.nix, LaunchAgents, or scripts.
  - Size suggests compiled binary but source unknown.
  - **Decision needed:** Debug info, unused artifact, or external binary? Check `file` output.

### mlx-lm and Embedding Chains (wrapper scripts)
- **jw-mlx-chat** (312B shell script, Jul 8)
  - Wrapper around mlx_lm.server. Service declared in config.nix as LaunchAgent.
  - **Status:** KEEP - active service.

- **jw-llama-embed** (332B shell script, Jul 3)
  - Wrapper. Llama embedding service declared in config.nix.
  - **Status:** KEEP - active service.

- **jw-coderank-embed** (365B shell script, Jul 8)
  - Wrapper. CodeRank embedding service declared in config.nix.
  - **Status:** KEEP - active service.

- **jw-cognee** (196B shell script, Jul 8)
  - Wrapper. Cognee API service declared in config.nix.
  - **Status:** KEEP - active service.

### Utilities (Small scripts, unclear purpose)
- **apalache-mc** (321B shell script, Jul 11)
  - Bourne shell script. No references in dotfiles or scripts. Purpose unknown.
  - **Decision needed:** Research or remove?

- **cursor** (765B shell script, Jul 9)
  - OpenAI Codex CLI wrapper. No references in config.nix.
  - **Decision needed:** Still using Cursor IDE?

- **op** (238B shell script, Jul 6)
  - Shell wrapper, unknown purpose. No references found.
  - **Decision needed:** Research or remove?

- **kk** (144B shell script, Jul 4)
  - Minimal script. No references found. Purpose unknown.
  - **Decision needed:** Research or remove?

- **secret-cache** (5.6K shell script, Jul 6)
  - Credential caching utility. No active references found.
  - **Decision needed:** Still needed?

- **smc** (53K binary, Jul 8)
  - Unknown purpose. No source found.
  - **Decision needed:** Research purpose?

### External Wrappers
- **agent** (symlink to cursor-agent)
  - Cursor Agent CLI. Not active in config.nix.
  - **Decision needed:** Keep for manual use or remove?

- **cursor-agent** (symlink to version dir, Jul 9)
  - Cursor Agent binary. No LaunchAgent declaration.
  - **Decision needed:** Active or stale?

### Symlinks to Nix/dotfiles
- **oo, rtldr** (symlinks to /nix/store and ~/dotfiles/home/.local/bin)
  - Managed by nix-darwin/home-manager, not hand-managed.
  - **Status:** KEEP - declarative management handles these.

### Symlinks to Ambiguous Targets
- **cbm** (symlink to ./jw-code-intel)
  - Alias to jw-code-intel. Purpose of target unclear.
  - **Decision needed:** Clarify jw-code-intel purpose.

## LIKELY-SAFE-TO-REMOVE (No usage evidence, source recoverable)

- **fm-events** (2.2K shell script, Jul 4)
  - References "fm" prefix which ~/CLAUDE.md notes is "retired".
  - No references in current config.nix or scripts.
  - **Action:** Safe to remove if no captain need.

- **jwci** (3.7M binary, Jul 5)
  - Purpose unknown. No references in config or scripts.
  - Large binary suggests compiled tool.
  - **Action:** Research source or remove.

- **mlx-cleanup.py** (5.9K Python script, Jul 3)
  - Maintenance script for mlx-lm. No active references.
  - **Action:** Safe to remove, recoverable from project if needed.

## Data Notes

### File Statistics
- **Largest:** jw-code-intel (265M) - purpose unclear
- **Total real binaries:** ~67 items
- **Symlinks managed by uv:** 24 items (cocoindex, mlx-lm, llm-tldr, cognee, scrapling)
- **Symlinks to nix/dotfiles:** 2 items (oo, rtldr)
- **Symlinks to local projects:** 2 items (quota, quota-core)
- **Symlinks to cursor-agent:** 2 items (agent, cursor-agent)
- **Wrapper scripts:** 15+ items
- **Go binaries:** 25+ items

### Source Repositories Confirmed
- ~/projects/mintmux (mm-* suite)
- ~/projects/no-mistakes
- ~/projects/treehouse
- ~/projects/quota-core
- ~/projects/m5tools (m5fand, m5logd, m5mon)

### Missing Source Repos (per ~/CLAUDE.md)
Despite ~/CLAUDE.md listing "jw-core" ecosystem repos (jw-tui, jw-sentry, jw-sessiond, jw-agentd, jw-adblock, jw-watcher), no local copies found under ~/projects/. Only jw-desk exists. This suggests either:
1. Binaries are old hand-built artifacts
2. Source was removed or archived
3. Repos are managed elsewhere (external GitHub, not locally cloned)

## Verification Strategy

This audit is READ-ONLY. To act on removals:

1. **For KEEP items:** No action needed.
2. **For UNCLEAR items:** Captain to decide based on current usage.
3. **For LIKELY-SAFE-TO-REMOVE:** Recommend archiving manifest before deletion.

Before deletion, capture:
```bash
# Archive current state
sha256sum ~/.local/bin/* > ~/.local/bin-manifest.sha256
tar czf ~/.cache/local-bin-backup-$(date +%Y%m%d).tar.gz ~/.local/bin
```

## Recommendations

1. **Investigate jw-code-intel (265M):** Largest file. Purpose unclear.
2. **Clarify jw-* ecosystem:** Confirm if jw-sentry/jw-sessiond are needed or if binaries are stale.
3. **Move uv-managed tools to ~/.config/jw/tools.txt:** Document which tools are critical.
4. **Archive or declare:** For fm-events, jwci, mlx-cleanup.py if no active use found.
5. **Git history:** If jw-core repos once existed, check git reflog to recover source if needed.

---

**Report location:** `/Users/jwalinshah/dotfiles/.jw/plans/local-bin-usage-audit.md`
