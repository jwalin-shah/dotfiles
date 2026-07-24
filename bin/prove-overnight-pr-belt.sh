#!/usr/bin/env bash
# prove-overnight-pr-belt.sh — regression for overnight delivery=pr PR matching.
# Mirrors jq in overnight-harden-tick.sh (keep in sync when changing the belt).
set -euo pipefail

match_count() {
  local tid="$1"
  local json="$2"
  jq --arg tid "$tid" '
    def tokens: ascii_downcase | gsub("/"; "-") | split("-") | map(select(length > 2));
    def stem_tokens: tokens
      | map(select(
          (. != "fix" and . != "feat" and . != "feature"
           and . != "chore" and . != "docs" and . != "design"
           and . != "refactor" and . != "test" and . != "ci"
           and . != "clean")
          and (test("^[0-9]+$") | not)
        ));
    [.[] | select(
      (.head.ref | contains($tid)) or
      (.title | contains($tid)) or
      ((.body // "") | contains($tid)) or
      (
        (.head.ref | stem_tokens) as $ht
        | ($ht | length) >= 4
        and ($ht | all(. as $t | ($tid | ascii_downcase | contains($t))))
      )
    )] | length
  ' <<<"$json"
}

# Fixtures mirror real abbreviated branches from this harden arc.
FIXTURE='[
  {"number":45,"title":"design: ledger-truth","head":{"ref":"design-ledger-truth-reconciliation"},"body":"ledger-truth-reconciliation-design"},
  {"number":48,"title":"design: clean base","head":{"ref":"feature/spawn-clean-base-note-only"},"body":"spawn-feature-branch-clean-base"},
  {"number":50,"title":"origin/main worktree","head":{"ref":"design/spawn-worktree-origin-main-052"},"body":""},
  {"number":53,"title":"LandedWorkProof","head":{"ref":"clean-landed-work-proof-054"},"body":"trim-portfolio-pr46-landed-work-proof"},
  {"number":96,"title":"overnight-queue denylist","head":{"ref":"trim-95-isolation"},"body":"trim-bridge-pr-95-isolation-only"}
]'

fail=0
expect() {
  local tid="$1" want="$2" label="$3"
  local got
  got="$(match_count "$tid" "$FIXTURE")"
  if [[ "$got" -eq "$want" ]]; then
    echo "OK: $label (tid=$tid got=$got)"
  else
    echo "FAIL: $label (tid=$tid want=$want got=$got)" >&2
    fail=1
  fi
}

# Prefer body/title containing full ticket id when branch stems are short.
expect "ledger-truth-reconciliation-design" 1 "body contains full id"
expect "spawn-feature-branch-clean-base" 1 "body contains full id (slash branch)"
expect "spawn-worktree-from-origin-main-design" 1 "stem len>=4 numeric suffix"
expect "trim-portfolio-pr46-landed-work-proof" 1 "body contains full id (short clean- stem)"
expect "trim-bridge-pr-95-isolation-only" 1 "body contains full id (short trim branch)"
expect "no-such-ticket-zzz" 0 "nonsense id"
expect "landed-work-proof-spawn-exit-impl" 0 "no false match on similar LandedWorkProof PR"

if [[ "$fail" -ne 0 ]]; then
  echo "prove-overnight-pr-belt: FAILED" >&2
  exit 1
fi
echo "prove-overnight-pr-belt: ALL CHECKS PASSED"
