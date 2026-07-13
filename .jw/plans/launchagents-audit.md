# LaunchAgents/Daemons audit (read-only, 2026-07-13)

## Healthy + declared in configuration.nix (nix-managed, org.nixos.com.jwalinshah.* namespace)
Running per `launchctl list`: mintmux, inbox-server, llama-embed-server, auto-save,
m5logd, mlx-chat-server (PID 28624, last exit -15/SIGTERM but currently alive - not
a crash loop, just a prior restart), cocoindex-daemon, coderank-embed-server,
voice-engine, jw-cred-canary. All 10 match a declared block in configuration.nix.

`cognee-api` is declared and running but shows last-exit status **2** (nonzero) in
`launchctl list` - worth checking logs, may be crash-looping and restarting via KeepAlive.

`m5fand` is declared in configuration.nix but deployed as a root-owned system
daemon (`/Library/LaunchDaemons/org.nixos.com.jwalinshah.m5fand.plist`) rather than
a user agent - expected, fan control needs root, nix-darwin routes it correctly.

## Healthy + undeclared (reproducibility gap)
`com.jwalinshah.voice-paste` - running, plist lives at
`~/Library/LaunchAgents/com.jwalinshah.voice-paste.plist` with **no** `org.nixos.`
prefix, meaning it was installed by hand, not by nix-darwin. A fresh machine
would not get this back. Same class of gap as the earlier gh-axi npm-global issue.

There's also `org.nixos.com.jw.heal.plist` on disk (different Label prefix,
`com.jw.*` not `com.jwalinshah.*`) - present but not matched by the
`com.jwalinshah.*` search pattern used here; likely nix-managed under a
differently-named block, not independently verified this pass.

## Not nix-managed, expected to be external
`homebrew.mxcl.tailscale.plist` (root, /Library/LaunchDaemons) - installed by
`brew services` for the tailscale formula, not part of jw-* nix declarations.
`com.kunchenguid.no-mistakes.daemon.*` - vendor-installed by the no-mistakes tool itself.

## Stale binary path (matches the adblock pattern)
`com.jwalin.adblock.plist` (root, /Library/LaunchDaemons) - not loaded, points at
retired `~/.local/bin/fm-adblock` (pre jw- rename). Already flagged separately.

## Documentation vs reality
`~/CLAUDE.md` section 12 lists **jw-sentry**, **jw-sessiond**, and
**quota-keychain-sync** as running background services. No plist for any of
these three exists anywhere on disk (`~/Library/LaunchAgents`,
`/Library/LaunchDaemons`, `/Library/LaunchAgents`), and none appear in
`launchctl list`. Either they were retired without updating the doc, or they
were never actually deployed on this machine - the doc is stale either way.
