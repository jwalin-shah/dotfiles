# projects-atlas: Portfolio Scanner + Repo Readiness

**Source**: `jwalin-shah/projects-atlas` (archived) -- `/tmp/audit-projects-atlas`

## Problem

A developer with 30+ repos has no single pane of glass for "what needs
attention right now." Agents need structured readiness signals before they can
safely launch work on a repo: Is it dirty? What branch? What validation command?
What work surfaces exist? What's the next action?

## How It Works

A **read-only scanner** (`scan_projects`) walks a workspace root, discovers
every Git repo, and collects structured signals:

1. **Git state**: branch, upstream, dirty/staged/untracked counts, ahead/behind,
   last commit age.
2. **Stack detection**: Python, Node, Rust, Go, etc. from lockfiles and config.
3. **Work surfaces**: presence of AGENTS.md, CLAUDE.md, CODEX_WORKPAD.md,
   PLAN.md, etc.
4. **Portfolio classification**: active portfolio repo, issue worktree,
   generated worktree, vendor submodule, support repo -- via pattern rules
   or an explicit `portfolio.json` registry.
5. **Next-action recommendation** per repo.
6. **Agent inbox**: dirty trees, unpushed commits, stale branches, missing
   validation, progress-update candidates.

Everything is read-only. The scanner never mutates scanned repos. Output is
a JSON atlas consumed by a local dashboard (`/api/atlas`) and CLI tools.

## Interface / Contract

```python
@dataclass(frozen=True)
class ScanOptions:
    root: Path
    max_depth: int = 7
    git_timeout_seconds: float = 5.0
    todo_limit_per_repo: int = 12
    portfolio_registry: Path | None = None

def scan_projects(options: ScanOptions) -> dict[str, Any]:
    """Walk root, discover repos, collect signals, return atlas JSON."""
    ...

# Classification rules (default non-active patterns)
DEFAULT_NON_ACTIVE_CLASSES = [
    {"pattern": "*-sym-*", "classification": "issue_worktree"},
    {"pattern": ".agent-stack-worktrees/*", "classification": "generated_worktree"},
    {"pattern": "app/src-tauri/vendor/*", "classification": "vendor_submodule"},
]
```

Key CLI surfaces for agents:
```bash
projects_atlas inbox ~/projects --json          # What needs attention?
projects_atlas workpack <repo> ~/projects --json # Full context packet for one repo
projects_atlas launch-card <repo> ~/projects     # Cockpit-ready status card
projects_atlas launch-gate ~/projects --json     # Can we safely launch workers?
```

## Applying to jw-*

- **jw-sentry**: Could be a scanned repo in an Atlas-like dashboard. The scanner
  would detect its Rust stack, check if CLAUDE.md exists, note dirty state.
- **Portfolio operating system**: The pattern of a centralized `portfolio.json`
  registry + classification rules that distinguish active products from
  generated checkouts and vendor code is directly portable to the jw-*
  ecosystem.
- **Agent readiness signals**: Any jw-* repo can expose AGENTS.md, a validation
  command, and work surfaces that an Atlas-like scanner would pick up --
  making the whole ecosystem agent-friendly without per-repo wiring.
