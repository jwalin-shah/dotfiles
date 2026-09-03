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
import json, os, re, shlex, subprocess, sys
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

# Destructive git operations that can permanently lose content with no git
# backup at all (untracked worktree files, commits reachable from no
# remote). Checked unconditionally — independent of MUTATION_RE/is_mutation,
# since these can silently discard work invisibly to that heuristic, and
# independent of checkout ownership/task-marker policy, since the risk is
# the same regardless of who owns the checkout.
WORKTREE_REMOVE_RE = re.compile(
    r"(?:^|[\s;|&])git\s+(?:-C\s+(\S+)\s+)?worktree\s+remove\s+(?:--force|-f)?\s*([^\s;|&]+)?\s*(?:--force|-f)?"
)
BRANCH_DELETE_RE = re.compile(
    r"(?:^|[\s;|&])git\s+(?:-C\s+(\S+)\s+)?branch\s+(?:-D|(?:-d|--delete)\s+(?:--force|-f))\s+([^\s;|&]+)"
)
GIT_CLEAN_RE = re.compile(
    r"(?:^|[\s;|&])git\s+(?:-C\s+(\S+)\s+)?clean\s+((?:-[A-Za-z]+\s*|--\S+\s*)+)"
)
GIT_RESET_HARD_RE = re.compile(
    r"(?:^|[\s;|&])git\s+(?:-C\s+(\S+)\s+)?reset\s+(?:--hard)\b"
)
GIT_PUSH_FORCE_RE = re.compile(
    r"(?:^|[\s;|&])git\s+(?:-C\s+(\S+)\s+)?push\s+(?P<args>[^\n]*?--force(?!-with-lease)[^\n]*?)(?:$|[;|&])"
)
# rm is tokenized with shlex rather than matched by regex (see check_rm_recursive)
# — flag-clustering (-rf vs -fr vs -r -f) is too varied to parse reliably as text.
RM_RE = re.compile(r"(?:^|[\s;|&])rm\s+([^;|&\n]+)")

DESTRUCTIVE_OVERRIDE_LOG = HOME / ".dotfiles-state" / "destructive-overrides.log"


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


def any_checkout_toplevel(path: Path) -> Path | None:
    """Like checkout_scope, but with no PROJECTS-tree restriction — used by
    the destructive-action risk checks (rm -r, git clean, etc.), which must
    protect real content regardless of whether the repo happens to be under
    the declared project fleet. checkout_scope's PROJECTS filter exists for
    the ownership/task-marker policy specifically, not for this."""
    try:
        probe = path.expanduser()
        if probe.is_file():
            probe = probe.parent
        while not probe.exists() and probe != probe.parent:
            probe = probe.parent
        return git_value(probe, "--show-toplevel")
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


def dirty_status(path: Path) -> str | None:
    """Return a description of uncommitted/untracked content, or None if clean."""
    try:
        result = subprocess.run(
            ["git", "-C", str(path), "status", "--porcelain"],
            check=True, capture_output=True, text=True,
        )
    except (OSError, subprocess.CalledProcessError):
        return "unable to check git status (not a git checkout?)"
    lines = [line for line in result.stdout.splitlines() if line.strip()]
    if not lines:
        return None
    sample = ", ".join(line.strip() for line in lines[:5])
    more = f" and {len(lines) - 5} more" if len(lines) > 5 else ""
    return f"{len(lines)} uncommitted/untracked path(s): {sample}{more}"


def unpushed_reason(path: Path, ref: str = "HEAD") -> str | None:
    """Return a reason string if ref is not reachable from any remote-tracking
    branch, or None if it is (i.e., a backstop already exists somewhere)."""
    try:
        result = subprocess.run(
            ["git", "-C", str(path), "branch", "-r", "--contains", ref],
            check=True, capture_output=True, text=True,
        )
    except (OSError, subprocess.CalledProcessError):
        return f"unable to check remote-tracking reachability for {ref}"
    if result.stdout.strip():
        return None
    return f"{ref} is not reachable from any remote-tracking branch (not pushed anywhere)"


def resolve_repo_relative(raw: str | None, cwd: str | None) -> Path:
    base = Path(cwd).expanduser() if cwd else Path.cwd()
    if not raw:
        return base
    candidate = Path(raw).expanduser()
    return candidate if candidate.is_absolute() else base / candidate


def destructive_override(d: dict) -> tuple[bool, str]:
    """Validate a structured, evidenced escape hatch for a destructive check.
    Unlike a bare --force-style flag, this requires two real, non-empty
    justifications and is not a silent bypass: every accepted override is
    appended to a durable, inspectable log (DESTRUCTIVE_OVERRIDE_LOG) before
    the caller is allowed to proceed. An override with a missing or empty
    field is denied with the specific gap named, same as prototype_contract."""
    scope = workflow_metadata(d)
    if scope.get("mode") != "destructive-override":
        return False, ""
    reason = scope.get("reason")
    verified_how = scope.get("verified_how")
    if not isinstance(reason, str) or not reason.strip():
        return False, "destructive-override requires a non-empty reason (why this must proceed anyway)"
    if not isinstance(verified_how, str) or not verified_how.strip():
        return False, "destructive-override requires a non-empty verified_how (what concretely confirms this is safe — e.g. 'content confirmed merged as PR #83', not just an assertion)"
    return True, f"{reason.strip()} | verified_how: {verified_how.strip()}"


