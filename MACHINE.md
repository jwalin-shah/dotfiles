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

All 40 brews + 9 casks cross-checked against
usage evidence — **no removal candidates**, full detail in
`homebrew-usage-audit.md`. `homebrew.onActivation.cleanup = "zap"` already
auto-removes anything installed-but-undeclared, so this list only needs
periodic re-validation for declared-but-dead entries, not orphan cleanup.

- OPEN: `typst` — zero usage evidence despite `modern-resume` supposedly
  being a Typst project. Verify or drop.

## npm globals (12 packages, declared via `home.activation.npmGlobalTools`)

| package | purpose |
|---|---|
| @anthropic-ai/claude-code | `ca` wrapper |
| @openai/codex | `cx` wrapper |
| @kilocode/cli | `ko`/`kt` wrappers |
| command-code | `com` wrapper |
| gh-axi | GitHub operations |
| githits | code search |
| ctx7 | library docs |
| chrome-devtools-axi | browser automation |
| lavish-axi | review surfaces |
| tasks-axi | task management |
| @inference/cli | observability |
| gnhf | loops |

All 12 declared 2026-07-14. Survives fresh machine.

## Python (uv-managed via home.nix)

All 6 Python tools are declared in `home.nix` via `uvTools` — mlx-lm,
cocoindex, cocoindex-code, cognee, llm-tldr, z3-solver. No global pip
packages remain. The old `pip-to-uv-migration.md` plan is closed:
the migration was already done when this was written — the plan itself
was the stale artifact.

Old shared `/opt/homebrew/lib/python3.14/site-packages` packages (including
`livelm==2.0.0`) are unreferenced. `homebrew.onActivation.cleanup = "zap"`
handles Brew-level cleanup automatically.

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
| firstmate, cocoindex, cognee, treehouse, gnhf, m5tools-adjacent, voice-engine-swift, modern-resume | mixed | not individually audited this pass | see `~/CLAUDE.md` §3 project map; `~/.local/bin` binary-level audit in progress (#12) |

Everything else in `~/.local/bin` besides mintmux/m5tools — audit in progress, will be
verified or purged based on usage. (`local-bin-usage-audit.md`).

`bootstrap-projects.sh` now also clones any `PROJECTS` entry missing from
disk via `gh-axi repo clone jwalin-shah/<name>` before building — a fresh
machine can self-heal instead of silently skipping missing repos.

## Skills (`~/.agents/skills/`, 26 total)

All 26 are nix-managed symlinks, current as of last `rb`. 0 unmanaged
directories. 5 `.backup` orphan directories were cleaned up 2026-07-14.

## Tool registry (`~/.agent-rules/TOOL_REGISTRY.md`)

Corrected 2026-07-14: pioneer status REMOVED (was PLANNED), cu→cua, stale
launchers (`c`, `op`) removed, skills count updated to 26 all-nix-managed,
`secret-cache` references removed.

## LaunchAgents/daemons

All declared in `configuration.nix` under `launchd.user.agents` +
`launchd.daemons`. Run `launchctl list | grep org.nixos` for the live list,
or `jw-status list` for a health dashboard. MACHINE.md does NOT duplicate
the service inventory — `configuration.nix` is the canonical source.

Services by category (2026-07-14):

- OPEN: `cognee-api` shows nonzero last-exit (2) — check for crash loop.
- **FIXED 2026-07-14**: voice-paste plist + binaries removed. voice-engine-swift kept.
- **FIXED 2026-07-14**: `com.jwalin.adblock.plist` — removed, binary already gone.
- **FIXED 2026-07-14**: `~/CLAUDE.md` now exists (→ `~/.dotfiles/GLOBAL.md`).
  `jw-sentry`, `jw-sessiond`, `quota-keychain-sync` confirmed absent —
  no plists anywhere. GLOBAL.md §12 corrected.

## App configs

| app | managed? |
|---|---|
| aerospace | OK, symlinked |
| karabiner-elements | OK, symlinked |
| cursor | OK, symlinked (runtime file correctly excluded) |
| ghostty | **FIXED 2026-07-14** — symlinked into dotfiles + home.nix entry. |
| brave-browser | intentionally unmanaged (runtime state, not config) |
| raycast, lulu, lunar, maccy, shottr, flux | low priority, not found in standard locations this pass |

## Claude Code settings/permissions

Base `settings.json` identical and clean across `~/.claude`, `~/.claude-a`,
`~/.claude-token`. No overly-broad grants anywhere.

- **FIXED 2026-07-14**: deny lists deployed to all three dirs via home.nix.
- OPEN: the TokenRouter-specific allow list sits in bare `~/.claude` rather
  than `~/.claude-token` — possible copy-paste-into-wrong-dir mistake,
  worth confirming.

## Not yet actioned (require captain approval per `~/CLAUDE.md` gates)

- **DONE 2026-07-14**: `com.jwalin.adblock.plist` removed.
- **DONE 2026-07-14**: TOOL_REGISTRY.md corrected.
- **DONE 2026-07-14**: Ghostty config symlinked into dotfiles.
- **DONE 2026-07-14**: Deny-list/local settings added to all Claude config dirs.
- **DONE 2026-07-14**: Cognee crash loop fixed (uvicorn server + disable auth).
- **DONE 2026-07-14**: Lean 4.32.0 + Lake 5.0.0 installed via elan; bridge proofs build clean (12 jobs).
