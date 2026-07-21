---
name: axi
description: Run AXI tools before writing code — blast radius, call graph, prior art, test coverage, compact shell output.
---

# AXI Tools

Mandatory pre-code tools. Run these before touching any file.

## Process

```bash
# 1. Blast radius BEFORE writing the tensor equation
llm-tldr impact <file-you-plan-to-change>

# 2. Call graph BEFORE writing pseudocode
aider-axi calls ~/projects/orbit/<file> <function>

# 3. OSS prior art BEFORE writing pseudocode
githits-axi example "<problem you are solving>"

# 4. Existing test coverage BEFORE adding invariant gates
aider-axi tests ~/projects/orbit/<pkg>

# 5. Compact shell output for all build/test runs
rtk err <command>
rtk diff "git diff HEAD"
```
