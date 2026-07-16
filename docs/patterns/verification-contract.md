# verification-contract: Proof That Every Task Was Actually Done

**Status**: active
**Applies to**: all jw-* development, firstmate task lifecycle, crewmate dispatch

## Problem

Agent-driven development produces evidence scattered across terminals, git
history, pipeline logs, and provider dashboards. Without a standardized proof
contract, there is no way to answer "did the agent actually do what it said it
did?" without manually reconstructing each task's trail. The Trinity operating
model (Thinker -> Worker -> Verifier -> Evaluate) needs each phase to produce
machine-verifiable evidence before the next phase can proceed.

## How It Works

Every task produces a **proof bundle** -- a structured set of artifacts that
together prove the work was done correctly. The bundle is assembled by the
worker (crewmate), validated by the verifier (no-mistakes pipeline), and
evaluated by the captain (or firstmate under yolo). No task is "done" until
its proof bundle is complete and verified.

The proof bundle is not a new file format. It is the set of existing artifacts
-- git diffs, test output, pipeline run records, report files, captain
approvals -- organized by task category so each category has a clear,
non-negotiable minimum bar.

---

## 1. Proof Types by Task Category

### 1.1 Code Change (Ship Task)

A ship task modifies project source code and delivers through the project's
delivery mode (no-mistakes, direct-PR, or local-only).

**Required proof artifacts:**

| Artifact | Source | Verifies |
|---|---|---|
| Git diff | `git diff base...HEAD` | What changed, and only what was intended |
| Test output | no-mistakes test step or `go test -race ./...` | Nothing broke |
| Lint/vet output | no-mistakes lint step or `go vet ./...` | Code is well-formed |
| Pipeline run record | `no-mistakes axi status --run <id>` | Every gate passed |
| Review findings | no-mistakes review step output | No correctness bugs, no obvious cleanups missed |
| CI status | GitHub Checks tab on the PR | All remote checks green |
| PR URL | GitHub PR | The change is reviewable, mergeable |

**Minimum bar for "done":**
- Diff is clean (only intended changes, no debug prints, no commented-out code)
- Tests pass locally AND in CI
- Lint/vet clean
- Review findings resolved (fixed or explicitly accepted by captain)
- PR is open, checks green, captain has merged (or firstmate merged under yolo)

**Where evidence lives:**
- Pipeline evidence: `NM_HOME` run database (queryable via `no-mistakes axi status`)
- Test evidence: `.no-mistakes/evidence/<branch>/` when `StoreInRepo` is true, otherwise `$TMPDIR/no-mistakes-evidence/<run-id>/`
- Diff and commit history: git (permanent)
- PR and CI: GitHub (permanent)

### 1.2 Investigation / Scout

A scout task investigates, plans, reproduces a bug, or audits. Its deliverable
is knowledge, not a code change.

**Required proof artifacts:**

| Artifact | Source | Verifies |
|---|---|---|
| Report file | `data/<id>/report.md` | Findings are written down, not just claimed |
| Data cited | paths to files read, tools run, benchmarks executed | Claims are grounded in evidence |
| Reproduction steps | in report (if bug investigation) | Someone else can reproduce it |
| Relevant code/log excerpts | inline in report or linked | Findings are traceable to source |

**Minimum bar for "done":**
- Report exists at `data/<id>/report.md`
- Report cites specific files, line numbers, command output, or benchmark results
- If investigating a bug: reproduction steps are explicit enough that a crewmate could follow them
- Captain has read the findings and confirmed (verbally or via task close)

**Where evidence lives:**
- Report: `firstmate/data/<id>/report.md` (survives worktree teardown)
- Supporting artifacts: referenced by path in the report, may live in the (now-torn-down) worktree if not copied out
- Captain confirmation: implicit in task close or explicit in chat

### 1.3 Infrastructure

An infrastructure task changes running services, deployments, launchd plists,
or machine config.

**Required proof artifacts:**

