# Red-Team Audit Findings — dotfiles Session

## CRITICAL ISSUES

### 1. **Function Definition Order Bug in bootstrap-projects.sh**
**Severity: BLOCKER** — Script will fail on any fresh machine.

Lines 28-37 call `log()`, `green()`, `red()`, and `dim()` functions BEFORE they're defined (lines 40-44). Worse, the system macOS `log` command shadows any user-defined function with that name, so line 28 (`log "=== Phase -1..."`) tries to invoke `/usr/bin/log` (system logging CLI) instead of the bash function.

**Impact:** Bootstrap script exits immediately with "Unknown subcommand" error.
**Fix:** Move function definitions (lines 40-51) to the top of the script, before Phase -1 code (line 28).

---

## HIGH-PRIORITY CONSISTENCY ISSUES

### 2. **Stale Documentation in CLAUDE.md §12**
**Severity: HIGH** — Misleads agents about available services.

Section 12 documents these as running services:
- `jw-sentry` — not present as LaunchAgent anywhere
- `jw-sessiond` — not present as LaunchAgent anywhere  
- `quota-keychain-sync` — not present as LaunchAgent anywhere

**Reality:** Only mintmux + m5tools are active in `~/.local/bin` ecosystem (per captain's note). Others were planned but never deployed.

**Impact:** Agents directed to non-existent tools; wastes time troubleshooting. Conflicts with captain's stated scope.
**Fix:** Update §12 to match actual running services (mlx-chat-server, llama-embed-server, cognee-api, cocoindex-daemon, mintmux, voice-engine, inbox-server, m5logd, m5fand, jw-cred-canary, auto-save).

---

### 3. **Tool Registry (TOOL_REGISTRY.md) Drift from Reality**
**Severity: HIGH** — Policy document contradicts deployed tooling.

Registry claims ACTIVE:
- `fastedit` — not on PATH
- `pioneer` (fastino) — not on PATH

Registry "Skills installed" table lists non-existent skills:
- `find-docs`, `tool-policy`, `pioneer-api`, `inference-net`

But actually 30 real skills exist in `~/.agents/skills/` (25 nix-managed + 5 unmanaged local dirs).

Contradicts CLAUDE.md §2 which lists `dust` as "always available" while registry marks it blocked.

**Impact:** Agents follow wrong tool policy; confusion about what's installed.
**Fix:** Audit TOOL_REGISTRY.md against current reality and CLAUDE.md. Recommend: mark `fastedit`/`pioneer` as PLANNED or remove. Update skills table to reference actual 30 skills or link to `~/.agents/skills/`.

---

### 4. **GLOBAL.md References Non-Existent `fastedit`**
**Severity: MEDIUM** — Recommended tool doesn't exist.

Section 2 says "Use `fastedit edit` only for intentional model-assisted edits" but `fastedit` is not installed.

**Fix:** Remove or mark conditional on tool availability.

---

## MODERATE ISSUES

### 5. **Container Brew Addition Undocumented**
**Severity: MEDIUM** — Added to configuration.nix but purpose unclear.

Line 179 of `configuration.nix` adds `container` (Apple's containerization CLI) with no comment or explanation. Container is not running as a LaunchAgent, not mentioned in MACHINE.md.

**Impact:** Unclear if this is experimental, intended for future use, or cargo-cult addition. No maintenance path.
**Fix:** Either (a) add a comment explaining why container was added, or (b) wire it up as a LaunchAgent if it should be active, or (c) remove it if no longer needed.

---

### 6. **MACHINE.md Already Stale Since 2026-07-13**
**Severity: MEDIUM** — Status document not being actively maintained.

MACHINE.md documents items marked OPEN or GAP but provides no tracking mechanism:
- 5 Python venvs (pip→uv migration) — status unknown since line wrote
- ghostty config symlink — "one-line fix pending" (line 119)
- deny-list additions to ~/.claude-a and ~/.claude-token — status unknown
- com.jwalin.adblock.plist deletion — blocked on captain approval but no follow-up
- cognee-api exit code 2 — needs investigation (line 100) but no resolution noted

**Impact:** Audit findings not being actioned; drift between documented and actual state grows.
**Fix:** Establish a weekly/monthly sync to update MACHINE.md status, or convert to a ticketed system with explicit action items.

---

### 7. **npm Activation Hook May Cause Churn**
**Severity: LOW** — Potential efficiency issue.

home.nix line 191 runs `npm install -g gh-axi chrome-devtools-axi lavish-axi` on every rebuild, even if already installed at the same version. This triggers npm resolution and potential version upgrades every time.

**Impact:** Slower rebuilds, potential version drift if npm resolves newer SemVer matches.
**Fix:** Consider pinning npm package versions explicitly or checking installed version before installing. Acceptable as-is if rebuilds are infrequent.

---

### 8. **cognee-api LaunchAgent Exit Code 2 Unexplored**
**Severity: LOW** — May indicate latent crash loop.

MACHINE.md notes cognee-api showing exit code 2, marked as OPEN but not investigated. launchctl shows: `org.nixos.com.jwalinshah.cognee-api` with exit code 2.

**Impact:** If cognee-api is crashing repeatedly, it burns CPU in a restart loop. Low actual risk if service isn't actively used yet.
**Fix:** Run `launchctl start com.jwalinshah.cognee-api` and check logs in `~/.local/share/jw/cognee-api.log`. If crashes confirmed, move to STALE with root cause.

---

## SUMMARY

**1 BLOCKER** (bootstrap-projects.sh function order) must be fixed before fresh-machine bootstrap works. **3 HIGH** items (stale docs in CLAUDE.md, Tool Registry drift, fastedit reference) undermine agent confidence and need correction. All fixable in ~30 min.

No syntax errors in nix files, no security concerns in container addition or npm hook, no blocking dependency-order issues in build scripts (go and gh-axi are available when needed).
