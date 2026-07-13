# Claude Code settings.json permissions audit

Scope: ~/.claude, ~/.claude-a, ~/.claude-token (settings.json + settings.local.json). No project-level `.claude/settings.json` found under ~/projects (searched 3 levels deep).

## Findings

**Base settings.json (all three dirs) is identical** — same env, model, statusLine, effortLevel, theme, `_comment` noting transport is chosen by the launcher wrapper. No permissions block in any of the three base files. Consistent, no drift.

**Only ~/.claude has a settings.local.json** — ~/.claude-a and ~/.claude-token have none. This is the actual inconsistency: any permission grant needed for the `-a` (OAuth) or `-token` (TokenRouter) identities isn't captured anywhere, so those sessions fall back to interactive prompts for everything not covered by base settings.json. If the grants in ~/.claude/settings.local.json (secret-cache, ct/TokenRouter checks) were meant to apply broadly, they're silently missing from the other two.

**~/.claude/settings.local.json allow list**: all TokenRouter/secret-cache plumbing (`secret-cache exec/list/status/refresh/get`, `ct --version`, lsof checks on ports 8788/18999, curl to api.tokenrouter.com with bearer token, launchctl list, a stray `echo "exit=$?"`). All scoped to specific commands, not bare `Bash`. No wildcard file-path grants. Nothing here looks unused — every entry maps to the TokenRouter debugging workflow described in the `tokenrouter-ct-plumbing` memory.

**deny list** is sane and minimal: `sudo *`, `rm -rf /`/`rm -rf /*`, `mkfs *`, `dd if=* of=/dev/*` — standard destructive-command denials, present only in ~/.claude.

## Flags

1. No overly-broad allows found (no bare `Bash`, no wildcard file access) — good.
2. Real gap: the deny list (sudo/rm -rf/mkfs/dd protections) only exists in ~/.claude, not in ~/.claude-a or ~/.claude-token. Those two identities have zero explicit deny rules of their own.
3. The TokenRouter-specific allow list living in ~/.claude/settings.local.json (the *bare* `claude` identity) rather than ~/.claude-token is backwards given the naming — worth confirming this isn't a copy-paste-into-wrong-dir mistake.
