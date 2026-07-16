# <Project Name>

This file is the project's committed home for agent knowledge: build, test, architecture, and sharp-edge notes that travel with the code. Copy to `AGENTS.md`, symlink as `CLAUDE.md`.

## What
One-line description.

## Tech
- Language: Go / Python 3.x / Swift / TypeScript / Rust
- Framework:
- Package manager: go mod / uv / swift pm / pnpm / cargo
- Test runner: go test / pytest / swift test / vitest

## Entry points
-

## Conventions
- Use `llm-tldr` for code structure, call graphs, dead code (`tldr arch`, `tldr dead`)
- Use `bridge signals <dir>` to get a code health score before large changes
- Use `bridge verify <dir>` to verify worker output after changes
- `gofmt -w .` / `ruff format .` before commits (auto-applied by PostToolUse hook)

## Build
- Build: `<command that exits 0 quickly — not a server command>`
- Test: `<test command>`
- Format: `<format command>`

## Sharp edges
-

## Status
<!-- bridge verify-machine uses this section -->
- Last verified: <date>
- Health: <bridge signals output>
