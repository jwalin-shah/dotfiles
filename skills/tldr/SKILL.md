---
name: tldr
description: Understand codebase architecture, call graphs, structure, and impact analysis. Use BEFORE touching any file to know what depends on what.
---

# tldr — Code Intelligence

CLI tool. All commands run via Bash. Output defaults to JSON, use `-f compact` for TOON-like format. Works on the current project directory.

## Ponytail Rungs This Answers

| Rung | Command |
|---|---|
| 1 — Where is this in the code? | `tldr semantic --query "<concept>"` |
| 2 — What modules exist? | `tldr structure` |
| 3 — What's already imported? | `tldr imports` |
| 4 — What breaks if I change X? | `tldr change_impact` or `tldr impact <symbol>` |
| 4 — Who calls this function? | `tldr calls <symbol>` |

## Quick Reference

```bash
# Architecture and layout
tldr arch                          # architectural layers
tldr structure                     # module/file tree
tldr tree                          # directory tree

# Understand code
tldr semantic --query "<concept>"  # find relevant code by meaning
tldr context --entry <function>    # call graph from entry point
tldr context                       # general context
tldr slice <symbol>                # program slice

# Impact analysis
tldr calls <symbol>                # who calls this (upstream)
tldr impact <symbol>               # what this calls (downstream)
tldr change_impact                 # blast radius of current changes
tldr importers <file>              # who imports this file

# Dead code
tldr dead                          # find unused code

# Search
tldr search <pattern>              # text search across codebase

# Config
tldr cfg                           # project configuration summary
tldr status                        # index status
tldr diagnostics                   # health check
```

## Output Formats

```bash
tldr <cmd> -f compact              # compact (fewest tokens)
tldr <cmd> -f json                 # JSON (default, structured)
tldr <cmd> -f text                 # human-readable
```

## Key Pointers

- Works on the **current directory** — cd to the project first
- `tldr change_impact` works on uncommitted changes — perfect for pre-commit checks
- `tldr dead` finds code that nothing imports — safe deletion targets
```

Run `tldr --help` or `tldr <cmd> --help` for full reference.
