---
name: gh-axi
description: All GitHub operations — PRs, issues, reviews, merges, search, releases. Use for ANY GitHub action. Never use raw gh. AXI-compliant CLI.
---

# gh-axi — GitHub Agent Interface

CLI tool. All commands run via Bash. AXI-compliant (TOON output, content-first, structured errors). Wraps `gh` with agent-optimized output.

## Core Pattern

`gh-axi` is the ONLY way to interact with GitHub. Never use `gh` directly — raw `gh` output wastes tokens and forces the model to parse human-oriented tables.

```bash
gh-axi <resource> <action> [flags]
gh-axi -R owner/repo <resource> <action> [flags]  # target specific repo
```

## Quick Reference

```bash
# PRs
gh-axi pr list                       # open PRs in current repo
gh-axi pr list --state closed        # closed PRs
gh-axi pr view 42                    # detail view
gh-axi pr view 42 --comments         # with comments
gh-axi pr view 42 --full             # full body (no truncation)
gh-axi pr create --title "..." --body "..." --base main
gh-axi pr merge 42 --merge           # merge (or --squash, --rebase)
gh-axi pr review 42 --approve        # approve
gh-axi pr review 42 --comment "..."  # comment
gh-axi pr diff 42                    # unified diff

# Issues
gh-axi issue list                    # open issues
gh-axi issue list --state closed     # closed issues
gh-axi issue view 42                 # detail
gh-axi issue create --title "..." --body "..."
gh-axi issue close 42

# Search
gh-axi search "auth middleware" --type code --language go

# Repo
gh-axi repo view                     # current repo details
gh-axi repo view owner/repo          # specific repo

# CI / Runs
gh-axi run list                      # recent workflow runs
gh-axi run view <id>                 # run detail + logs

# Labels, Secrets, Variables
gh-axi label list
gh-axi secret list
gh-axi variable list
```

## Setup

```bash
gh-axi setup hooks                   # install SessionStart/Stop hooks
```

## Key AXI Behaviors

- `--no-args` shows dashboard of relevant state (open PRs, recent issues)
- `--fields` to request specific fields
- Long bodies truncated with `--full` escape hatch
- Errors on stdout with fix suggestions
```

Run `gh-axi --help` or `gh-axi <resource> --help` for full reference.
