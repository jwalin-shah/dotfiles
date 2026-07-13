# Machine Manifest

Single source of truth for what's installed/configured on this machine, how
each thing is (or isn't) reproducible, and what's still an open question.
Seeded 2026-07-13 from a full audit (reports in `.jw/plans/*-audit.md`,
`.jw/plans/*-survey.md`). Check new installs/configs against this file
before adding them ad hoc — if it's not declared here or in
`configuration.nix`/`home.nix`, it doesn't survive a fresh machine.

Status key: **OK** = declared + working. **GAP** = works but not declared
anywhere (won't survive a rebuild). **STALE** = declared/documented but
doesn't match reality. **OPEN** = needs a captain decision.

## Homebrew (`configuration.nix` homebrew.brews/casks)

All 37 brews + 8 casks + `container` (newly added) cross-checked against
usage evidence — **no removal candidates**, full detail in
`homebrew-usage-audit.md`. `homebrew.onActivation.cleanup = "zap"` already
auto-removes anything installed-but-undeclared, so this list only needs
periodic re-validation for declared-but-dead entries, not orphan cleanup.

- OPEN: `typst` — zero usage evidence despite `modern-resume` supposedly
  being a Typst project. Verify or drop.

## npm globals

| package | alias | status |
|---|---|---|
| gh-axi | `gha` | OK — declared via `home.activation.npmGlobalTools`, alias points at `/opt/homebrew/bin/gh-axi` directly (not npx) |
| chrome-devtools-axi | `cda` | OK — same |
| lavish-axi | `lva` | OK — same |

Fixed 2026-07-13: previously `npx -y <pkg>` (risk of resolving a different
copy than the pinned global, same bug class already seen with `claude-code`)
and not declared anywhere (would vanish on a fresh machine). Both fixed.

## Python (moving off shared Homebrew site-packages)

Full plan: `pip-to-uv-migration.md`. Target state — nothing global via
`pip3 install` again, everything in a per-project/per-workflow `uv` venv:

| venv | location | status |
|---|---|---|
| btw-v1 | `~/projects/btw-v1` (existing project) | OPEN — plan written, not yet executed |
| research-toolkit | `~/envs/research-toolkit` (new) | OPEN — plan written, not yet executed |
| browser-automation | `~/envs/browser-automation` (new) | OPEN — plan written, not yet executed |
| ml-embedding | `~/envs/ml-embedding` (new) | OPEN — plan written, not yet executed |
| sphinx-docs | `~/envs/sphinx-docs` (new, or fold into whichever repo builds docs) | OPEN — plan written, not yet executed |

- OPEN: `livelm==2.0.0` in the old shared site-packages doesn't map to any
  group above — captain to identify or drop.
- Old shared `/opt/homebrew/lib/python3.14/site-packages` packages stay in
  place until each new venv is verified working — do not delete early.

## Project repos (`~/projects/`)

Recoverable from GitHub (`jwalin-shah` account) if ever lost locally —
confirmed via `gh-axi repo list jwalin-shah`.

| repo | on disk? | build/bootstrap | status |
|---|---|---|---|
| mintmux | yes | `go build ./cmd/...` — wired into `bootstrap-projects.sh` Phase 0 | OK, verified working 2026-07-13 |
| m5tools | yes (cloned 2026-07-13, was missing before) | `make install` — wired into `bootstrap-projects.sh` Phase 0 | OK |
| btw-v1 | yes | needs its own `uv` venv (see Python section) | OPEN |
| jw-desk | yes | scaffold only — 2 commits, no implementation yet, NOT obsolete, NOT superseded by research-bridge (unrelated project, confirmed 2026-07-13) | early-stage, no action needed |
| research-bridge | yes | `uv`/pip venv at `~/projects/research-bridge/.venv`, provides `chatgpt-bridge`/`gemini-bridge`/`perplexity-bridge` binaries | OK |
| firstmate, cocoindex, cognee, treehouse, no-mistakes, gnhf, m5tools-adjacent, voice-engine-swift, modern-resume | mixed | not individually audited this pass | see `~/CLAUDE.md` §3 project map; `~/.local/bin` binary-level audit in progress (#12) |

Everything else in `~/.local/bin` besides mintmux/m5tools (no-mistakes, etc.) — audit in progress, will be
verified or purged based on usage. (`local-bin-usage-audit.md`).

`bootstrap-projects.sh` now also clones any `PROJECTS` entry missing from
disk via `gh-axi repo clone jwalin-shah/<name>` before building — a fresh
machine can self-heal instead of silently skipping missing repos.

## Skills (`~/.agents/skills/`, 30 total)

25/30 are nix-managed symlinks, current as of last `rb`. 5 are real
unmanaged local directories — **GAP**, won't survive a fresh machine:
`computer-use`, `orchestration`, `gh-axi`, `githits`, `tldr`.

## Tool registry (`~/.agent-rules/TOOL_REGISTRY.md`)

**STALE** — drifted from reality, not yet corrected:
- Claims `fastedit` and `pioneer` are ACTIVE; neither is on `PATH`.
- "Skills installed" table lists 4 skills (`find-docs`, `tool-policy`,
  `pioneer-api`, `inference-net`) that don't exist, and omits all 30 real
  ones.
- Contradicts `~/CLAUDE.md` on whether `dust` is agent-blocked (registry
  says blocked, `~/CLAUDE.md` §2 lists it as always-available).

## LaunchAgents/daemons

10 healthy + correctly nix-declared: mintmux, inbox-server,
llama-embed-server, auto-save, m5logd, mlx-chat-server, cocoindex-daemon,
coderank-embed-server, voice-engine, jw-cred-canary. `m5fand` correctly
root-owned system daemon (fan control needs root).

- OPEN: `cognee-api` shows nonzero last-exit (2) — check for crash loop.
- **GAP**: `com.jwalinshah.voice-paste` running but hand-installed, no
  `org.nixos.` prefix, not in `configuration.nix`.
- **STALE**: `com.jwalin.adblock.plist` — not loaded, points at retired
  `fm-adblock` binary. Removal pending captain's explicit go (root-owned
  file, task #3).
- **STALE**: `~/CLAUDE.md` §12 documents `jw-sentry`, `jw-sessiond`, and
  `quota-keychain-sync` as running services. No plist for any of the three
  exists anywhere on this machine. Doc needs correction either way —
  whether that means "deploy them" or "stop claiming they run" is a
  captain call (see mintmux/m5tools-only scope note above).

## App configs

| app | managed? |
|---|---|
| aerospace | OK, symlinked |
| karabiner-elements | OK, symlinked |
| cursor | OK, symlinked (runtime file correctly excluded) |
| ghostty | **GAP** — plain file, not symlinked. One-line fix pending. |
| brave-browser | intentionally unmanaged (runtime state, not config) |
| raycast, lulu, monitorcontrol | low priority, not found in standard locations this pass |

## Claude Code settings/permissions

Base `settings.json` identical and clean across `~/.claude`, `~/.claude-a`,
`~/.claude-token`. No overly-broad grants anywhere.

- **GAP**: only `~/.claude/settings.local.json` exists. `~/.claude-a` (this
  identity) and `~/.claude-token` have **no local deny list** (`sudo *`,
  `rm -rf /`, `mkfs *`, `dd if=* of=/dev/*` protections are absent there).
- OPEN: the TokenRouter-specific allow list sits in bare `~/.claude` rather
  than `~/.claude-token` — possible copy-paste-into-wrong-dir mistake,
  worth confirming.

## Not yet actioned (require captain approval per `~/CLAUDE.md` gates)

- Delete `com.jwalin.adblock.plist` (gate: root-owned system file).
- Create the 5 pip→uv venvs (safe/additive, awaiting go-ahead to execute).
- Correct `TOOL_REGISTRY.md` and `~/CLAUDE.md` §12 staleness.
- Symlink ghostty config into dotfiles (low-risk, one line).
- Add deny-list/local settings to `~/.claude-a` and `~/.claude-token`.
- Decide fate of remaining `~/.local/bin` binaries once #12 lands.