def log_override(cmd: str, cwd: str | None, evidence: str) -> None:
    """Best-effort durable audit trail. A logging failure must never itself
    block or crash an otherwise-valid override — that would make the audit
    mechanism a second, undocumented way to deny legitimate work."""
    try:
        DESTRUCTIVE_OVERRIDE_LOG.parent.mkdir(parents=True, exist_ok=True)
        with DESTRUCTIVE_OVERRIDE_LOG.open("a") as f:
            f.write(json.dumps({
                "at": datetime.now(timezone.utc).isoformat(),
                "cwd": cwd,
                "command": cmd,
                "evidence": evidence,
            }) + "\n")
    except OSError:
        pass


def dirty_status_scoped(checkout: Path, target: Path) -> str | None:
    """Like dirty_status, but scoped to one path within checkout — used for
    rm -r, where the target is a subpath, not the whole checkout."""
    try:
        result = subprocess.run(
            ["git", "-C", str(checkout), "status", "--porcelain", "--", str(target)],
            check=True, capture_output=True, text=True,
        )
    except (OSError, subprocess.CalledProcessError):
        return None
    lines = [line for line in result.stdout.splitlines() if line.strip()]
    if not lines:
        return None
    sample = ", ".join(line.strip() for line in lines[:5])
    more = f" and {len(lines) - 5} more" if len(lines) > 5 else ""
    return f"{len(lines)} uncommitted/untracked path(s) with no git backup: {sample}{more}"


def check_rm_recursive(cmd: str, cwd: str | None) -> None:
    """Fail closed on `rm -r` (any flag order/clustering) removing a path
    that has real, unrecoverable git content. Scoped narrowly: a target
    outside any git checkout is not checked at all (rm -rf on scratch/tmp/
    cache dirs outside version control is extremely common and legitimate —
    over-blocking it would recreate the exact friction problem this hook was
    already fixed for once today). A target that IS inside a checkout but is
    gitignored or already fully committed is also not checked — `git status
    --porcelain` shows neither, which is correct: that content has a real
    backup (git history) or was never meant to have one (ignored)."""
    for m in RM_RE.finditer(cmd):
        try:
            tokens = shlex.split(m.group(1))
        except ValueError:
            continue  # unbalanced quoting; not this hook's to parse further
        flags = [t for t in tokens if t.startswith("-") and t != "--"]
        targets = [t for t in tokens if not t.startswith("-")]
        recursive = any(
            f in ("-r", "-R", "--recursive")
            or (not f.startswith("--") and ("r" in f or "R" in f))
            for f in flags
        )
        if not recursive or not targets:
            continue
        for raw_target in targets:
            target = resolve_repo_relative(raw_target, cwd)
            if not target.exists():
                continue
            checkout = any_checkout_toplevel(target)
            if checkout is None:
                continue
            dirty = dirty_status_scoped(checkout, target)
            if dirty:
                deny(
                    f"rm -r denied: {target} has {dirty}. "
                    "Commit and push first, then retry."
                )


def check_git_clean(cmd: str, cwd: str | None) -> None:
    """Fail closed on `git clean -f...` that would actually remove
    untracked files — previewed via a real `git clean -n` dry run against
    the actual repo, not guessed from the command text."""
    for m in GIT_CLEAN_RE.finditer(cmd):
        repo_flag, flag_text = m.group(1), m.group(2) or ""
        if "-n" in flag_text.split() or "--dry-run" in flag_text:
            continue  # already a dry run; nothing will actually be removed
        repo_path = resolve_repo_relative(repo_flag, cwd)
        dry_flags = ["-n", "-fd"] + (["-x"] if "x" in flag_text else [])
        try:
            result = subprocess.run(
                ["git", "-C", str(repo_path), "clean"] + dry_flags,
                capture_output=True, text=True,
            )
        except OSError:
            continue
        lines = [line for line in result.stdout.splitlines() if line.strip()]
        if lines:
            sample = ", ".join(line.strip() for line in lines[:5])
            more = f" and {len(lines) - 5} more" if len(lines) > 5 else ""
            deny(
                f"git clean denied: would remove {len(lines)} untracked path(s) "
                f"in {repo_path} with no git backup: {sample}{more}. Review with "
                "`git clean -n` first, then retry."
            )


def check_git_reset_hard(cmd: str, cwd: str | None) -> None:
    """Fail closed on `git reset --hard` discarding real uncommitted work."""
    for m in GIT_RESET_HARD_RE.finditer(cmd):
        repo_flag = m.group(1)
        repo_path = resolve_repo_relative(repo_flag, cwd)
        dirty = dirty_status(repo_path)
        if dirty:
            deny(
                f"git reset --hard denied: {repo_path} has {dirty}. "
                "This permanently discards uncommitted changes. Commit or "
                "stash first, then retry."
            )


