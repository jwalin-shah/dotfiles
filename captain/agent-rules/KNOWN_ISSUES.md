# Known Issues

## macOS / BSD

- `head -n -N` outputs nothing on macOS (BSD head). Use `tail -n +N` instead.
- `sed -i` requires an extension argument: `sed -i '' 's/old/new/' file`.

## Agent Config

- All agents use native tools directly. No wrapper layer. No permission hooks.
- Permissions are skipped via launcher flags (`--dangerously-skip-permissions`, `--trust --yolo`).
- Agents load ~/.agent-rules/ for behavioral contracts.
- Per-account Claude OAuth requires `/login` in `~/.claude-a` once.

## fastedit (needs tldr-code Rust binary for `references`)

`fastedit edit` calls `tldr references`, which the Python `llm-tldr` 1.5.2 does not provide.
Install the Rust `tldr-code` binary for this. Until then, use normal patch/edit tools.

## coreutils / gtimeout

Homebrew `coreutils` is installed for `gtimeout`. Do NOT add GNU binutils to agent PATH —
`gcat`, `gls`, `ggrep`, `gfind` would bypass native tool expectations.

## cursor-agent (cu) — use official curl installer, NOT Homebrew

Brew's cask sets `com.apple.quarantine` on unsigned native modules, Gatekeeper removes them.
Use: `curl https://cursor.com/install -fsS | bash`

## Shell bypasses (not fixed, accept the risk)

- `bun -e` with `fs.writeFileSync` bypasses file-write policy via script interpreter.
- `tee << 'EOF'` can write arbitrary files without being caught by any deny rule.
- Pipeline pager deny catches `| head`/`| tail` but not `| /usr/bin/head` or `| ghead`.

These are documented, not fixed. The cost of enforcement (regex-based permission hooks) exceeds
the risk. Agents are trusted. If an agent writes a bad file, we fix it or reap the thread.
