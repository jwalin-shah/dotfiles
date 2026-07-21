---
name: cocoindex-code
description: CocoIndex Code daemon — manages the indexing daemon for code search.
---

# CocoIndex Code

Manage the ccc indexing daemon.

## Commands

- `ccc run-daemon` — start the daemon
- `ccc status` — check daemon health

## Integration

The daemon watches 13 repos and auto-updates indices. Managed by system daemon-wrapper + launchd.