| Artifact | Source | Verifies |
|---|---|---|
| jw-status output | `jw-status` or `jw-status validate` | Services are running as expected |
| Service health checks | `lsof -i :PORT` for each TCP service, `ccc doctor` for cocoindex | Each port is bound, each daemon is alive |
| Log excerpts | `/tmp/<service>.log` tail (relevant lines only) | No crash loops, no error storms |
| Config diff | `git diff` of changed plists, env files, or launch scripts | Only intended config changes |

**Minimum bar for "done":**
- Every affected service is running and healthy
- `jw-status validate` passes (all expected ports bound, all daemons responding)
- Logs show clean startup (no crash loops, no fatal errors since change)
- Config changes are committed and pushed (if in a tracked repo)

**Where evidence lives:**
- Service state: live on the machine (verified by `jw-status`)
- Config: in the relevant repo (machine-scratch for plists/launchd, project repo for app config)
- Logs: `/tmp/<service>.log` (ephemeral, excerpted into report if permanent record needed)

### 1.4 Decision

A decision task requires the captain to choose between options. The proof is
the captain's explicit approval, recorded so it is auditable.

**Required proof artifacts:**

| Artifact | Source | Verifies |
|---|---|---|
| Captain approval | chat message, `axi respond`, or PR merge | Captain explicitly said yes |
| Decision context | the brief or preceding scout report | What was decided and why |
| No-mistakes gate response | `no-mistakes axi respond --run <id> --finding <n> --action <action>` | Machine-recorded approval for pipeline gates |

**Minimum bar for "done":**
- Captain's "yes" is explicit and attributable (a chat message, a merge click, an `axi respond`)
- The decision is recorded in the task's trail (PR merge, report close, or backlog note)
- For no-mistakes `ask-user` findings: the response is recorded in the run database

**Where evidence lives:**
- Pipeline decisions: `no-mistakes` run database (`NM_HOME` sqlite)
- Merge decisions: GitHub PR audit log

### 1.5 Deletion / Cleanup

A cleanup task removes code, files, services, or configurations.

**Required proof artifacts:**

| Artifact | Source | Verifies |
|---|---|---|
| Before state | `du -sh <target>` or `ls -la <target>` before removal | What existed before |
| After state | `du -sh <target>` or `ls -la <target>` after removal | What was actually removed |
| Git diff | `git diff --stat` showing deletions | Removed code is tracked |
| Service check | `lsof -i :PORT` confirming port is free (if removing a service) | Service is actually gone |

**Minimum bar for "done":**
- Before/after evidence shows the intended removal
- No orphaned references (imports of deleted code, symlinks to deleted paths, launchd refs to removed plists)
- If removing a service: port is free, process is gone, launchd plist is unloaded
- Git diff shows only deletions (no accidental collateral damage)

**Where evidence lives:**
- Before/after: captured in the task's report or commit message
- Git history: permanent record of what was deleted
- Service state: live on the machine

---

## 2. Run Manifest

Every agent task execution produces a run manifest -- a canonical JSON record
of what was asked, what was done, and what proof exists. The manifest is
assembled from existing records; the agent does not hand-write it.

### 2.1 Schema

