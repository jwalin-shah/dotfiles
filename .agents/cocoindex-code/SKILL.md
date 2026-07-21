---
name: cocoindex-code
description: Manage the cocoindex daemon — start, stop, health check, reindex.
---

# CocoIndex Code Daemon

## Status
```bash
ccc status
```

## Restart
```bash
# Daemon managed by launchd, use daemon-wrapper
daemon-wrapper restart ccc
```

## Health check
```bash
ccc doctor
```
