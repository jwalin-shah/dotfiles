---
name: githits
description: Find real-world open-source code examples, search repos, inspect dependencies, and check package docs. Use BEFORE writing code to see how others have built it.
---

# githits — Grounded OSS Context

CLI tool. No MCP. All commands run via Bash. Output is TOON format (compact, ~40% fewer tokens than JSON).

## Ponytail Rungs This Answers

| Rung | Command |
|---|---|
| 0 — Does this need to be built? | `githits example "<query>" -l <lang>` |
| 0 — Any packages doing this? | `githits search "<query>"` |
| 2 — What does this dep do? | `githits pkg_info <pkg>` |
| 3 — What deps does it pull? | `githits pkg_deps <pkg>` |
| 4 — Any known vulns? | `githits pkg_vulns <pkg>` |

## Quick Reference

```bash
# Real-world implementations
githits example "rate limiter middleware" -l go
githits example "react virtual scroll" -l typescript --json  # switch to JSON

# Search code, docs, and packages
githits search "auth0 jwt validation"

# Inspect a dependency
githits pkg_info express               # registry metadata
githits pkg_deps express               # dependency tree
githits pkg_changelog express          # recent changes
githits pkg_vulns express              # known vulnerabilities

# Browse dependency source
githits code read <pkg> --file <path>  # read source file
githits code grep <pkg> "<pattern>"    # grep dependency source

# Browse docs
githits docs list <pkg>                # available doc pages
githits docs read <pkg> <page>         # read a doc page

# Submit feedback on results
githits feedback <solution_id>         # helps improve quality
```

## Key Flags

- `-l, --language <lang>` — filter by language
- `--json` — switch to JSON output
- `--no-color` — strip ANSI (always use this in agent context)
```

Run `githits --help` or `githits <cmd> --help` for full reference.
