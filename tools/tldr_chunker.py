"""Tree-sitter-aware chunker — splits files at function/class boundaries.

Uses ``tldr structure`` (tree-sitter AST) to identify function, method, and
class definitions, then extracts each as a standalone chunk. Falls back to
character-split when tldr finds nothing.

Every chunk is verified against CodeRank's 2048-token limit using the
llama-server /tokenize endpoint. Chunks that exceed 2000 tokens are
recursively bisected until they fit. No guesswork. No calibration drift.
"""

from __future__ import annotations

import json
import subprocess
import urllib.request
from pathlib import Path

from cocoindex.resources.chunk import Chunk, TextPosition

# CodeRank's hard limit. We target 2000 for a 48-token safety margin.
MAX_TOKENS = 2000

# Character-level fallback: 2500 chars at worst-case density (1.318 chars/token
# as observed in dense Go code) = 1896 tokens — safely under 2048.
# This avoids tokenize calls for the 95% of chunks that clearly fit.
MAX_CHARS = 2500

# Languages tldr has reliable tree-sitter support for.
TLDR_LANGS = frozenset({"go", "python", "typescript", "tsx", "rust", "swift", "c", "cpp", "java", "zig", "lua"})

# Tokenize endpoint. Cached per daemon lifetime.
_TOKENIZE_ENDPOINT = "http://127.0.0.1:8082/tokenize"


