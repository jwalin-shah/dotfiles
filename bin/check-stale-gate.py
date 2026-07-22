#!/usr/bin/env python3
"""PreToolUse hook (Write|Edit|Bash): gates on CRDM (check-stale) health for
whichever ~/projects/<name> the tool call actually targets.

Scoped per-project, not machine-wide — a broken dependency in a project
you're not touching must not block unrelated work. Results are cached per
project for TTL seconds so check-stale's network/port probes don't re-run
on every single tool call in a session.

Exit 2 to deny (exit 1 fails open for both Claude Code and Cursor — see
enforce-bridge-workflow.sh fix, same session). Exit 0 to allow.
"""
import json
import os
import subprocess
import sys
import time

PROJECTS_DIR = os.path.expanduser("~/projects")
CACHE_FILE = os.path.expanduser("~/.claude/.check-stale-cache.json")
CHECK_STALE = os.path.expanduser("~/projects/dotfiles/bin/check-stale")
TTL = 300  # seconds


def resolve_project(target: str) -> str | None:
    target = os.path.abspath(target)
    prefix = PROJECTS_DIR + os.sep
    if not target.startswith(prefix):
        return None
    rest = target[len(prefix):]
    return rest.split(os.sep)[0] if rest else None


def main() -> None:
    raw = sys.stdin.read()
    try:
        data = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        data = {}

    tool_input = data.get("tool_input", {})
    target = tool_input.get("file_path") or tool_input.get("path") or os.getcwd()

    project = resolve_project(target)
    if not project:
        sys.exit(0)  # not inside ~/projects — nothing to gate

    deps_file = os.path.join(PROJECTS_DIR, project, "wayfinder", "deps.json")
    if not os.path.isfile(deps_file):
        sys.exit(0)  # project has no CRDM manifest — nothing to check

    cache: dict = {}
    if os.path.isfile(CACHE_FILE):
        try:
            with open(CACHE_FILE) as f:
                cache = json.load(f)
        except Exception:
            cache = {}

    entry = cache.get(project)
    now = time.time()
    if not entry or (now - entry.get("checked_at", 0)) > TTL:
        try:
            proc = subprocess.run(
                [CHECK_STALE, project], capture_output=True, text=True, timeout=15
            )
            status = "pass" if proc.returncode == 0 else "fail"
            lines = [l for l in proc.stdout.splitlines() if l.strip()]
            detail = "\n".join(lines[-6:])
        except Exception as e:
            # The checker itself failed to run (binary missing/moved, timeout).
            # That's an infra problem with the checker, not a proven dependency
            # failure — fail OPEN here specifically, so a broken check-stale
            # install doesn't block all work machine-wide. Genuine check-stale
            # findings (returncode != 0) still fail closed below.
            status = "pass"
            detail = f"check-stale invocation error (not a dependency finding): {e}"
        entry = {"status": status, "detail": detail, "checked_at": now}
        cache[project] = entry
        os.makedirs(os.path.dirname(CACHE_FILE), exist_ok=True)
        with open(CACHE_FILE, "w") as f:
            json.dump(cache, f, indent=2)

    if entry["status"] == "fail":
        reason = (
            f"check-stale: {project} has unsatisfied required dependencies:\n"
            f"{entry['detail']}\n"
            f"(cached {int(now - entry['checked_at'])}s ago, TTL {TTL}s — "
            f"fix the dependency, or the next check after TTL will re-verify)"
        )
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": reason,
            }
        }))
        sys.exit(2)

    sys.exit(0)


if __name__ == "__main__":
    main()