```json
{
  "schema_version": "1.0",
  "run_id": "run_20260703T143000Z_jw_ui_terminal",
  "task_ref": {
    "id": "jw-ui-terminal",
    "kind": "ship",
    "project": "jw-ui",
    "mode": "no-mistakes"
  },
  "work_order_ref": {
    "source": "firstmate",
    "brief_path": "data/jw-ui-terminal/brief.md",
    "authorized_by": "captain"
  },
  "repo_ref": {
    "path": "/Users/jwalinshah/projects/jw-ui",
    "worktree": "/tmp/treehouse/jw-ui-abc123",
    "branch": "fm/jw-ui-terminal",
    "head_sha": "abc123def456",
    "base_sha": "789ghi012jkl",
    "dirty": false
  },
  "runner_ref": {
    "harness": "claude",
    "model": "sonnet",
    "effort": "high"
  },
  "commands": [
    {
      "purpose": "build",
      "argv": ["npm", "run", "build"],
      "exit_code": 0,
      "stdout_path": ".no-mistakes/evidence/fm/jw-ui-terminal/build.stdout",
      "stderr_path": ".no-mistakes/evidence/fm/jw-ui-terminal/build.stderr"
    },
    {
      "purpose": "test",
      "argv": ["npm", "test"],
      "exit_code": 0,
      "stdout_path": ".no-mistakes/evidence/fm/jw-ui-terminal/test.stdout"
    }
  ],
  "validation_ref": {
    "pipeline": "no-mistakes",
    "run_id": "nm_run_abc123",
    "status": "succeeded",
    "steps": {
      "review": "passed",
      "test": "passed",
      "lint": "passed",
      "pr": "opened",
      "ci": "passed"
    }
  },
  "evidence_refs": [
    {
      "type": "test_output",
      "path": ".no-mistakes/evidence/fm/jw-ui-terminal/test.stdout",
      "summary": "3 tests passed, 0 failed"
    },
    {
      "type": "diff",
      "path": "<git>",
      "summary": "+127 -43 across 5 files"
    },
    {
      "type": "pr",
      "url": "https://github.com/jwalinshah/jw-ui/pull/3",
      "status": "merged"
    }
  ],
  "risk_ref": {
    "external_write_allowed": false,
    "pushed_to_remote": true,
    "force_push": false,
    "privacy_risk": "low"
  },
  "handoff_ref": {
    "captain_approved": true,
    "approval_method": "merge",
    "approved_at": "2026-07-03T15:00:00Z"
  }
}
```

### 2.2 Manifest Assembly

The manifest is assembled from sources the agent already touches. No agent
hand-writes JSON.

| Field | Assembled from |
|---|---|
| `run_id` | Generated: `run_<ISO timestamp>_<task id>` |
| `task_ref` | `state/<id>.meta` (written by `fm-spawn.sh`) |
| `work_order_ref` | `data/<id>/brief.md` (written by `fm-brief.sh`) |
| `repo_ref` | `state/<id>.meta` + `git rev-parse HEAD` + `git rev-parse origin/<default>` |
| `runner_ref` | `state/<id>.meta` (harness, model, effort recorded at spawn) |
| `commands` | no-mistakes test step captures each command with exit code and output paths |
| `validation_ref` | `no-mistakes axi status --run <id> --json` |
| `evidence_refs` | no-mistakes evidence step collects paths, summarizes each |
| `risk_ref` | no-mistakes force-push decision + push step classifies external writes |
| `handoff_ref` | captain merge (GitHub audit log) or `axi respond` (run database) |

### 2.3 When the Manifest Is Written

- **Ship tasks (no-mistakes mode):** The no-mistakes pipeline is the manifest
  assembler. Each step appends its results. The final manifest is the run
  record in `NM_HOME` plus the evidence on disk.
- **Ship tasks (direct-PR mode):** The crewmate runs `npm test` (or equivalent)
  and records the output. The PR itself serves as the diff artifact. No
  pipeline run manifest exists; the proof bundle is the PR + test output +
  captain merge.
- **Ship tasks (local-only mode):** The crewmate records test output.
  Firstmate reviews the diff with `fm-review-diff.sh`. Captain approves.
  Firstmate merges with `fm-merge-local.sh`. The proof bundle is the diff +
  test output + merge commit.
- **Scout tasks:** The report IS the manifest. It must cite sources.
- **Infrastructure tasks:** `jw-status validate` output is the manifest.
- **Decision tasks:** The captain's approval (chat or `axi respond`) is the
  manifest.
- **Cleanup tasks:** Before/after evidence (in commit message or report) is the
  manifest.

---

## 3. Verification Flow

How the captain (or firstmate acting for the captain) verifies each type of
work. The verification step is **gated** -- a task cannot be marked "done"
until verification passes.