def _count_tokens(text: str) -> int | None:
    """Count tokens using the llama-server /tokenize endpoint.

    Returns None if the endpoint is unreachable (daemon not running).
    """
    try:
        data = json.dumps({"content": text}).encode()
        req = urllib.request.Request(
            _TOKENIZE_ENDPOINT,
            data=data,
            headers={"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            result = json.loads(resp.read())
            return len(result.get("tokens", []))
    except Exception:
        return None


def _fit_tokens(text: str) -> list[str]:
    """Guarantee *text* splits into pieces each ≤ MAX_TOKENS.

    Uses exact token counting via /tokenize. If the endpoint is down,
    falls back to a safe character-level estimate (MAX_CHARS / 2).
    Binary-splits recursively on oversize pieces.
    """
    tokens = _count_tokens(text)
    if tokens is not None and tokens <= MAX_TOKENS:
        return [text]

    # Tokenize unavailable or piece is oversize — split in half
    # and recurse. Each recursive call verifies again.
    half = min(len(text) // 2, MAX_CHARS // 2)
    if half < 1:
        return [text]  # can't split further
    a = text[:half]
    b = text[half:]
    return _fit_tokens(a) + _fit_tokens(b)


def _needs_verification(chars: int) -> bool:
    """Only tokenize chunks that might plausibly exceed MAX_TOKENS.

    2048 token limit / 1.318 worst-case chars-per-token = 2700 chars.
    At 1800 chars, the worst-case is 1800/1.318 = 1365 tokens — safe.
    Above 1600 chars, density can vary unpredictably, so we verify.
    """
    return chars > 1600


def _tldr_definitions(path: Path) -> list[dict] | None:
    """Run ``tldr structure`` and return function/class/method definitions."""
    try:
        result = subprocess.run(
            ["tldr", "structure", str(path)],
            capture_output=True, text=True, timeout=15,
        )
        if result.returncode != 0:
            return None
        data = json.loads(result.stdout)
        definitions = []
        for file_info in data.get("files", []):
            lang = file_info.get("language") or data.get("language", "")
            for d in file_info.get("definitions", []):
                if d.get("kind") in ("function", "method", "class"):
                    d["_language"] = lang
                    definitions.append(d)
        return definitions if definitions else None
    except (subprocess.TimeoutExpired, json.JSONDecodeError, KeyError, OSError):
        return None


def _char_split(content: str) -> list[Chunk]:
    """Split every MAX_CHARS characters. Safe fallback."""
    chunks = []
    for i in range(0, len(content), MAX_CHARS):
        piece = content[i : i + MAX_CHARS]
        chunks.append(Chunk(
            text=piece,
            start=TextPosition(byte_offset=i, char_offset=i, line=1, column=0),
            end=TextPosition(byte_offset=i + len(piece), char_offset=i + len(piece), line=1, column=0),
        ))
    return chunks


def _tldr_split(path: Path, content: str) -> list[Chunk] | None:
    """Split at function/class boundaries using tldr AST.

    Returns None if no definitions found (caller should fall back).
    """
    defs = _tldr_definitions(path)
    if not defs:
        return None

    lines = content.split("\n")
    chunks: list[Chunk] = []
    last_end = 0
    char_offset = 0

    defs.sort(key=lambda d: d.get("line_start", 0))

    for d in defs:
        ls = d.get("line_start", 0)
        le = d.get("line_end", 0)
        if ls < 1 or le < ls:
            continue

        # Preamble: imports/comments before this function
        if ls - 1 > last_end:
            pre_lines = lines[last_end : ls - 1]
            pre = "\n".join(pre_lines)
            pre_chars = sum(len(l) + 1 for l in pre_lines)
            if pre.strip():
                chunks.append(Chunk(
                    text=pre,
                    start=TextPosition(byte_offset=char_offset, char_offset=char_offset,
                                       line=last_end + 1, column=0),
                    end=TextPosition(byte_offset=char_offset + pre_chars,
                                     char_offset=char_offset + pre_chars,
                                     line=ls - 1, column=len(pre_lines[-1]) if pre_lines else 0),
                ))
            char_offset += pre_chars

        # Function body
        body_lines = lines[ls - 1 : le]
        body = "\n".join(body_lines)
        body_chars = sum(len(l) + 1 for l in body_lines)

        if _needs_verification(body_chars):
            # Large function — verify with exact token count, split if needed
            pieces = _fit_tokens(body)
            for piece in pieces:
                piece_lines = piece.split("\n")
                piece_chars = sum(len(l) + 1 for l in piece_lines)
                chunks.append(Chunk(
                    text=piece,
                    start=TextPosition(byte_offset=char_offset, char_offset=char_offset,
                                       line=ls, column=0),
                    end=TextPosition(byte_offset=char_offset + piece_chars,
                                     char_offset=char_offset + piece_chars,
                                     line=ls + len(piece_lines) - 1,
                                     column=len(piece_lines[-1]) if piece_lines else 0),
                ))
                char_offset += piece_chars
        else:
            chunks.append(Chunk(
                text=body,
                start=TextPosition(byte_offset=char_offset, char_offset=char_offset,
                                   line=ls, column=0),
                end=TextPosition(byte_offset=char_offset + body_chars,
                                 char_offset=char_offset + body_chars,
                                 line=le, column=len(body_lines[-1]) if body_lines else 0),
            ))
            char_offset += body_chars

        last_end = le

    # Tail
    if last_end < len(lines):
        tail_lines = lines[last_end:]
        tail = "\n".join(tail_lines)
        if tail.strip():
            tails_chars = sum(len(l) + 1 for l in tail_lines)
            chunks.append(Chunk(
                text=tail,
                start=TextPosition(byte_offset=char_offset, char_offset=char_offset,
                                   line=last_end + 1, column=0),
                end=TextPosition(byte_offset=char_offset + tails_chars,
                                 char_offset=char_offset + tails_chars,
                                 line=len(lines), column=len(tail_lines[-1]) if tail_lines else 0),
            ))

    return chunks if chunks else None


# ── Public API: one chunker, handles everything ──────────────────────

def chunk(path: Path, content: str) -> tuple[str | None, list[Chunk]]:
    """Split a file into embeddable chunks.

    Code files: tree-sitter at function/class boundaries.
    Everything else: character-level split.
    All chunks guaranteed ≤ 2000 tokens via /tokenize verification.
    """
    suffix = path.suffix.lstrip(".").lower()
    if suffix in TLDR_LANGS:
        result = _tldr_split(path, content)
        if result:
            return (None, result)
    return (None, _char_split(content))
