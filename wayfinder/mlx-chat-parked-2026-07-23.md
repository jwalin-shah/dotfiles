# mlx-chat parked — 2026-07-23

**Owning repo:** dotfiles

**Ticket:** [`wayfinder/tickets/001-park-mlx-chat.md`](tickets/001-park-mlx-chat.md)
(GitHub Issues disabled on `jwalin-shah/dotfiles` — file ticket is SoT)
**Cross-ref:** `portfolio/wayfinder/mlx-chat-parked-2026-07-23.md`

## Decision

Stop and remove the **mlx-chat** LaunchAgent (`org.nixos.com.jwalinshah.mlx-chat-daemon`, `:8080`). Do not re-enable without an explicit ticket + MACHINE.md update.

## Why (evidence)

1. **Neo4j is the sole knowledge store.** Indexing does not call `:8080`.
2. **What feeds Neo4j:** llama-embed `:8081` + coderank-embed `:8082` (cocoindex dual embed) and `tldr` structure/calls. Bridge **reads** Neo4j at spawn.
3. **mlx was idle:** `~/.local/share/orbit/mlx-chat.log` showed almost only `GET /health` from orbit/verify-machine — no chat completions on the factory path.
4. **Cost:** ~1.4 GB RSS always-on for unused local chat.

Same session: orphaned `python -m livelm.api` on `:8000` (btw-v1 Codex leftover) was killed — also unused.

## Diff surface (dotfiles)

| File | Change |
|------|--------|
| `configuration.nix` | LaunchAgent block removed; parked comment |
| `bin/prove-launchers.sh` | Dropped from required agents |
| `config/orbit/models.env` | Chat block marked PARKED (vars kept for optional scripts) |
| `MACHINE.md` | mlx-lm / mlx-chat-daemon / model row → PARKED |

## Downstream (bridge — separate PR/commit)

| File | Change |
|------|--------|
| `internal/machineverify/configconsistency.go` | Daemon health row removed |
| `cmd/bridge/orbit.go` | “all healthy” no longer requires `:8080` |

## Apply

```bash
cd ~/projects/dotfiles && ./rebuild.sh
cd ~/projects/bridge && go build -o ~/.local/bin/bridge ./cmd/bridge
# prove
./bin/prove-launchers.sh
# expect :8080 free; :8081/:8082 + neo4j up
```

## Re-enable

1. Open a ticket with a real consumer (who calls `/v1/chat/completions`?).
2. Restore LaunchAgent from git history into `configuration.nix`.
3. Restore prove-launchers + machineverify + orbit checks.
4. Update MACHINE.md PARKED → OK.
5. `./rebuild.sh`.