### 3.1 Code Change Verification

```
Crewmate reports "done"
        │
        ▼
[no-mistakes mode]                [direct-PR mode]         [local-only mode]
        │                              │                         │
        ▼                              ▼                         ▼
no-mistakes pipeline runs       Crewmate pushes +         Crewmate stops at
(review, test, lint,            opens PR.                 "done: ready in branch
 push, PR, CI).                 Captain reviews PR        fm/<id>".
        │                       diff and test output.             │
        ▼                              │                         ▼
Captain reviews:                       ▼                 Firstmate runs
- PR diff                      Captain merges or         fm-review-diff.sh <id>.
- Pipeline findings            requests changes.                │
- CI status                            │                         ▼
- Evidence artifacts                  ▼                 Captain reviews diff.
        │                      Task done (merged).              │
        ▼                                                      ▼
Captain merges or                                       Captain approves.
requests changes.                                       Firstmate runs
        │                                               fm-merge-local.sh <id>.
        ▼                                                      │
Task done (merged).                                           ▼
                                                    Task done (merged to
                                                    local main).
```

**Verification checklist (no-mistakes mode):**
- [ ] `git diff base...HEAD` shows only intended changes
- [ ] `go test -race ./...` (or equivalent) passes -- zero failures
- [ ] `go vet ./...` (or equivalent) clean
- [ ] Review findings: all `error` and `warning` resolved; `info` accepted or fixed
- [ ] CI: all checks green on the PR
- [ ] PR description is coherent, links to the task
- [ ] Evidence artifacts exist and are readable

**Failure modes:**
- Red CI: do not merge. Steer the crewmate to fix.
- Review findings parked at `ask-user`: captain must respond via `axi respond`
  or firstmate resolves under yolo.
- Force-push refused: an out-of-band commit landed on the branch. Investigate
  before proceeding.
- Evidence missing: the test step produced no output. Check the run log.

### 3.2 Investigation Verification

```
Crewmate reports "done"
        │
        ▼
Firstmate reads data/<id>/report.md
        │
        ▼
Firstmate checks:
- Report exists and is non-empty
- Claims cite specific files, line numbers, or command output
- If bug investigation: reproduction steps are concrete
        │
        ▼
Firstmate relays findings to captain (chat for simple, lavish-axi for complex)
        │
        ▼
Captain reads and confirms:
- "looks good" or equivalent
- OR: follow-up questions that become a new task
        │
        ▼
Firstmate runs fm-teardown.sh <id>
(scout worktree is scratch -- teardown allows it once report exists)
        │
        ▼
Task done. Report survives at data/<id>/report.md.
```

**Verification checklist:**
- [ ] `data/<id>/report.md` exists and has substantive content (not just "done")
- [ ] Report cites at least one concrete source (file path + line number, command output, benchmark result)
- [ ] If the task was "reproduce bug X": the report includes explicit steps that produce the bug
- [ ] Captain has acknowledged the findings

**Failure modes:**
- Report is empty or vague ("investigated and it looks fine"): reject. Steer
  crewmate to add concrete citations.
- Report cites nothing: reject. A scout report without sources is a claim, not
  an investigation.
- Captain disagrees with findings: promote to a ship task with the corrected
  analysis, or spawn a new scout with tighter scope.

### 3.3 Infrastructure Verification

```
Crewmate reports "done"
        │
        ▼
Firstmate (or captain directly) runs:
  jw-status validate
        │
        ▼
For each service the task touched:
  lsof -i :PORT           # is the port bound?
  tail -20 /tmp/<svc>.log # any crash loops?
        │
        ▼
If jw-status validate passes and all services healthy:
  Task done.
Else:
  Steer crewmate to fix, or investigate.
```

**Verification checklist:**
- [ ] `jw-status validate` exits 0
- [ ] Every expected port is bound (check against ARCHITECTURE.md service table)
- [ ] Log tail for each affected service shows clean startup (no fatal errors, no crash loops)
- [ ] Config changes are committed and pushed (if in a tracked repo)
- [ ] LaunchAgents: `launchctl list | grep <label>` shows the service

