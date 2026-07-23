#!/usr/bin/env bash
# prove-factory-e2e-scorecard.sh — fail closed if any machine-bar Y row lacks a
# working Prove command. Reads portfolio/wayfinder/factory-e2e-prove-rows.tsv
#
# Exit 1: missing scorecard/tsv, Y with empty cmd, or Y cmd exit ≠ 0
# Exit 0: all Y rows proved (P/N skipped)
set -euo pipefail

PORTFOLIO="${PORTFOLIO:-$HOME/projects/portfolio}"
SCORECARD="${PORTFOLIO}/wayfinder/factory-e2e-readiness-2026-07-23.md"
ROWS="${PORTFOLIO}/wayfinder/factory-e2e-prove-rows.tsv"

FAIL=0
ok() { echo "  OK  $*"; }
fail() { echo "  FAIL $*" >&2; FAIL=1; }
warn() { echo "  WARN $*"; }

echo "==> factory e2e scorecard schema prove"

if [[ ! -f "$SCORECARD" ]]; then
  fail "missing scorecard: $SCORECARD"
  exit 1
fi
ok "scorecard present"

# Required sections (Session 0 contract)
for needle in \
  "## Pre-AI craft and LLM-minimal" \
  "## Repo topology" \
  "## Harness DAG" \
  "## Search ports" \
  "## Work DAG" \
  "## Enforcement stack" \
  "## Tensor and axiom lineage" \
  "## Best-spec ritual" \
  "## Prove obligation derivation" \
  "## Variant lab and ca explore" \
  "## Machine gaps" \
  "## Enterprise gaps"
do
  if rg -q -F "$needle" "$SCORECARD"; then
    ok "section: $needle"
  else
    fail "missing section: $needle"
  fi
done

if [[ ! -f "$ROWS" ]]; then
  fail "missing prove rows: $ROWS"
  exit 1
fi
ok "prove-rows tsv present"

y_count=0
while IFS=$'\t' read -r id score cmd || [[ -n "${id:-}" ]]; do
  [[ -z "${id:-}" || "$id" =~ ^# ]] && continue
  score="$(echo "$score" | tr -d '[:space:]')"
  # trim
  cmd="${cmd#"${cmd%%[![:space:]]*}"}"
  case "$score" in
    Y|y)
      y_count=$((y_count + 1))
      if [[ -z "$cmd" || "$cmd" =~ ^# ]]; then
        fail "$id score=Y but Prove cmd empty"
        continue
      fi
      echo "  RUN $id: $cmd"
      set +e
      # shellcheck disable=SC2086
      bash -c "$cmd" >/tmp/factory-e2e-"$id".out 2>/tmp/factory-e2e-"$id".err
      rc=$?
      set -e
      if [[ "$rc" -eq 0 ]]; then
        ok "$id proved (exit 0)"
      else
        fail "$id prove exit=$rc — see /tmp/factory-e2e-$id.err"
        tail -5 "/tmp/factory-e2e-$id.err" 2>/dev/null || true
      fi
      ;;
    P|p|N|n)
      warn "$id score=$score (gap/deferred) — $cmd"
      ;;
    *)
      fail "$id unknown score='$score'"
      ;;
  esac
done < "$ROWS"

if [[ "$y_count" -lt 1 ]]; then
  fail "no Y rows in $ROWS"
fi

if [[ "$FAIL" -ne 0 ]]; then
  echo "prove-factory-e2e-scorecard: FAILED" >&2
  exit 1
fi
echo "prove-factory-e2e-scorecard: ALL Y ROWS PROVED ($y_count)"
exit 0
