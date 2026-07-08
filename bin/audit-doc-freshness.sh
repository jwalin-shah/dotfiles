#!/usr/bin/env python3
from __future__ import annotations

import os
import pathlib
import re
import sys


REPO = pathlib.Path("/Users/jwalinshah/projects/dotfiles")
HOME = pathlib.Path("/Users/jwalinshah")
SKIP_DIRS = {".git", "docs/archive", "templates", "node_modules"}
SKIP_FILES = {
    "bin/audit-config-ownership.sh",
    "bin/audit-doc-freshness.sh",
}

ABS_PATH_RE = re.compile(r"/Users/jwalinshah/[^\s`\"')>]+")
MD_LINK_RE = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
STALE_TOKENS = [
    "/Users/jwalinshah/projects/machine-scratch",
    "tool-guard",
    "orca",
    "machine-bootstrap router",
]


def fail(msg: str) -> None:
    print(f"audit-doc-freshness: {msg}", file=sys.stderr)
    raise SystemExit(1)


def is_skipped(path: pathlib.Path) -> bool:
    rel = path.relative_to(REPO).as_posix()
    if rel in SKIP_FILES:
        return True
    parts = rel.split("/")
    if any(part in SKIP_DIRS for part in parts[:-1]):
        return True
    return False


def iter_files() -> list[pathlib.Path]:
    files: list[pathlib.Path] = []
    for path in REPO.rglob("*"):
        if path.is_dir():
            continue
        if is_skipped(path):
            continue
        if path.suffix.lower() not in {".md", ".markdown", ".txt"}:
            continue
        files.append(path)
    return files


def strip_fragment(target: str) -> str:
    target = target.split("#", 1)[0]
    target = target.split("?", 1)[0]
    return target


def strip_line_suffix(target: str) -> str:
    if target.startswith("/Users/jwalinshah/"):
        for sep in (":L", "#L", ":"):
            if sep in target:
                base, suffix = target.split(sep, 1)
                if suffix and suffix[0].isdigit():
                    return base
    return target


def resolve_target(source: pathlib.Path, target: str) -> pathlib.Path | None:
    target = strip_fragment(target.strip())
    if not target or target.startswith(("http://", "https://", "mailto:", "file://", "app://")):
        return None
    target = strip_line_suffix(target)
    if target.startswith("/"):
        return pathlib.Path(target)
    if target.startswith("~/"):
        return HOME / target[2:]
    return (source.parent / target).resolve()


def main() -> None:
    stale_hits: list[str] = []
    broken_links: list[str] = []

    for path in iter_files():
        text = path.read_text()
        rel = path.relative_to(REPO).as_posix()

        for token in STALE_TOKENS:
            if token in text:
                stale_hits.append(f"{rel}: contains {token}")

        if path.suffix.lower() in {".md", ".markdown", ".txt"}:
            for match in ABS_PATH_RE.findall(text):
                resolved = pathlib.Path(match)
                if not resolved.exists():
                    broken_links.append(f"{rel}: missing absolute path {match}")

            for target in MD_LINK_RE.findall(text):
                resolved = resolve_target(path, target)
                if resolved is None:
                    continue
                if not resolved.exists():
                    broken_links.append(f"{rel}: missing link target {target}")

    if stale_hits:
        print("\n".join(stale_hits), file=sys.stderr)
        fail("stale references found in active docs")

    if broken_links:
        print("\n".join(broken_links), file=sys.stderr)
        fail("broken doc links found in active docs")

    print("audit-doc-freshness: ok")


if __name__ == "__main__":
    main()
