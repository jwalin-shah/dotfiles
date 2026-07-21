---
name: cocoindex
description: Semantic code search via cocoindex. Indexes 13 repos with dual embeddings for code-aware search.
---

# CocoIndex Code

## Context integration

When bridge assembles a context packet for a spawn, `SearchSource` runs `ccc search` with the ticket's acceptance criteria as the query. Results are fused with `rg` grep via RRF (Reciprocal Rank Fusion) and injected into the context packet as `CodeSearchHits`.

## Commands

```bash
ccc status      # index health across 13 repos
ccc search "how does bridge handle sandbox profiles"  # semantic search
ccc grep "Spawn(" --lang go  # structural grep
```

## Daemon

The daemon watches 13 repos and auto-updates indices. Managed via `launchd` + `daemon-wrapper`:
```
ccc run-daemon
```