def check_git_push_force(cmd: str, cwd: str | None) -> None:
    """Fail closed on `git push --force` (not --force-with-lease, which
    already fails safely if the remote moved) that would discard commits
    currently on the remote and not reachable from the new local tip."""
    for m in GIT_PUSH_FORCE_RE.finditer(cmd):
        repo_flag, args = m.group(1), m.group("args")
        repo_path = resolve_repo_relative(repo_flag, cwd)
        tokens = [t for t in args.split() if not t.startswith("-")]
        if not tokens:
            continue
        remote = tokens[0]
        refspec = tokens[1] if len(tokens) > 1 else None
        if refspec and ":" in refspec:
            local_ref, remote_ref = refspec.split(":", 1)
        elif refspec:
            local_ref = remote_ref = refspec
        else:
            try:
                branch_result = subprocess.run(
                    ["git", "-C", str(repo_path), "rev-parse", "--abbrev-ref", "HEAD"],
                    capture_output=True, text=True,
                )
            except OSError:
                continue
            local_ref = remote_ref = branch_result.stdout.strip()
        if not local_ref or not remote_ref:
            continue
        try:
            remote_sha_result = subprocess.run(
                ["git", "-C", str(repo_path), "ls-remote", remote, remote_ref],
                capture_output=True, text=True,
            )
        except OSError:
            continue
        remote_line = remote_sha_result.stdout.split()
        if not remote_line:
            continue  # remote ref does not exist yet; nothing to lose
        remote_sha = remote_line[0]
        try:
            ancestor_check = subprocess.run(
                ["git", "-C", str(repo_path), "merge-base", "--is-ancestor", remote_sha, local_ref],
                capture_output=True, text=True,
            )
        except OSError:
            continue
        if ancestor_check.returncode != 0:
            deny(
                f"git push --force denied: {remote}/{remote_ref} ({remote_sha[:8]}) is "
                f"not an ancestor of {local_ref} — this would discard commits currently "
                "on the remote. Fetch and reconcile first, then retry."
            )


def check_destructive_git(cmd: str, cwd: str | None, d: dict) -> None:
    """Fail closed on git worktree remove / branch -D / rm -r / git clean /
    git reset --hard / git push --force that would discard content with no
    recoverable backup. This runs unconditionally — it does not depend on
    is_mutation() or checkout ownership, since the risk (an untracked file
    or an unpushed commit with zero git-level backup) is the same regardless
    of who owns the checkout or whether the broader mutation heuristic
    happens to fire.

    A single structured, evidenced override (bridge_workflow.mode=
    destructive-override, with real reason + verified_how) skips every check
    below for this one command and is durably logged — never a silent
    bypass. This is checked once, here, rather than threaded through every
    sub-check, because the override is a property of the command being run,
    not of any one specific risk within it."""
    scope = workflow_metadata(d)
    if scope.get("mode") == "destructive-override":
        ok, evidence = destructive_override(d)
        if not ok:
            deny(evidence)
        log_override(cmd, cwd, evidence)
        return

    check_rm_recursive(cmd, cwd)
    check_git_clean(cmd, cwd)
    check_git_reset_hard(cmd, cwd)
    check_git_push_force(cmd, cwd)

    for m in WORKTREE_REMOVE_RE.finditer(cmd):
        repo_flag, raw_target = m.group(1), m.group(2)
        if not raw_target:
            continue
        base = resolve_repo_relative(repo_flag, cwd)
        target = resolve_repo_relative(raw_target, str(base))
        if not target.exists():
            continue  # already gone or unresolvable path; nothing to protect
        dirty = dirty_status(target)
        if dirty:
            deny(
                f"git worktree remove denied: {target} has {dirty}. "
                "This is not recoverable once the worktree is removed unless "
                "it has already been committed and pushed. Commit and push "
                "first, then retry."
            )
        reason = unpushed_reason(target)
        if reason:
            deny(f"git worktree remove denied: {target} — {reason}. Push it somewhere first, then retry.")

    for m in BRANCH_DELETE_RE.finditer(cmd):
        repo_flag, branch = m.group(1), m.group(2)
        repo_path = resolve_repo_relative(repo_flag, cwd)
        try:
            sha_result = subprocess.run(
                ["git", "-C", str(repo_path), "rev-parse", "--verify", branch],
                capture_output=True, text=True,
            )
        except OSError:
            continue
        if sha_result.returncode != 0:
            continue  # branch does not exist here; not this hook's problem
        sha = sha_result.stdout.strip()
        reason = unpushed_reason(repo_path, sha)
        if reason:
            deny(f"git branch delete denied: {branch} ({sha[:8]}) — {reason}. Push it somewhere first, then retry.")


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
        check_destructive_git(cmd, cwd, d)
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
