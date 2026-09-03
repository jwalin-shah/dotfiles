#!/usr/bin/env bash
# enforce-bridge-workflow.sh — machine-wide mutation gate for all agent harnesses.
#
# Policy (one script, every harness):
#   Any mutation under ~/projects/<repo> requires ORBIT_TASK.md or .bridge-task
#   in that repo. Covers file edits AND shell write-forms (no heredoc bypass).
#
# Wired from:
#   Cursor  — preToolUse Write|Edit|Delete|TabWrite|Shell
#   Claude  — PreToolUse Edit|Write|Bash
#   Codex   — pre-edit (file); shell still a Codex gap (see HOOKS.md)
#   Gemini/agy — PreToolUse edit_file via antigravity wrapper
#
# Block contract: print JSON deny + exit 2. Other nonzero = harness-dependent.
set -u
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"
export INPUT
INPUT=$(cat || true)

exec python3 - <<'PY'
import json, os, re, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path

HOME = Path(os.environ.get("HOME", "")).expanduser()
PROJECTS = (HOME / "projects").resolve()
TASK_MARKERS = ("ORBIT_TASK.md", ".bridge-task")
PROTOTYPE_ROOTS = (".scratch", ".prototype")
ALWAYS_ALLOWED_PREFIXES = (
    # Repo-root task markers — chicken-egg bootstrap (Write/Edit only these).
    "ORBIT_TASK.md",
    ".bridge-task",
    ".claude/",
    "docs/agents/",
    "wayfinder/",
    "CLAUDE.md",
    "AGENTS.md",
    ".gitignore",
    "go.mod",
    "go.sum",
    "README.md",
    "OPERATING_MODEL.md",
    "bin/enforce-bridge-workflow.sh",
    "bin/enforce-bridge-workflow-antigravity.sh",
    "bin/prove-bridge-workflow-gate.sh",
    "home/.cursor/hooks.json",
    "home/.claude/settings.json",
    "home/.codex/hooks.json",
    "home/.gemini/config/hooks.json",
    "docs/HOOKS.md",
)

MUTATION_RE = re.compile(
    r"""(?x)
    (?:^|[\s;|&])(?:tee|rm|mv|cp|mkdir|touch|chmod|chown|install|ln|truncate|dd)\b
    |(?:^|[\s;|&])sed\s+[^\n]*?-i
    |(?:^|[\s;|&])perl\s+[^\n]*?-i
    |(?:^|[\s;|&])git\s+(?:add|commit|push|checkout|reset|rebase|merge|cherry-pick|stash\s+push)\b
    |(?:^|[\s;|&])(?:npm|pnpm|yarn|pip3?|uv|cargo)\s+(?:install|add)\b
    |(?:^|[\s;|&])go\s+(?:install|get|mod\s+tidy)\b
    """
)


def emit(obj: dict, code: int) -> None:
    print(json.dumps(obj))
    raise SystemExit(code)


def deny(msg: str) -> None:
    print(f"[bridge-workflow] BLOCKED: {msg}", file=sys.stderr)
    emit(
        {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": msg,
            }
        },
        2,
    )


def allow() -> None:
    # Claude Code treats empty stdout as an allow/no-op.  Do not emit the
    # legacy root-level permission/decision fields: current Claude rejects
    # them as an invalid PreToolUse output object.
    raise SystemExit(0)


def load() -> dict:
    raw = os.environ.get("INPUT", "")
    if not raw.strip():
        return {}
    try:
        value = json.loads(raw)
    except Exception:
        deny("hook input is not valid JSON; refusing to infer permission")
    if not isinstance(value, dict):
        deny("hook input must be a JSON object; refusing to infer permission")
    return value


def project_for_path(path: Path) -> Path | None:
    try:
        real = path.expanduser().resolve()
    except Exception:
        return None
    try:
        rel = real.relative_to(PROJECTS)
    except ValueError:
        return None
    if not rel.parts:
        return None
    return PROJECTS / rel.parts[0]


def git_value(path: Path, flag: str) -> Path | None:
    """Return one resolved git path without invoking a shell."""
    try:
        result = subprocess.run(
            ["git", "-C", str(path), "rev-parse", flag],
            check=True,
            capture_output=True,
            text=True,
        )
    except (OSError, subprocess.CalledProcessError):
        return None
    value = result.stdout.strip()
    if not value:
        return None
    candidate = Path(value)
    if not candidate.is_absolute():
        candidate = path / candidate
    try:
        return candidate.resolve()
    except OSError:
        return None


def checkout_scope(path: Path) -> tuple[Path, Path, bool] | None:
    """Return (checkout root, primary root, isolated) for a git path."""
    try:
        probe = path.expanduser()
        if probe.is_file():
            probe = probe.parent
        while not probe.exists() and probe != probe.parent:
            probe = probe.parent
        checkout = git_value(probe, "--show-toplevel")
        common = git_value(probe, "--git-common-dir")
    except OSError:
        return None
    if checkout is None or common is None or common.name != ".git":
        return None
    primary = common.parent
    if not primary.is_dir():
        return None
    # Only govern repositories whose primary checkout is inside the declared
    # project fleet. Other git repositories remain outside this policy.
    try:
        primary.relative_to(PROJECTS)
    except ValueError:
        return None
    return checkout, primary, checkout != primary