**Failure modes:**
- `jw-status validate` fails: the service is not running or not healthy.
- Port not bound: the service crashed or didn't start.
- Log shows crash loop: the change introduced a runtime error.
- Config not committed: the change is ephemeral and will be lost on reboot.

### 3.4 Decision Verification

```
Crewmate (or pipeline gate) reports "needs-decision"
        │
        ▼
Firstmate relays decision context to captain:
- What is being decided
- The options (if multiple)
- The recommendation (if firstmate has one)
        │
        ▼
Captain responds:
- "yes" / "approved" / "merge it" (explicit approval)
- OR: picks a specific option
- OR: for no-mistakes ask-user findings:
    no-mistakes axi respond --run <id> --finding <n> --action <action>
        │
        ▼
Decision recorded in:
- Chat (for verbal decisions)
- no-mistakes run database (for pipeline gate responses)
- GitHub PR audit log (for merges)
        │
        ▼
Task proceeds or closes based on decision.
```

**Verification checklist:**
- [ ] Captain's approval is explicit (not "maybe", not silence)
- [ ] The approval is recorded in at least one durable location
- [ ] For pipeline gates: `axi respond` was called with a valid action
- [ ] The run resumed after the decision (check `axi status` -- run is no longer parked)

**Failure modes:**
- Silent approval (captain said nothing and firstmate assumed): do not proceed.
  Firstmate must get explicit word.
- Ambiguous approval ("sure, I guess"): ask for confirmation on
  destructive/irreversible decisions.
- Pipeline gate timeout: if captain doesn't respond, the run stays parked.
  Firstmate should surface this on heartbeats.

### 3.5 Deletion / Cleanup Verification

```
Crewmate reports "done"
        │
        ▼
Firstmate checks:
- git diff --stat shows deletions (and only deletions)
- If code deleted: grep for remaining imports/references
- If service deleted: lsof -i :PORT confirms port is free
- If file deleted: ls confirms path is gone
        │
        ▼
Captain reviews the diff (for code) or before/after (for files)
        │
        ▼
Captain approves merge (no-mistakes/direct-PR) or local merge (local-only)
        │
        ▼
Task done.
```

**Verification checklist:**
- [ ] Git diff shows only intended deletions (no accidental file removal)
- [ ] `grep -r <deleted_symbol> <project>` returns no remaining references (or only intentional ones)
- [ ] If a service was removed: port is free, plist is unloaded, process is gone
- [ ] If files were removed: `ls <path>` confirms they are gone
- [ ] `du -sh <target>` before and after confirms space was reclaimed (large deletions)

---

## 4. Integration with no-mistakes

no-mistakes is the **Verifier** in the Trinity. It is the enforcement layer
that makes the proof contract machine-checkable.

### 4.1 Pipeline as Proof Assembler

Each no-mistakes pipeline step contributes to the proof bundle:

| Step | Proof Contribution |
|---|---|
| **Review** | Findings JSON: severity, location, description. Resolved findings = proof of review. |
| **Test** | Command output, exit code, evidence artifacts on disk. |
| **Lint** | `go vet` / `gofmt -l` output. Clean = proof of well-formedness. |
| **Push** | Force-push decision log (lease-guarded, never clobbers unseen commits). |
| **PR** | PR URL, PR summary (risk level, change description). |
| **CI** | CI check statuses (all green = proof of remote validation). |

### 4.2 Gate Responses as Decision Proof

When a step produces `ask-user` findings, the run parks at an `awaiting_approval`
or `fix_review` gate. The captain's response via `no-mistakes axi respond` is
recorded in the run database. This is the machine-verifiable proof that a
human reviewed and approved the finding.

The `awaiting_agent: parked <duration>` line in `axi status` is the
**observability signal** -- it tells firstmate the run is waiting. Firstmate
must not let a run sit parked indefinitely; the heartbeat backstop surfaces
parked runs.

