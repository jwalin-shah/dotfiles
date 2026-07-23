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
import json, os, re, sys
from pathlib import Path

HOME = Path(os.environ.get("HOME", "")).expanduser()
PROJECTS = (HOME / "projects").resolve()
TASK_MARKERS = ("ORBIT_TASK.md", ".bridge-task")
ALWAYS_ALLOWED_PREFIXES = (
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
            "permission": "deny",
            "decision": "deny",
            "user_message": msg,
            "agent_message": msg,
            "reason": msg,
        },
        2,
    )


def allow() -> None:
    emit({"permission": "allow", "decision": "allow"}, 0)


def load() -> dict:
    raw = os.environ.get("INPUT", "")
    if not raw.strip():
        return {}
    try:
        return json.loads(raw)
    except Exception:
        return {}


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


def has_task(project: Path) -> bool:
    return any((project / m).is_file() for m in TASK_MARKERS)


def always_allowed(project: Path, abs_file: Path) -> bool:
    try:
        rel = str(abs_file.resolve().relative_to(project.resolve()))
    except ValueError:
        return False
    return any(rel == p or rel.startswith(p) for p in ALWAYS_ALLOWED_PREFIXES)


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
    cleaned = re.sub(r"&>?/dev/null", "", cleaned)
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


def main() -> None:
    d = load()
    file_path = extract_file(d)
    cmd, cwd = extract_shell(d)

    if file_path:
        abs_file = Path(file_path).expanduser()
        project = project_for_path(abs_file)
        if project is None:
            allow()
        if always_allowed(project, abs_file):
            allow()
        if has_task(project):
            allow()
        try:
            rel = str(abs_file.resolve().relative_to(project.resolve()))
        except Exception:
            rel = abs_file.name
        deny(
            f"Direct edits in {project} require ORBIT_TASK.md or .bridge-task "
            f"(or bridge spawn). Blocked: {rel}"
        )

    if cmd:
        if not is_mutation(cmd):
            allow()
        touched = projects_touched_by_shell(cmd, cwd)
        if not touched and cwd:
            p = project_for_path(Path(cwd))
            if p is not None:
                touched.add(p)
        if not touched:
            allow()
        blocked = [p for p in sorted(touched) if not has_task(p)]
        if not blocked:
            allow()
        names = ", ".join(p.name for p in blocked)
        deny(
            f"Shell mutation under ~/projects/{{{names}}} requires ORBIT_TASK.md "
            f"or .bridge-task (no Write bypass via shell). Command: {cmd[:160]}"
        )

    allow()


if __name__ == "__main__":
    main()
PY
