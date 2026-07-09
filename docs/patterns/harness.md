# harness: Adapter-Based Workflow Runner

**Source**: `jwalin-shah/harness` (archived) -- `/tmp/audit-harness`

## Problem

Agent workflow runs produce evidence scattered across terminals, log files, git
history, and provider dashboards. There is no standardized way to: (a) describe
what a run was supposed to do, (b) capture what actually happened, and (c) make
that evidence machine-readable for downstream adapters.

## How It Works

Harness defines a **typed ref system** where every concern of an agent run is a
named, schema-constrained JSON object:

- `work_order_ref` -- who authorized this run
- `task_ref` -- which tracker task caused it
- `repo_ref` -- which repo and worktree
- `runner_ref` -- local, CI, or remote provider
- `command_ref` -- each explicit command executed (purpose, argv, exit code, stdout/stderr paths)
- `validation_ref` -- the validation gate result
- `evidence_ref` -- local artifact produced
- `risk_ref` -- external-write permission classification
- `context_pack` -- the bounded prompt packet compiled before the run
- `handoff_ref` -- whether the run has been handed off for review

These refs combine into a **run manifest** -- a single JSON file that is the
canonical record of one agent execution. Every ref is path-addressable,
hashable, and read-only by default. Mutations require explicit `--` commands.

The **TaskContract** is parsed from markdown (sections like `## Validation`,
`## Acceptance Criteria`, `## Owned Files`, `## Stop Conditions`) and compiles
into the context pack that an agent receives before starting work.

## Interface / Contract

```python
@dataclass(frozen=True)
class TaskContract:
    task: str | None              # e.g., "SYM-161"
    title: str | None
    validation: str | None        # e.g., "./scripts/check.sh"
    acceptance: list[str]         # bullet criteria
    owned_files: list[str]        # paths the agent may touch
    includes: list[str]           # required context files
    stop_conditions: list[str]    # when to stop
    handoff_requirements: list[str]

def parse_task_contract(path: Path) -> TaskContract:
    """Parse a markdown task brief into a structured contract."""
    ...
```

Run manifest (schema excerpt):
```json
{
  "schema_version": "1.0",
  "run_id": "run_20260511T000000Z_sym_161",
  "status": "succeeded",
  "work_order_ref": {"id": "...", "source": "phone_cockpit"},
  "task_ref": {"linear_key": "SYM-161"},
  "repo_ref": {"path": "...", "branch": "...", "head_sha": "...", "dirty": false},
  "commands": [{"purpose": "validation", "argv": ["./scripts/check.sh"], "exit_code": 0}],
  "validation_ref": {"status": "succeeded"},
  "risk_ref": {"external_write_allowed": false, "privacy_risk": "low"}
}
```

## Applying to jw-*

- **jw-sentry**: Every test run, benchmark, or deployment could produce a
  harness run manifest. The manifest becomes the audit trail for "did this
  change pass validation before it shipped?"
- **jw-agentd**: Worker agent runs launched by the orchestrator can emit
  harness manifests -- giving the orchestrator a machine-readable record of
  what each worker did, whether validation passed, and what evidence exists.
- **Any jw-* repo**: Adopting the TaskContract markdown format (with `##
  Validation`, `## Acceptance Criteria`, `## Stop Conditions` sections) makes
  work orders agent-parseable without a custom schema.
