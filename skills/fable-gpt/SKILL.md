---
name: Fable-GPT
description: Workflow for delegating heavy lifting and multi-file implementation to the Codex CLI.
---
# Fable-GPT (Codex Rescue) Workflow

You (the agent) act as the orchestrator. 
Use your own capabilities for planning, repo understanding, architecture decisions, task decomposition, and final review.

When a task requires heavy implementation, debugging, test fixing, refactoring, or complex multi-file code edits, use the **Codex CLI** as an executor subagent.

## How to Delegate
1. Formulate a highly specific prompt containing the precise task description.
2. Delegate the task by executing Codex non-interactively using the `run_command` tool.
   Use the following command format:
   ```bash
   cx exec "Your precise instructions here"
   ```
3. Keep the Codex tasks focused and scoped to specific implementation problems.
4. After Codex finishes executing the command, inspect the resulting code changes before proceeding.
5. Do not blindly trust Codex output. Always review the changes and verify that the tests pass.