def has_task(checkout: Path) -> bool:
    return any((checkout / m).is_file() for m in TASK_MARKERS)


def always_allowed(checkout: Path, abs_file: Path) -> bool:
    try:
        rel = str(abs_file.resolve().relative_to(checkout.resolve()))
    except ValueError:
        return False
    return any(rel == p or rel.startswith(p) for p in ALWAYS_ALLOWED_PREFIXES)


def shell_only_always_allowed(cmd: str, checkout: Path) -> bool:
    """True when every project file path in cmd is always_allowed (narrow shell)."""
    proj = str(checkout.resolve())
    rels: list[str] = []
    for m in re.finditer(re.escape(proj) + r"/([^\s;'\"\\|<>]+)", cmd):
        rels.append(m.group(1).rstrip("/"))
    # cwd-relative bare markers (touch .bridge-task, > ORBIT_TASK.md)
    for name in TASK_MARKERS:
        if re.search(rf"(?:^|[\s;|&>])(?:\./)?{re.escape(name)}\b", cmd):
            rels.append(name)
    if not rels:
        return False
    return all(
        any(rel == p or rel.startswith(p) for p in ALWAYS_ALLOWED_PREFIXES)
        for rel in rels
    )


def workflow_metadata(d: dict) -> dict:
    """Read the explicit bridge_workflow contract without trusting free text."""
    for container in (d, d.get("tool_input"), d.get("toolInput")):
        if not isinstance(container, dict):
            continue
        for key in ("bridge_workflow", "work_scope"):
            value = container.get(key)
            if isinstance(value, dict):
                return value
    return {}


def parse_expiry(value: object) -> datetime | None:
    if not isinstance(value, str) or not value.strip():
        return None
    try:
        expiry = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None
    if expiry.tzinfo is None:
        return None
    return expiry.astimezone(timezone.utc)


def prototype_contract(d: dict, checkout: Path, target: Path) -> tuple[bool, str]:
    """Validate a disposable, bounded prototype exception."""
    scope = workflow_metadata(d)
    if scope.get("mode") != "prototype":
        return False, ""
    if not isinstance(scope.get("purpose"), str) or not scope["purpose"].strip():
        return False, "prototype requires a non-empty purpose"
    if scope.get("disposable") is not True:
        return False, "prototype requires disposable=true"
    if scope.get("deliverable") is True or scope.get("no_delivery") is False:
        return False, "prototype cannot be marked deliverable"
    expiry = parse_expiry(scope.get("expires_at"))
    if expiry is None or expiry <= datetime.now(timezone.utc):
        return False, "prototype requires a future timezone-aware expires_at"
    allowed = scope.get("allowed_paths")
    if not isinstance(allowed, list) or not allowed or not all(isinstance(p, str) for p in allowed):
        return False, "prototype requires a non-empty allowed_paths list"
    try:
        target_rel = target.resolve().relative_to(checkout.resolve())
    except ValueError:
        return False, "prototype target is outside the checkout"
    target_parts = target_rel.parts
    if not target_parts or target_parts[0] not in PROTOTYPE_ROOTS:
        return False, "prototype writes must stay under .scratch or .prototype"
    for raw in allowed:
        candidate = Path(raw)
        if candidate.is_absolute() or ".." in candidate.parts:
            return False, "prototype allowed_paths must be relative and traversal-free"
        allowed_path = (checkout / candidate).resolve()
        try:
            target.resolve().relative_to(allowed_path)
            return True, ""
        except ValueError:
            continue
    return False, "prototype target is outside allowed_paths"


def shell_targets(cmd: str, cwd: str | None) -> list[Path]:
    """Extract only obvious mutation targets; ambiguity is denied."""
    base = Path(cwd).expanduser() if cwd else Path.cwd()
    raw_targets: list[str] = []
    patterns = (
        r"(?:^|[\s;&|])(?:>>?\s*|tee\s+|touch\s+|rm\s+(?:-[^\s]+\s+)*)([^\s;&|<>]+)",
        r"(?:^|[\s;&|])(?:mv|cp|install)\s+(?:-[^\s]+\s+)*[^\s;&|]+\s+([^\s;&|]+)",
    )
    for pattern in patterns:
        raw_targets.extend(m.group(1) for m in re.finditer(pattern, cmd))
    return [Path(value).expanduser() if Path(value).expanduser().is_absolute()
            else base / value for value in raw_targets]


def extract_file(d: dict) -> str | None:
    ti = d.get("tool_input") or d.get("toolInput") or {}
    if isinstance(ti, dict):
        for key in ("file_path", "path", "target_file", "TargetFile"):
            v = ti.get(key)
            if isinstance(v, str) and v.strip():
                return v.strip()
    for key in ("file_path", "path"):
        v = d.get(key)
        if isinstance(v, str) and v.strip():
            return v.strip()
    return None


