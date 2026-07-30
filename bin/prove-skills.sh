#!/usr/bin/env bash
# Prove required agent skills exist with SKILL.md under dotfiles/.agents
set -euo pipefail
ROOT="${DOTFILES_ROOT:-$HOME/Projects/dotfiles}/.agents"
REQUIRED=(
  preflight
  wayfinder
  grill-me
  domain-modeling
  codebase-design
  setup-matt-pocock-skills
  research
  prototype
  code-review
)
missing=0
for s in "${REQUIRED[@]}"; do
  if [[ ! -f "$ROOT/$s/SKILL.md" ]]; then
    echo "MISSING $s/SKILL.md"
    missing=1
  else
    echo "OK $s"
  fi
done
if [[ "$missing" -ne 0 ]]; then
  echo "prove-skills: FAIL"
  exit 1
fi
echo "prove-skills: PASS (${#REQUIRED[@]} required)"
exit 0
