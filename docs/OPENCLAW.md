# OpenClaw on this Mac — constitution, TCC, what we are not doing yet

OpenClaw is the **surface**. Inbox, Bridge, HomeBase, Google, and Shortcuts
are how it **touches the world**. Do not give OpenClaw Full Disk Access so it
can “see everything.”

## Live vs declared

| Piece | Today |
|---|---|
| Package | `npm -g openclaw@2026.9.1` (OpenClaw 2.0) via Homebrew **node** (not a brew formula; `zap` will not remove it) |
| State | `~/.openclaw/` (sessions, credentials — not git) |
| Token | `~/.openclaw/service-env/ai.openclaw.gateway.env` (0600; not nix) |
| Port | 18789 |
| Nix agent | `com.jwalinshah.openclaw-gateway` in `configuration.nix` |
| Old agent | `ai.openclaw.gateway` — unload with `bin/openclaw-adopt-nix.sh` before rebuild |

## Who is allowed to read what

| Need | Binary | Permission | How OpenClaw uses it |
|---|---|---|---|
| iMessage, Notes, Reminders | Frozen `~/Applications/inbox-python312/bin/python3.12` | **Full Disk Access** | HTTP to inbox `:9849` (`bin/inbox`). Never FDA on node. |
| Gmail / Calendar / Drive | inbox OAuth and/or OpenClaw Google plugin | OAuth | Capability `gmail.read` later; not Takeout |
| Notifications to you | OpenClaw **node** (after nix pin) | Notifications | LifeOps attention policy decides *whether* |
| Apple Shortcuts | Shortcuts.app | Shortcuts + Notifications | Shortcut POSTs a hook / opens OpenClaw URL. **Not built yet.** Event producer only. |
| Computer use / GUI | Pinned node or Chromium | Accessibility, Screen Recording | **Parked.** Requires Bridge grant. Do not enable to “get access to everything.” |
| HomeBase | `homebase` :9102 | none extra | Status/receipts; cannot mint grants |
| Keeper passwords | — | — | Humans only. Infisical for workload tokens. |

If iMessage reads go empty after a “fix,” the FDA identity on **python3.12**
broke. Do not rebuild that interpreter. Do not insert bash in front of it.

## What we know without building it

- **Shortcuts:** can already run on a schedule or automation; the missing
  piece is a **stable local URL or `openclaw` CLI** with a documented hook
  and an attention class. No new daemon.
- **Computer use:** high blast radius. Same as browser automation: capability
  + grant + verifier (screenshot/DOM), not FDA.
- **“Access to everything”:** is a **routing** problem (inbox + Google +
  FirstMate + Bridge), not one TCC checkbox on OpenClaw.

## AXI vs MCP (Kun Chen, kunchenguid/axi)

[AXI](https://github.com/kunchenguid/axi) is **not** “never MCP.” It is: **MCP
and human CLIs are both expensive for agents** (huge schemas / help text).
Agent-native CLIs (TOON, 3–4 fields, aggregates, empty states, next-step
hints) beat both on tokens and turns. This machine already ships
`gh-axi`, `chrome-devtools-axi`, `lavish-axi`, `tasks-axi`, and
`bin/inbox` (explicitly AXI-flavored, read-only).

Do not confuse with the **axioms** corpus or the old `/axi` skill (renamed
**preflight**).

| Client | Preferred inbox access |
|---|---|
| OpenClaw / Cursor / Claude / Codex **on this Mac** | `bin/inbox` (AXI CLI) → `:9849`. Do not dump the full MCP tool catalog into every session. |
| ChatGPT / other **cloud** brains | HTTP MCP, preferably **read-only** tunnel. They cannot usefully “just run inbox CLI.” |
| Writes | Still inbox Action Gateway + approval lease (MCP full or TUI). AXI CLI stays read-default. |

OpenClaw Google Workspace is a **stock MCP/plugin**. AXI says: wrap Google
(and Apple) behind `inbox`’s compact CLI, not a second Google tool schema
in the model’s context. Improve `bin/inbox` toward the 10 principles; do
not add parallel Gmail MCP into OpenClaw.


```bash
~/projects/dotfiles/bin/openclaw-adopt-nix.sh
# Quote #mac: zsh NOMATCH and bash comments will eat an unquoted flake URI.
cd ~/projects/dotfiles && sudo darwin-rebuild switch --flake "${HOME}/.dotfiles#mac"
~/projects/dotfiles/bin/prove-openclaw-cutover.sh
lsof -nP -iTCP:18789 -sTCP:LISTEN   # exactly one process
lsof -nP -iTCP:9849 -sTCP:LISTEN    # inbox still up
```
