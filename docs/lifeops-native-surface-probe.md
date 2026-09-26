# LifeOps native surface probe

`bin/lifeops-native-surface-probe.py` is the Mac-side accessibility observer
for native Gemini, Grok Bot, and Perplexity surfaces.

It is installed as the user LaunchAgent
`ai.openai.lifeops-native-surface-probe`. On 2026-09-26, the LaunchAgent was
disabled and unloaded because the previous implementation requested window
restoration; it must not be re-enabled until a passive attachment path is
independently verified.

It invokes Orca's accessibility tree reader, checks for an exact previously
issued UI canary marker, and—only with `--apply`—records a surface-scoped
evidence checkpoint in OCI. It never clicks, types, sends, edits, restores, or
foregrounds a provider window, and it never grants authority. The result proves
only that the named native UI path was observed.

The probe requests a normal Orca capture (including the temporary screenshot
capture) because macOS shared-window sessions can expose only a
`WindowSharingSessionButton` wrapper when the screenshot-free path is used
before the session is attached. The probe reads only `treeText`; it does not
persist or transmit the screenshot. If that wrapper remains, the probe reports
`UNAVAILABLE` with `shared_window_session_not_attached` instead of weakening
the result to `UNPROVEN`.

```text
bin/lifeops-native-surface-probe.py
bin/lifeops-native-surface-probe.py --apply
```

The observer intentionally does not promote a surface to `VERIFIED` or make it
dispatchable. Adapter, identity, entitlement, policy, and governed mutation
proofs remain independent gates. Muse is not included because its current
account authorization is not proven; HyperAgent uses a separate browser/MCP
adapter path.
