#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: prune-agent-local-state.sh [--apply] [agent ...]

Agents: claude codex cursor gemini opencode
Defaults to all agents. Dry-run by default.
EOF
}

apply=0
agents=()

for arg in "$@"; do
  case "$arg" in
    --apply) apply=1 ;;
    -h|--help) usage; exit 0 ;;
    claude|codex|cursor|gemini|opencode) agents+=("$arg") ;;
    *)
      printf 'prune-agent-local-state: unknown arg: %s\n' "$arg" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ "${#agents[@]}" -eq 0 ]; then
  agents=(claude codex cursor gemini opencode)
fi

declare -A roots=(
  [claude]="${HOME}/.claude"
  [codex]="${HOME}/.codex"
  [cursor]="${HOME}/.cursor"
  [gemini]="${HOME}/.gemini"
  [opencode]="${HOME}/.config/opencode"
)

keep_list_for() {
  case "$1" in
    claude)
      printf '%s\n' \
        'CLAUDE.md' \
        'settings.json' \
        'sessions' \
        'history.jsonl' \
        'logs' \
        'file-history' \
        'plugins' \
        'skills' \
        'cache'
      ;;
    codex)
      printf '%s\n' \
        'config.toml' \
        'hooks.json' \
        'rules' \
        'auth.json' \
        'history.jsonl' \
        'memories' \
        'sessions' \
        'shell_snapshots' \
        'state_5.sqlite' \
        'state_5.sqlite-shm' \
        'state_5.sqlite-wal' \
        'goals_1.sqlite' \
        'goals_1.sqlite-shm' \
        'goals_1.sqlite-wal' \
        'version.json' \
        'plugins' \
        'skills'
      ;;
    cursor)
      printf '%s\n' \
        'cli-config.json' \
        'hooks.json' \
        'mcp.json' \
        'settings.json' \
        'sessions' \
        'history' \
        'chats' \
        'projects' \
        'skills-cursor' \
        'extensions'
      ;;
    gemini)
      printf '%s\n' \
        'settings.json' \
        'config' \
        'antigravity-cli' \
        'history.jsonl' \
        'conversation_summaries.db' \
        'conversations' \
        'knowledge' \
        'scratch' \
        'builtin' \
        'implicit' \
        'mcp' \
        'updater'
      ;;
    opencode)
      printf '%s\n' \
        'AGENTS.md' \
        'mcp.json' \
        'opencode.json' \
        'profiles' \
        'skills'
      ;;
  esac
}

purge_list_for() {
  case "$1" in
    claude)
      printf '%s\n' \
        'CLAUDE.md.backup' \
        'backups' \
        'mcp-needs-auth-cache.json' \
        'paste-cache' \
        'settings.json.backup' \
        'settings.json.bak'
      ;;
    codex)
      printf '%s\n' \
        '.personality_migration' \
        '.tmp' \
        'cache/codex_app_directory' \
        'cache/codex_apps_server_info' \
        'cache/codex_apps_tools' \
        'plugins/.remote-plugin-install-staging' \
        'settings.json.backup' \
        'settings.json.bak' \
        'tmp'
      ;;
    cursor)
      printf '%s\n' \
        'hooks.json.bak' \
        'plugins' \
        'statsig-cache.json'
      ;;
    gemini)
      printf '%s\n' \
        'settings.json.backup' \
        'settings.json.bak' \
        'cli.log'
      ;;
    opencode)
      printf '%s\n' \
        '.gitignore' \
        'AGENTS.md.backup' \
        'bun.lock' \
        'node_modules' \
        'opencode.json.backup' \
        'package-lock.json' \
        'package.json' \
        'plugins'
      ;;
  esac
}

printf 'Agent local-state cleanup\n'

for agent in "${agents[@]}"; do
  root="${roots[$agent]}"
  if [ ! -d "$root" ]; then
    printf '%s: missing directory: %s\n' "$agent" "$root" >&2
    continue
  fi

  printf '\n[%s] %s\n' "$agent" "$root"

  keep_map=$(keep_list_for "$agent")
  purge_map=$(purge_list_for "$agent")

  candidates=()
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    skip=0
    while IFS= read -r keep; do
      [ -n "$keep" ] || continue
      case "$rel" in
        "$keep"|"$keep"/*)
          skip=1
          break
          ;;
      esac
    done <<EOF_KEEP
$keep_map
EOF_KEEP
    [ "$skip" -eq 1 ] && continue

    while IFS= read -r purge; do
      [ -n "$purge" ] || continue
      case "$rel" in
        "$purge"|"$purge"/*)
          candidates+=("$rel")
          break
          ;;
      esac
    done <<EOF_PURGE
$purge_map
EOF_PURGE
  done < <(find "$root" -mindepth 1 -maxdepth 1 -print | sed "s#^$root/##" | sort)

  if [ "${#candidates[@]}" -eq 0 ]; then
    printf '  no unmanaged local state found\n'
    continue
  fi

  printf '  candidates:\n'
  for rel in "${candidates[@]}"; do
    printf '    %s\n' "$rel"
  done

  if [ "$apply" -ne 1 ]; then
    printf '  dry run only\n'
    continue
  fi

  for rel in "${candidates[@]}"; do
    rm -rf -- "$root/$rel"
  done

  printf '  remaining:\n'
  find "$root" -mindepth 1 -maxdepth 1 -print | sed "s#^$root/##" | sort | sed 's/^/    /'
done