### 4.3 Evidence Storage

Two modes, controlled by `evidence.store_in_repo` in `.no-mistakes.yaml`:

- **Default (opt-out):** Evidence lives in `$TMPDIR/no-mistakes-evidence/<run-id>/`.
  Temporary. Lost on reboot. Good for CI and local dev where the run record is
  the permanent artifact.
- **Opt-in:** Evidence lives in `.no-mistakes/evidence/<branch-slug>/` inside
  the worktree. Committed and pushed. Renders on the PR. Good for teams that
  want test output archived with the code.

The `evidence.go` safety constraints:
- Configured directory must be relative and stay inside the worktree
- Symlinks in the evidence path cause fallback to temp dir (no writing outside the worktree)
- Unsafe branch names (traversal, special chars) are sanitized to safe path segments

### 4.4 Regression Catching

The pipeline catches regressions at multiple layers:

1. **Test step:** Runs the project's test command. Any non-zero exit is a
   finding. In fix mode, the agent fixes failures and re-runs.
2. **Lint step:** Runs `go vet` (or equivalent). Any output is a finding.
3. **Review step:** Agent reviews the diff for correctness bugs and
   simplification opportunities. Findings are severity-graded.
4. **CI step:** Monitors GitHub Checks. Any red check is surfaced. The agent
   can auto-fix failing checks.
5. **Force-push safety:** The push step refuses to clobber commits that landed
   on the branch since the run started. This prevents the agent from
   accidentally discarding a human's out-of-band fix.

The captain's merge is the final regression gate: if the diff, test output,
and CI status look wrong, the captain does not merge.

### 4.5 What no-mistakes Does NOT Verify

no-mistakes validates code quality and regression freedom. It does NOT verify:
- Whether the change actually solves the problem described in the brief
- Whether the approach is architecturally sound (review step catches patterns, not intent)
- Whether the change is the right thing to build

These are captain judgments, made during PR review or investigation report
review. The pipeline proves the change is well-formed and non-breaking; the
captain proves it is correct.

---

## 5. Integration with tuxedo (todo.txt)

tuxedo-axi is the AI wrapper for tuxedo, which manages `todo.txt`. Task
completion is tracked through `tasks-axi` commands (firstmate's backlog
backend) or through direct `tuxedo-axi` calls.

### 5.1 Task Completion Recording

When a task's proof bundle is complete and the captain has approved, firstmate
records the completion with a proof reference:

**PR-based ship tasks:**
```sh
tasks-axi done <id> --pr "https://github.com/jwalinshah/jw-ui/pull/3"
```

**Scout tasks:**
```sh
tasks-axi done <id> --report "data/<id>/report.md"
```

**Local-only ship tasks:**
```sh
tasks-axi done <id> --note "local main"
```

**Infrastructure tasks:**
```sh
tasks-axi done <id> --note "jw-status validate passed, all services healthy"
```

### 5.2 Proof References in todo.txt

The `--pr`, `--report`, and `--note` flags become part of the done entry in
`data/backlog.md`. The entry is the **proof pointer** -- it tells the captain
where to find the evidence without restating it.

Example backlog entry after completion:
```markdown
## Done
- [x] jw-ui-terminal - xterm.js terminal embedded in jw-ui - https://github.com/jwalinshah/jw-ui/pull/3 (merged 2026-07-03)
```

The PR URL is the proof. Anyone can follow it to see the diff, CI status,
review comments, and merge record.

### 5.3 tuxedo-axi Review as Pre-Flight Verification

Before dispatching a task, `tuxedo-axi review` can be run to check the todo.txt
for stale items, missing priorities, or dependency chain breaks. This is a
lightweight pre-flight check, not a replacement for the full verification flow.

---

## 6. Captain's Verification Checklist (Per Task)

This is the checklist the captain uses when firstmate reports a task ready
for review. It is the same for every task and must be satisfied before the
captain says "merge it" or "done."

