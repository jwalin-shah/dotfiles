# Known Issues

## macOS / BSD

- `head -n -N` outputs nothing on macOS (BSD head). Use `tail -n +N` instead.
- `sed -i` requires an extension argument: `sed -i '' 's/old/new/' file`.

## Agent Config

- All agents use native tools directly. No wrapper layer. No permission hooks.
- Permissions are skipped via launcher flags (`--dangerously-skip-permissions`, `--trust --yolo`).
- Agents load ~/.agent-rules/ for behavioral contracts.
- Per-account Claude OAuth requires `/login` in `~/.claude-a` once.

## fastedit (REMOVED 2026-07-14)

`fastedit` is decommissioned per CLAUDE.md — not on PATH, not coming back.
Both `fastedit` and its dependency `tldr-code` (Go binaries) have been removed.
`llm-tldr` v1.5.2 (via uv) handles all code analysis. Use standard Edit/Write.

## coreutils / gtimeout

Homebrew `coreutils` is installed for `gtimeout`. Do NOT add GNU binutils to agent PATH —
`gcat`, `gls`, `ggrep`, `gfind` would bypass native tool expectations.

## cursor-agent (cua) — use official curl installer, NOT Homebrew

Brew's cask sets `com.apple.quarantine` on unsigned native modules, Gatekeeper removes them.
Use: `curl https://cursor.com/install -fsS | bash`

## Shell bypasses (not fixed, accept the risk)

- `tee << 'EOF'` can write arbitrary files without being caught by any deny rule.
- Pipeline pager deny catches `| head`/`| tail` but not `| /usr/bin/head` or `| ghead`.

These are documented, not fixed. The cost of enforcement (regex-based permission hooks) exceeds
the risk. Agents are trusted. If an agent writes a bad file, we fix it or reap the thread.
