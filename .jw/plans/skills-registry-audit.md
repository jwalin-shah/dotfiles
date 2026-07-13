# Skills + TOOL_REGISTRY audit (read-only, 2026-07-13)

## ~/.agents/skills/ (30 entries)

25 are nix-store symlinks (home-manager managed, e.g. axi, cocoindex,
code-review, diagnose, plan, research, tdd, wayfinder, etc.) - all current,
last relinked 2026-07-11.

5 are real (non-symlink) local directories, not nix-managed:
- `computer-use/SKILL.md` - mtime 2026-07-02
- `orchestration/SKILL.md` - mtime 2026-07-02
- `gh-axi/SKILL.md`, `githits/SKILL.md`, `tldr/SKILL.md` - mtime 2026-07-08

These 5 exist outside home.nix's declarative management - if this machine
were rebuilt from dotfiles alone, they'd be missing. Flag for task #5
(the manifest) and/or adding them to home.nix's home.file declarations.

No duplicate-purpose skills found among the 30.

## TOOL_REGISTRY.md status vs reality

**Broken ACTIVE claims** (binary not on PATH):
- `fastedit` - marked ACTIVE, not found via `command -v`
- `pioneer` - marked ACTIVE, not found
- `bun` - marked INFRA ("don't call directly", so absence may be intentional,
  but the CLI it's supposed to run, `pioneer`, is also missing)

**All other ACTIVE tools verified present**: llm-tldr, jq, yq, lavish-axi,
chrome-devtools-axi, ctx7, cognee-cli, cocoindex-code/ccc, treehouse,
githits, inf, gtimeout, timeout.

**"Skills installed" table is stale/orphaned**: TOOL_REGISTRY.md lists
`find-docs`, `tool-policy`, `pioneer-api`, `inference-net` as installed
skills - none of these 4 exist anywhere in `~/.agents/skills/`. Conversely,
none of the 30 skills actually present (axi, cocoindex, code-review, tdd,
wayfinder, etc.) are documented in TOOL_REGISTRY.md at all. The registry's
skills section does not reflect this machine's real skill set.

**Separate conflict noticed**: TOOL_REGISTRY.md's "Blocked" table denies
`dust` for agents ("use `du -s`/`du -sh` instead"), but `~/CLAUDE.md`
section 2 lists `dust` under "System Utilities (always available)" with no
restriction. Two source-of-truth files disagree - relevant to task #5.