def extract_shell(d: dict) -> tuple[str | None, str | None]:
    ti = d.get("tool_input") or d.get("toolInput") or {}
    cmd = cwd = None
    if isinstance(ti, dict):
        cmd = ti.get("command") or ti.get("cmd")
        cwd = ti.get("working_directory") or ti.get("workdir") or ti.get("cwd")
    cmd = cmd or d.get("command") or d.get("cmd")
    cwd = cwd or d.get("working_directory") or d.get("cwd") or d.get("workdir")
    if not isinstance(cmd, str) or not cmd.strip():
        cmd = None
    else:
        cmd = cmd.strip()
    if not isinstance(cwd, str) or not cwd.strip():
        cwd = None
    else:
        cwd = cwd.strip()
    return cmd, cwd


def is_mutation(cmd: str) -> bool:
    cleaned = re.sub(r"\d*>&\d+", "", cmd)
    cleaned = re.sub(r"(?:\d*|&)>>?\s*/dev/null", "", cleaned)
    if re.search(r"(^|[^-=])>(?!&)", cleaned):
        return True
    if "<<" in cmd and re.search(r">>?\s*\S+", cmd):
        return True
    return bool(MUTATION_RE.search(cmd))


def projects_touched_by_shell(cmd: str, cwd: str | None) -> set[Path]:
    found: set[Path] = set()
    if cwd:
        p = project_for_path(Path(cwd))
        if p is not None:
            found.add(p)
    for m in re.finditer(r"(?:~|/Users/[^/\s]+)/projects/([A-Za-z0-9_.-]+)", cmd):
        found.add(PROJECTS / m.group(1))
    for m in re.finditer(r"(?<![A-Za-z0-9_.-])projects/([A-Za-z0-9_.-]+)", cmd):
        found.add(PROJECTS / m.group(1))
    return {p for p in found if p.is_dir()}


def checkouts_touched_by_shell(cmd: str, cwd: str | None) -> set[Path]:
    paths: list[Path] = []
    if cwd:
        paths.append(Path(cwd).expanduser())
    paths.extend(shell_targets(cmd, cwd))
    scopes: set[Path] = set()
    for path in paths:
        scope = checkout_scope(path)
        if scope is not None:
            scopes.add(scope[0])
    # Retain the old absolute-path recognizer for commands whose target is not
    # syntactically tied to a redirection (e.g. git -C ~/projects/repo ...).
    for project in projects_touched_by_shell(cmd, cwd):
        scope = checkout_scope(project)
        if scope is not None:
            scopes.add(scope[0])
    return scopes


def shell_target_for_checkout(checkout: Path, targets: list[Path]) -> Path:
    """Select a target belonging to this checkout; otherwise stay ambiguous."""
    for target in targets:
        scope = checkout_scope(target)
        if scope is not None and scope[0] == checkout:
            return target
    return checkout / "__ambiguous_shell_target__"


def deny_scope(d: dict, checkout: Path, primary: Path, target: Path) -> None:
    """Deny shared/markerless mutations, or malformed prototype exceptions."""
    prototype_ok, reason = prototype_contract(d, checkout, target)
    scope = workflow_metadata(d)
    if scope.get("mode") == "prototype":
        if prototype_ok:
            allow()
        deny(reason)
    if checkout == primary:
        deny(
            f"Mutations in shared primary checkout {primary} are denied; use a "
            "clean isolated git worktree. Declare bridge_workflow.mode=prototype "
            "only for a bounded disposable .scratch/.prototype experiment."
        )
    if not has_task(checkout):
        deny(
            f"Isolated checkout {checkout} requires ORBIT_TASK.md or .bridge-task "
            "before mutation (create the marker first)."
        )
    allow()


def main() -> None:
    d = load()
    file_path = extract_file(d)
    cmd, cwd = extract_shell(d)

    if file_path:
        abs_file = Path(file_path).expanduser()
        scope = checkout_scope(abs_file)
        if scope is None:
            allow()
        checkout, primary, _ = scope
        if always_allowed(checkout, abs_file):
            allow()
        deny_scope(d, checkout, primary, abs_file)

    if cmd:
        if not is_mutation(cmd):
            allow()
        touched = checkouts_touched_by_shell(cmd, cwd)
        if not touched and cwd:
            scope = checkout_scope(Path(cwd))
            if scope is not None:
                touched.add(scope[0])
        if not touched:
            allow()
        for checkout in sorted(touched):
            scope = checkout_scope(checkout)
            if scope is None:
                continue
            _, primary, _ = scope
            if shell_only_always_allowed(cmd, checkout):
                continue
            target = shell_target_for_checkout(checkout, shell_targets(cmd, cwd))
            deny_scope(d, checkout, primary, target)
        allow()

    allow()


if __name__ == "__main__":
    main()
PY
