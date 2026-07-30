#!/usr/bin/env bash
# Deterministic contract tests for ca-watch. No real CA or provider is used.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
tmp="$(mktemp -d /tmp/ca-watch-test.XXXXXX)"
trap 'rm -rf "$tmp"' EXIT

fake_bin="$tmp/bin"
config_dir="$tmp/config"
project="$tmp/project"
mkdir -p "$fake_bin" "$config_dir/debug" "$project"

cat >"$fake_bin/mm-ctl" <<'EOF'
#!/usr/bin/env bash
printf '%s' "${CA_WATCH_FIXTURE:-}"
EOF
chmod +x "$fake_bin/mm-ctl"

write_trust() {
  local accepted="$1"
  printf '{"projects":{"%s":{"hasTrustDialogAccepted":%s}}}\n' \
    "$project" "$accepted" >"$config_dir/.claude.json"
}

run_watch() {
  local expected_rc="$1"
  local output
  local rc
  if output="$(
    CA_WATCH_FIXTURE="$CA_WATCH_FIXTURE" \
    CLAUDE_CONFIG_DIR="$config_dir" \
      PATH="$fake_bin:$PATH" \
      "$ROOT/bin/ca-watch" --once --pane 7 --project "$project" \
      --done-marker CA_DONE 2>&1
  )"; then
    rc=0
  else
    rc=$?
  fi
  [[ "$rc" == "$expected_rc" ]] || {
    printf 'expected exit %s, got %s\n%s\n' "$expected_rc" "$rc" "$output" >&2
    exit 1
  }
  printf '%s\n' "$output"
}

CA_WATCH_FIXTURE='CA_DONE'
write_trust false
output="$(run_watch 3)"
[[ "$output" == *'state=trust_required'* ]] || {
  printf 'missing trust_required state\n%s\n' "$output" >&2
  exit 1
}
[[ "$output" != *'state=complete'* ]] || {
  printf 'untrusted pane was marked complete\n%s\n' "$output" >&2
  exit 1
}
[[ "$output" != *'CA_DONE'* ]] || {
  printf 'pane content leaked\n%s\n' "$output" >&2
  exit 1
}

write_trust true
output="$(run_watch 0)"
[[ "$output" == *'state=complete'* ]] || {
  printf 'trusted pane was not marked complete\n%s\n' "$output" >&2
  exit 1
}

CA_WATCH_FIXTURE='overloaded_error CA_DONE'
output="$(run_watch 5)"
[[ "$output" == *'state=provider_degraded'* ]] || {
  printf 'provider degradation was not reported\n%s\n' "$output" >&2
  exit 1
}
[[ "$output" != *'state=complete'* ]] || {
  printf 'degraded pane was marked complete\n%s\n' "$output" >&2
  exit 1
}

if output="$(
  CLAUDE_CONFIG_DIR="$config_dir" \
    PATH="$fake_bin:$PATH" \
    "$ROOT/bin/ca-watch" --once --pane 7 --project "$project" \
    --max-seconds 601 2>&1
)"; then
  rc=0
else
  rc=$?
fi
[[ "$rc" == 2 && "$output" == *'bounded_durations_required'* ]] || {
  printf 'unbounded duration was accepted\n%s\n' "$output" >&2
  exit 1
}

CA_WATCH_FIXTURE=''
output="$(run_watch 4)"
[[ "$output" == *'state=pane_unavailable reason=empty_capture'* ]] || {
  printf 'empty pane capture was treated as healthy\n%s\n' "$output" >&2
  exit 1
}

printf 'ca-watch contract tests passed\n'
