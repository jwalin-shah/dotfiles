# Cocoindex config persistence

The files in `tools/` are the canonical copies of Cocoindex configuration.
They live in dotfiles so they survive `nix-darwin` rebuilds and serve as
the single source of truth for this machine's code indexing setup.

## Files

| File | Purpose |
|------|---------|
| `tools/cocoindex-global-settings.yml` | Global Cocoindex settings — embedding provider (CodeRankEmbed on `:8082`), API base URL, PYTHONPATH |
| `tools/cocoindex-project-settings.yml` | Per-project settings — include paths, exclude patterns, file-type patterns, chunker config |
| `tools/tldr_chunker.py` | Custom tree-sitter-aware chunker — splits files at function/class boundaries, verifies against CodeRank's 2048-token limit via `/tokenize` endpoint |

## How they're used

Cocoindex reads these files at index time. The `tldr_chunker.py` module is
referenced by `cocoindex-project-settings.yml` under `chunkers:` — each
supported file extension maps to `tldr_chunker:chunk`, which calls the
`chunk()` function in that module.

The chunker uses `tldr structure` (tree-sitter AST) to identify function,
method, and class definitions, then extracts each as a standalone chunk.
Chunks are verified against the CodeRank embed server's 2048-token limit
using the `/tokenize` endpoint. Oversized chunks are recursively bisected.

## Why dotfiles owns them

1. **Survive rebuilds.** `nix-darwin` rebuilds wipe anything not declared
   in `configuration.nix`. These files are symlinked or copied from dotfiles
   so they persist.
2. **Single source of truth.** The dotfiles repo is the machine's
   configuration authority. Code indexing config belongs here, not scattered
   across project directories.
3. **Portable.** If this machine is rebuilt from scratch, these files
   are part of the dotfiles checkout and can be restored immediately.

## Embedder model split

Two separate embedding servers run on this machine:

| Server | Port | Model | Purpose |
|--------|------|-------|---------|
| CodeRank Embed | `:8082` | CodeRankEmbed (GGUF Q8) | Code embeddings for Cocoindex |
| Llama Embed | `:8081` | Qwen3-Embedding-0.6B (GGUF Q8) | General-purpose embeddings for Cognee |

The global settings file points Cocoindex at `:8082` for code-specialized
embeddings. Cognee uses `:8081` independently. This split was discovered
during Cocoindex setup — using a single embed server for both degraded
code search quality.

## Chunking calibration

The `MAX_CHARS` and `MAX_TOKENS` constants in `tldr_chunker.py` were
calibrated against real dense Go code:
- 2500 chars at worst-case density (1.318 chars/token) = 1896 tokens —
  safely under the 2048 limit without calling `/tokenize` for every chunk
- Chunks above 1600 chars trigger token verification
- Chunks above 2000 tokens are recursively bisected
