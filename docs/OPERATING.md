# How we use the machine — operate, commit, worktrees

**Owner:** dotfiles  
**Link map:** [`SYSTEM_MAP.md`](SYSTEM_MAP.md)  
**Prove:** docs mentioned here stay linked from SYSTEM_MAP; run `bin/prove-docs-freshness.sh`

This is the **day-to-day playbook**. Not inventory (MACHINE.md), not philosophy (GLOBAL.md).

---

## 1. Daily loop (what you actually do)

```text
1. orbit status                     # Bridge + neo4j health
2. Pick ONE atom (one job)
3. Route:
     A. Captain edit in a worktree  → commit → PR
     B. Orbit/Bridge spawn          → only when HomeBase+isolation admit
4. Prove (repo tests / prove-*.sh)
5. Land (PR merge) or release/deliver
6. Update MACHINE.md / SYSTEM_MAP if you changed machine linkage
```

**Right now (honest):** full `orbit "…" --yes` worker spawn still needs HomeBase URL+keys (and production wants VM). Until Atom E lands, most real work is **path A**: captain/agent edit in an isolated worktree, commit, PR — still using Bridge proves and Wayfinder discipline.

---

## 2. Git commits — who commits what

| Who | Where | When |
|---|---|---|
| **You / Cursor in a worktree** | Feature branch in that worktree | Normal captain work; one atom per commit preferred |
| **Bridge worker** | Disposable spawn worktree | Only inside admitted spawn; should stay inside `allowed_paths` |
| **`bridge deliver`** | Applies verified tree → publish path | Preferred for `delivery: pr` once trust P0 closes |
| **`bridge release`** | After landed PR/reference check | Records `LandedWorkProof`; releases lease |

### Captain commit rules (this machine)

