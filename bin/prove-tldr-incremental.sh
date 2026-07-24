#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TLDR="${HOME}/.local/bin/tldr"
TLDR_PYTHON="${HOME}/.local/share/uv/tools/llm-tldr/bin/python3"

[[ -x "$TLDR" ]] || { echo "prove-tldr-incremental: missing tldr" >&2; exit 1; }
[[ -x "$TLDR_PYTHON" ]] || { echo "prove-tldr-incremental: missing llm-tldr python" >&2; exit 1; }

fixture="$(mktemp -d "${TMPDIR:-/tmp}/prove-tldr-incremental.XXXXXX")"
trap '/bin/rm -rf "$fixture"' EXIT
git -C "$fixture" init -q

"$TLDR_PYTHON" - "$fixture" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
(root / "main.go").write_text(
    "package fixture\n\n"
    "func Caller() { Before() }\n\n"
    "func Before() {}\n"
)
PY

"$TLDR_PYTHON" - "$TLDR" "$fixture" <<'PY'
import subprocess
import sys

subprocess.run(
    [sys.argv[1], "warm", sys.argv[2], "--lang", "go"],
    check=True,
    stdout=subprocess.DEVNULL,
    timeout=30,
)
PY
"$TLDR" impact Before "$fixture" --lang go | rg -q 'Caller'

"$TLDR_PYTHON" - "$fixture" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
(root / "main.go").write_text(
    "package fixture\n\n"
    "func Caller() { After() }\n\n"
    "func After() {}\n"
)
PY

"$ROOT/bin/tldr-mark-dirty" "$fixture/main.go"
jq -e '.dirty_files == ["main.go"]' "$fixture/.tldr/cache/dirty.json" >/dev/null
"$TLDR" calls "$fixture" --lang go | jq -e '
  (.edges | any(.to_func == "After")) and
  (.edges | all(.to_func != "Before"))
' >/dev/null
[[ ! -e "$fixture/.tldr/cache/dirty.json" ]]
"$TLDR" impact After "$fixture" --lang go | rg -q 'Caller'

# Two simultaneous editor hooks must not lose either dirty-file record.
"$TLDR_PYTHON" - "$fixture" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
(root / "one.go").write_text("package fixture\n\nfunc One() {}\n")
(root / "two.go").write_text("package fixture\n\nfunc Two() {}\n")
PY
"$ROOT/bin/tldr-mark-dirty" "$fixture/one.go" &
first_pid=$!
"$ROOT/bin/tldr-mark-dirty" "$fixture/two.go" &
second_pid=$!
wait "$first_pid"
wait "$second_pid"
jq -e '.dirty_files | sort == ["one.go", "two.go"]' \
  "$fixture/.tldr/cache/dirty.json" >/dev/null

echo "prove-tldr-incremental: PASS (one-file patch, fresh impact, concurrent markers, bounded warm)"
