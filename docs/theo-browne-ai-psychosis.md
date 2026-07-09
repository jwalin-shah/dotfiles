---
name: theo-browne-ai-psychosis-talk
description: Theo Browne's "AI Psychosis" talk at AI Engineer 2026 — the full transcript and how it applies to this machine
metadata:
  type: reference
---

# Theo Browne — AI Psychosis (AI Engineer 2026)

## The talk summarized

Theo argues we're in the "skeuomorphic phase" of software development — building
things that look like old things because they're familiar, not because they're
right. iOS 7 was the transition from skeuomorphism to flat design. Software
development needs the same transition.

### The three tiers have shifted down

| Old tier | New tier | Example |
|----------|----------|---------|
| Too big | Startup | Building your own AWS, competing with npm |
| Startup | Side project | Full-stack cloud platforms |
| Side project | **Markdown file** | A prompt piped to an agent on a cron |

Theo's PR triage system is a markdown file. No code. Just a prompt + cron.

### Models outpace us

- Sonnet 3.5 = "tool call era" (first model that did tool calls reliably)
- Opus 4.5 = "long-running tasks" (hours-long work, no babysitting)
- Mythos = "orchestration" (spawns sub-models, breaks up work, verifies)
- Each jump makes our old habits less relevant

### What to do about it

1. **Delete ruthlessly.** Sunk cost fallacy is the enemy. Agents don't feel bad
   when you kill their work. You shouldn't either.
2. **Go wider, not deeper.** Don't compete on depth of features. Build across
   the spectrum. Architect so users extend what you didn't build (like Slack
   became the agent platform accidentally).
3. **Stop identifying with your stack.** Languages, frameworks, tools — not
   identity. Implementation details that matter less every day.
4. **Go bigger than makes sense.** The top tier is unknown now. Only way to find
   the limit is to push past where it makes sense.
5. **The markdown tier is real.** If your product could be a markdown file piped
   to an agent, it should be.

## How we're applying this to the captain's machine

### Already done

- **Skeuomorphism killed:** The old `claude-launch` with its Python agentlib,
  TOML config, Infisical secrets, preflight pings — that was skeuomorphic. It
  looked like "real infrastructure." The new `claude-wrapper` is 3 lines of
  bash calling `npx`. That's iOS 7.

- **Python exec-wrappers killed:** `cu-wrapper`, `cx-wrapper`, `ko-wrapper`,
  `oo-wrapper` — all 5-line Python scripts doing nothing but `os.execvp()`.
  Rewritten as 3-line bash. Python interpreter startup for a no-op was the
  definition of skeuomorphic.

- **Deletion first:** 20+ files deleted this session. 580 lines removed, 425
  added. Net negative diff. No guilt.

- **Brew cask gone:** Homebrew's `claude-code` cask installed a stub that called
  `claude-launch` which called another wrapper which called... a loop. Gone.
  `npx` directly. One hop.

- **One config directory, not many:** `claude-endpoints.toml` was a config-layer
  between you and the model. Now the wrapper IS the config. Wanna change the
  model? Edit the 3-line bash file. What would Theo say? "That used to be a
  startup idea, now it's a bash file."

### The markdown tier applied to our setup

The Firstmate `jw-*` system (57 files, 5000+ lines of shell) is overdue for
this question: **could any of this be a markdown file?**

The orchestrator at its core:
1. Reads intent → decomposes → dispatches
2. Tracks state → gates → approves
3. Supervises → health checks → teardown

With Mythos, you could replace significant portions with a prompt:
- "Here are my 10 repos. Look at open PRs in each, review them, prioritize,
  and give me a morning brief."
- That's a markdown file + cron. Theo's PR triage system.

Not saying `jw` should be killed — the state tracking and LaunchAgent
supervision need real code. But the decomposition/dispatch logic? Markdown
tier candidate.

### What we still need to apply

1. **Go wider, not deeper.** The agent fleet (claude/ca/ct + codex + kilo +
   opencode + agy + cursor) already covers the spectrum. The wrappers shouldn't
   get deeper — they should be shells that users (crewmates) can extend.

2. **Stop identifying with Go.** The ponytail principle says Go is the default
   for daemons. But Theo would ask: does it need to be Go? Or is that skeuomorphic
   identity? The wrapper rewrite (Python→bash) applied this. More to do.

3. **What's "too big" now?** Training your own model? Building an OS? Competing
   with npm? The captain is already pushing this edge with the MLX local stack,
   Cognee knowledge graphs, and the agent fleet. The answer isn't "do less" —
   it's "go bigger, but with simpler pieces."

### The test for every file on this machine

For every file, script, config, plist, repo — ask Theo's question:

> "Is this how we do it because it's right, or because it's just how we've
> always done it?"

If it's the second, delete it.

---

*Saved from the captain's Claude Code session on 2026-07-08. Talk transcript
and principles from Theo Browne at AI Engineer 2026.*