1. **Never commit on a dirty shared `main` tip** if a promotion/security worktree exists — work in the worktree.  
2. **One atom ≈ one commit** (or small stack); no mega-commits across repos.  
3. **Message:** why, not file laundry list. Use HEREDOC (see captain git rules).  
4. **Do not commit** `.env`, credentials, Keychain exports, `grpc-auth-token`.  
5. **Hooks:** `enforce-bridge-workflow` may require `ORBIT_TASK.md` or `.bridge-task` in that repo before edits.  
6. **Prove before push** when the repo has a prove (`go test`, `prove-docs-freshness`, `check.sh`, …).  
7. **Push / PR** is Tier 3-ish consequential — you approve; don’t let workers own publish forever (gap #7).

### Interim (no HomeBase spawn)

```bash
# Example: document-only atom in portfolio worktree or clean branch
cd ~/projects/portfolio   # or a worktree path
git status -sb
git add -A path/to/atom
git commit -m "$(cat <<'EOF'
Explain why this atom landed.

EOF
)"
# gh pr create … when ready
```

Cross-repo: **separate commits per repo**. Never one commit “fixing” bridge+dotfiles+portfolio together.

---

## 3. Worktrees — three lanes (don’t mix them up)

### Lane A — Captain feature worktrees (`worktree` CLI → `~/.worktrees/`)

For **you** isolating a feature while keeping `main` clean.

```bash
# Always the shell wrapper (changes cwd). Never worktree-bin alone for jump.
worktree create bridge-trust-p0 agent/bridge-trust-delivery-sandbox --from main
worktree jump bridge-trust-p0          # cd into ~/.worktrees/<repo>/bridge-trust-p0
# … edit, commit, push …
worktree back
worktree remove bridge-trust-p0        # when landed
```

Skill: `worktree-manager`. Storage default: `~/.worktrees/<repo>/<feature>/`.

### Lane B — Bridge spawn worktrees (disposable, Bridge-owned)

Created by `bridge spawn` under Bridge’s worktree manager (`internal/worktree`).  
Worker runs in mintmux; Bridge polls `.bridge/manifest.json`.  
On timeout/fail: `ForceReturnWorktree` + kill session.  
**You do not hand-manage these** unless debugging a stuck lease.

### Lane C — Promotion / running-machine lanes (`~/projects/worktrees/`)

Longer-lived parallel checkouts for security promotion / running-machine integration, e.g.:

- `~/projects/worktrees/bridge-running-machine`  
- `~/projects/worktrees/bridge-security-promotion`  
- `homebase-*`, `trajectory-*`, …

Use these for **risky Bridge/HomeBase work** instead of dirtying `agent/quota-opportunity-routing` or `main`. Commit **inside that worktree’s branch**.

| Lane | Path pattern | Lifetime | Who creates |
|---|---|---|---|
| A Captain feature | `~/.worktrees/<repo>/<feature>/` | Until PR merges | `worktree create` |
| B Spawn | Bridge-managed worktree | One attempt | `bridge spawn` |
| C Promotion | `~/projects/worktrees/<name>/` | Days/weeks | Human / prior tickets |

**Rule:** don’t edit the same files in two lanes at once. Prefer C for Bridge trust P0; A for small portfolio/dotfiles atoms; B only when spawn admits.

---

## 4. How Orbit / Bridge fit commits

```text
orbit captures ticket+brief
  → (gates) HomeBase grant + isolation
  → spawn worktree (Lane B)
  → worker may commit inside allowed_paths
  → bridge verify (fresh tree)
  → bridge deliver / release   # publish + proof
  → ledger records outcome
```

If gates fail (as on 2026-07-30 drive): **no worktree, no worker commit** — only ledger failure. That’s correct fail-closed.

Until HomeBase is up: use Lane A/C + your commits; still run `orbit status` and repo proves.

---

## 5. Dotfiles-specific

| Action | How |
|---|---|
| Change LaunchAgent / package | Edit nix → update MACHINE.md → `prove-docs-freshness` → `./rebuild.sh` (Tier 3) |
| Change skills | Edit `.agents/` → `prove-skills.sh` → rebuild to project |
| Change linkage docs | SYSTEM_MAP + MACHINE in same commit |
| Commit | From a clean branch/worktree; don’t rebuild mid-flight without captain |

---

## 6. Cheat sheet

```bash
orbit status
bin/prove-docs-freshness.sh
bin/prove-launchers.sh

# Captain isolation
worktree create <feature> <branch> --from main
worktree jump <feature>

# After HomeBase+isolation green
orbit "In <repo>: <one atom with tensor/proof/spec/approval>" --yes
# or: bridge spawn ticket.json brief.md
# watch: tail -f <repo>/.bridge/ledger.jsonl

git status -sb
git commit …    # why
gh pr create …
```

## 7. What to do when many repos are dirty (fleet triage)

Do **not** try to commit everything in one pass. Sort by lane:

| Priority | Repo class | Action |
|---|---|---|
| P0 | **dotfiles** (constitution + proves) | One commit (or small stack) on `main`/`docs` branch: SYSTEM_MAP, OPERATING, MACHINE, prove scripts, skills. Then captain `./rebuild.sh` so GLOBAL/skills/hooks project. |
| P0 | **portfolio** one-surface / DRIVE docs | Commit Wayfinder notes separately from unrelated portfolio dirt. Prefer clean branch or worktree if `HEAD` detached. |
| P1 | **running-machine-contracts** (schemas, AuthorityChain, ONE_SURFACE) | Commit contract artifacts on dedicated branch; leave unrelated dirt out. |
| P1 | **bridge** dirty tip | Do **not** pile onto `agent/quota-opportunity-routing`. Use `~/projects/worktrees/bridge-running-machine` (Lane C) for trust/HomeBase work. |
| P2 | CONTEXT/DESIGN seeds (orbit, KE, axioms, …) | Batch “universal pocock stubs” per repo as chore commits, or one PR each — low urgency. |
| P2 | homebase/mintmux/trajectory large dirt | Isolate; don’t mix with today’s docs drive. |

**Rules**

1. One repo → one PR thread.  
2. Detached `HEAD` (portfolio/orbit seen that way): create a branch before commit (`git switch -c …`).  
3. `bridge orbit` claim `no-dirty-repos` stays red until dirt is landed or explicitly waived in a worktree note.  
4. After dotfiles commit: rebuild once so **all providers** see the same GLOBAL/hooks/skills.

---

## 8. Config consistency across providers (ca / ct / cx / Cursor / agy)

### Source of truth

| Kind | Canonical source | Live projection |
|---|---|---|
| Principles | `dotfiles/GLOBAL.md` | `~/CLAUDE.md`, `.codex/AGENTS.md`, `.cursor/AGENTS.md`, `.gemini/AGENTS.md` via home-manager |
| Hooks | `dotfiles/home/.<harness>/…` | `~/.claude`, `~/.codex`, `~/.cursor`, `~/.gemini` (force symlink / store) |
| Skills | `dotfiles/.agents/*` | Copied into Claude/Codex/Cursor skills dirs on **rebuild** |
| Inventory / linkage | `MACHINE.md`, `docs/SYSTEM_MAP.md` | Docs only — proved by `prove-docs-freshness.sh` |

**Never edit live `~/.claude/settings.json` etc. by hand** — change `dotfiles/home/…` and rebuild.

### How we know they match

```bash
# Hooks gate+fmt wired the same policy across harnesses (event names differ per vendor)
bin/prove-harness-hooks.sh

# Cursor-specific event names
bin/prove-cursor-hooks.sh

# Skills present in .agents
bin/prove-skills.sh

# Machine docs + PARKED + PATH
bin/prove-docs-freshness.sh

# Bundle (includes docs freshness)
bin/prove-launchers.sh
```

Invariant (from portfolio harness matrix): for every harness that can write factory code,

```text
live(H) == source(H)  ∧  enforce wired  ∧  fmt→neo4j wired  ∧  prove-harness-hooks exits 0
```

Known **WAIVER**: Codex shell bypass until vendor adds a shell pre-hook — documented in prove output, not silently ignored.

### Skills caveat

Cursor product skills (`canvas`, `create-hook`, …) are **separate** from nix `.agents` skills. Prove `.agents` with `prove-skills.sh`; don’t assume Cursor built-ins == Claude skills.

### After you change GLOBAL / hooks / skills

1. Commit in dotfiles  
2. `bin/prove-harness-hooks.sh && bin/prove-skills.sh && bin/prove-docs-freshness.sh`  
3. Captain `./rebuild.sh` (Tier 3)  
4. Re-run `prove-harness-hooks.sh` — must still PASS against live paths  

Without rebuild, interim symlinks under `~/.agents/skills` may help Cursor/Claude see restored skills, but HM is the durable consistency mechanism.

---

## Related

- Spawn gates / isolation: SYSTEM_MAP  
- Drive evidence: `portfolio/wayfinder/one-surface-system-2026-07-30/DRIVE_LOG.md`  
- Bridge trust P0 (deliver + sandbox): that folder’s `bridge-trust-p0.md`
- Harness matrix: `portfolio/wayfinder/harness-activation-matrix-2026-07-22.md`