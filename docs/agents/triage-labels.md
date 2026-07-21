# Triage Labels

State machine labels applied to issues during triage:

| Label | Meaning |
|-------|---------|
| `needs-triage` | Maintainer needs to evaluate this issue |
| `needs-info` | Waiting on reporter for more information |
| `ready-for-agent` | Fully specified, can be dispatched via bridge spawn |
| `ready-for-human` | Needs human implementation (not agent-ready) |
| `wontfix` | Will not be actioned |

These labels are the default vocabulary. The actual GitHub labels must exist on the repo for the `gh` CLI to apply them.