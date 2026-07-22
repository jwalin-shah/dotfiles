---
name: axi
description: Mandatory pre-code gates — blast radius, call graph, prior art, test coverage. Run BEFORE writing any code in orbit/bridge.
---

# AXI — Pre-Code Invariant Gates

These MUST run before any Go file is touched in orbit or bridge. The hook enforces this mechanically.

## Process

```bash
# 1. Blast radius
llm-tldr impact <file-you-plan-to-change>

# 2. Call graph
aider-axi calls ~/projects/<repo>/<file> <function>

# 3. OSS prior art
githits example "<problem you are solving>"

# 4. Test coverage
aider-axi tests ~/projects/<repo>/<pkg>

# 5. Compact output
rtk err <command>
rtk diff "git diff HEAD"
```

## When to run

- Before writing any Go code in orbit or bridge
- Before changing any file that has invariants attached
- Always — enforced mechanically, not by choice

## Integration

This skill wraps Matt Pocock's `implement` skill. The flow:
```
/mattpocock-skills:implement → /axi → write code → P0 gate → /mattpocock-skills:mp-code-review
```
