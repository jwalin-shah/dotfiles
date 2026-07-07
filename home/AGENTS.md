# overall agent instructions

Shared by Claude, OpenCode, and Codex (symlinked via home-manager).

- Never use the em dash "—". Use plain dash "-" instead.
- When writing commit messages, NEVER auto-add your agent name as co-author.
- Never manually modify CHANGELOG.md files or any files marked as auto-generated.
- When making technical decisions, prefer quality, simplicity, robustness,
  scalability, and long term maintainability over development speed.
- When doing bug fixes, always reproduce the bug before fixing it.
- Apply a high standard to engineering excellence: lint, test failures,
  and test flakiness should be fixed even if not directly related.

Also see the captain's machine-level CLAUDE.md at ~/CLAUDE.md for
hardware context, approval gates, and tool catalog.
