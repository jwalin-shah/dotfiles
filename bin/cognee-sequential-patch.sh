#!/usr/bin/env bash
# ── Deterministic shell: cognee sequential extraction patch ─────────
# Fixes: asyncio.gather in extract_graph_from_data.py fires all LLM
# calls concurrently, overwhelming single-GPU local MLX server.
# Applies after every cognee uv tool update.
set -euo pipefail

TARGET="$HOME/.local/share/uv/tools/cognee/lib/python3.13/site-packages/cognee/tasks/graph/extract_graph_from_data.py"
LOCKDIR="/tmp/cognee-patch.lockdir"
GEN_ID="$(date +%s)-$$"

log_event() {
    local event="$1" detail="${2:-}"
    printf '{"gen_id":"%s","event":"%s","timestamp":"%s","detail":"%s"}\n' \
        "$GEN_ID" "$event" "$(date -u +"%Y-%m-%dT%H:%M:%S%z")" "$detail" >> "$HOME/.local/share/jw/cognee-patch-lifecycle.jsonl"
}

# Single instance
if ! mkdir "$LOCKDIR" 2>/dev/null; then
    echo "[cognee-patch] already running or recently ran" >&2
    exit 75
fi
trap 'rm -rf "$LOCKDIR"' EXIT

log_event "patch_started" "target=$TARGET"

# Check if already patched
if grep -q 'Process chunks sequentially' "$TARGET" 2>/dev/null; then
    log_event "already_patched" "sequential processing already present"
    echo "[cognee-patch] already patched — sequential processing present"
    exit 0
fi

# Apply the patch: replace asyncio.gather with sequential loop
python3 << 'PYEOF'
import sys
target = "/Users/jwalinshah/.local/share/uv/tools/cognee/lib/python3.13/site-packages/cognee/tasks/graph/extract_graph_from_data.py"

with open(target) as f:
    content = f.read()

old = """        with pipeline_stage("extraction"):
            chunk_graphs = await asyncio.gather(
                *[
                    extract_content_graph(
                        chunk.text, graph_model, custom_prompt=custom_prompt, **kwargs
                    )
                    for chunk in non_dlt_chunks
                ]
            )"""

new = """        with pipeline_stage("extraction"):
            # Process chunks sequentially to avoid overwhelming local LLM servers.
            # asyncio.gather fires all requests concurrently - works for cloud
            # providers but crashes single-GPU local servers (e.g. MLX on :8080).
            # Patch: cognee-sequential-patch.sh (dotfiles)
            chunk_graphs = []
            for chunk in non_dlt_chunks:
                graph = await extract_content_graph(
                    chunk.text, graph_model, custom_prompt=custom_prompt, **kwargs
                )
                chunk_graphs.append(graph)"""

if old in content:
    content = content.replace(old, new)
    with open(target, 'w') as f:
        f.write(content)
    print("PATCHED: asyncio.gather → sequential loop")
else:
    print("NOT FOUND: asyncio.gather pattern not in file (already patched?)")
    sys.exit(1)
PYEOF

log_event "patch_applied" "sequential extraction enabled"
echo "[cognee-patch] done"
