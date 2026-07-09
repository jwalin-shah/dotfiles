# Orca — Patterns to Steal, Weight to Drop

## What Orca Got Right

### 1. Computer-Use (the killer feature)
Agents read accessibility trees, take screenshots, click, type, scroll.
This lets agents interact with ANY desktop app — not just terminals.
macOS has all the APIs built in. We don't need Orca for this.

### 2. Worktree Isolation
Every agent gets its own git worktree. No conflicts. Clean teardown.
**We have this.** treehouse does exactly this.

### 3. Mobile Companion
Phone pairing via `orc pair`. Remote control from phone.
**Lightweight alternative:** jw-status on Tailscale. A simple HTTP dashboard
reachable from phone. No Electron app needed.

### 4. Inbox-Based Orchestration
Tasks arrive as inbox items. Rich metadata per task.
**We have this.** firstmate's backlog.md + tasks-axi. Structured, file-based.

### 5. Trinity Cycle (Thinker → Worker → Verifier)
Three-phase agent workflow:
- Thinker: decomposes intent into work plan
- Worker: implements the plan
- Verifier: validates the result (no-mistakes pipeline)
**Pattern:** our jw protocol maps to this naturally.
  decompose → dispatch → validate → gate → captain → respond

## What Made Orca Heavy (and Wrong for Us)

| Problem | Why | Our Fix |
|---------|-----|---------|
| Electron app | 500MB+, slow startup | Native Go binaries, no UI framework |
| Opaque agents | Can't see what's happening | events.jsonl → real-time visibility |
| External dependency | Another app to install/manage | Everything in ~/.local/bin |
| Managed lifecycle | Orca owns the agents | We own the agents. firstmate supervises. |

## Our Lightweight Versions

### Computer-Use (Go binary, ~50KB)
```
jw-computer-use screenshot        → PNG to stdout/mintmux
jw-computer-use tree              → AXUIElement tree as JSON
jw-computer-use click "Send"      → find + click button
jw-computer-use type "hello"      → CGEvent keyboard injection
```
Zero dependencies. macOS APIs are C, Go can call them via cgo or syscall.
Already proven: voice-engine Paster uses CGEvent in Swift. Same pattern.

### Trinity Cycle (events.jsonl)
```
decompose   → "what should we do?"
dispatch    → agent gets brief + worktree
execute     → agent works, events flow to events.jsonl
validate    → no-mistakes pipeline on branch
gate        → captain reviews, approves/redirects
respond     → agent continues, loop to validate
done        → thread_done event, teardown worktree
```

### Mobile Access (Tailscale + HTTP)
```
jw-serve                     → starts :9090 HTTP server (already exists in jw-core)
phone browser                → https://<tailscale-ip>:9090 → thread list + approve/answer
```
No pairing. No companion app. Just your Tailscale mesh + a web browser.