### For every task:
- [ ] The brief described what was asked. Does the outcome match?
- [ ] The proof bundle exists and is complete for the task category (see Section 1).
- [ ] The agent did not touch files outside its brief's scope.
- [ ] The agent did not force-push over someone else's work.
- [ ] The agent did not commit secrets, debug prints, or commented-out code.

### Additional for code changes:
- [ ] Diff is clean and intentional.
- [ ] Tests pass (local + CI).
- [ ] Lint/vet clean.
- [ ] Pipeline findings resolved.
- [ ] PR description is coherent.

### Additional for investigations:
- [ ] Report is substantive and cites sources.
- [ ] Reproduction steps work (if applicable).

### Additional for infrastructure:
- [ ] `jw-status validate` passes.
- [ ] Services are running and logs are clean.

### Additional for deletions:
- [ ] Only intended things were removed.
- [ ] No orphaned references remain.

### Additional for decisions:
- [ ] Captain's approval is explicit and recorded.

---

## 7. Relationship to the Trinity

```
                  Thinker                Worker              Verifier
              (firstmate)           (crewmate)          (no-mistakes)
                   │                     │                     │
                   │  1. Write brief     │                     │
                   │────────────────────>│                     │
                   │                     │                     │
                   │  2. Do the work     │                     │
                   │                     │  3. Run pipeline    │
                   │                     │─────────────────── >│
                   │                     │                     │
                   │                     │  4. Proof bundle    │
                   │                     │<─────────────────── │
                   │                     │                     │
                   │  5. Report "done"   │                     │
                   │<────────────────────│                     │
                   │                     │                     │
                Evaluate                                           │
              (captain)                                            │
                   │                                               │
                   │  6. Verify proof bundle                       │
                   │  7. Approve or request changes                │
                   │  8. Merge (or close for non-code tasks)       │
                   │                                               │
                   └──> Loop: next task                            │
```

The proof bundle is what makes the Evaluate step possible. Without it, the
captain is approving on faith. With it, the captain is approving on evidence.

---

## 8. Implementation Notes

### What exists today:
- no-mistakes pipeline produces review findings, test evidence, lint output,
  push decisions, PR URLs, and CI status. This covers the Verifier column.
- firstmate task lifecycle produces briefs, spawns crewmates, reads reports,
  and records completions. This covers the Thinker and Evaluate columns.
- firstmate's `fm-crew-state.sh` reconciles pipeline run state with crewmate
  status. This is the bridge between Worker and Verifier.
- `evidence.go` stores test artifacts with safety constraints.
- The force-push safety system prevents the most dangerous class of agent
  mistake (clobbering unseen commits).

### What gaps exist today:
- **No unified manifest assembly.** The pipeline produces evidence but does not
  compile it into a single manifest JSON. Each artifact lives in its own
  location (run database, temp dir, GitHub). A `no-mistakes axi manifest --run <id>`
  command that assembles the manifest from existing records would close this gap.
- **No scout verification enforcement.** Firstmate reads the report but there
  is no machine check that the report is substantive. A crewmate could write
  "done" to the report and firstmate would accept it. A minimum-length check or
  a "must cite at least one file path" regex would help.
- **No infrastructure verification automation.** `jw-status validate` is
  referenced as a concept but may not exist as a command. Until it does,
  infrastructure verification is manual (`lsof`, `tail`, `launchctl list`).
- **No cross-task proof index.** Each task's proof lives in its own silo (PR,
  report, run record). There is no way to ask "show me all proof for the last
  10 tasks." The backlog's Done section with PR URLs is the closest thing.


### Next steps (not part of this contract -- implementation decisions):
1. Add `no-mistakes axi manifest --run <id>` that assembles the proof bundle
   into a single JSON output.
2. Add scout report validation in firstmate: refuse to close a scout task if
   the report is under N characters or contains no file paths.
3. Build `jw-status validate` as a command that checks every service in
   ARCHITECTURE.md's service table.
