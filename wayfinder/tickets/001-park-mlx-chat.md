# Ticket 001 — Park mlx-chat LaunchAgent

**Status:** done (code + MACHINE.md + prove-launchers); **needs** `./rebuild.sh`

**Opened:** 2026-07-23

**Owner:** captain / Layer A

**Repo:** dotfiles

> GitHub Issues are **disabled** on `jwalin-shah/dotfiles`. This file is the
> durable ticket until issues are re-enabled or work moves to portfolio.

## Goal

Park local mlx-chat (`:8080`) so the machine only runs knowledge-path
services (Neo4j + embeds). Document why in MACHINE.md and wayfinder.

## Acceptance

- [x] LaunchAgent removed from `configuration.nix` (parked comment)
- [x] `prove-launchers.sh` does not require mlx-chat
- [x] `MACHINE.md` marks mlx-lm / mlx-chat-daemon / chat model PARKED
- [x] Decision note: `wayfinder/mlx-chat-parked-2026-07-23.md`
- [x] Runtime bootout — `:8080` free
- [ ] `./rebuild.sh` applied (captain) so nix does not reinstall the plist
- [x] Bridge gates updated (machineverify + orbit) — merged in Bridge PR #104

## Why (one paragraph)

Neo4j is the sole knowledge store. Embeds on `:8081`/`:8082` feed cocoindex →
Neo4j; bridge reads Neo4j. mlx `:8080` is a local **chat** server with no
active factory consumer (logs were health-check only) and ~1.4 GB idle RSS.

## Prove after rebuild

```bash
! launchctl print gui/$UID/org.nixos.com.jwalinshah.mlx-chat-daemon 2>/dev/null
! lsof -nP -iTCP:8080 -sTCP:LISTEN
lsof -nP -iTCP:8081,8082 -sTCP:LISTEN
~/projects/dotfiles/bin/prove-launchers.sh
```

## Refs

- `wayfinder/mlx-chat-parked-2026-07-23.md`
- `portfolio/wayfinder/mlx-chat-parked-2026-07-23.md`
- `portfolio/wayfinder/neo4j-sole-store.md`
