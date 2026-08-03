#!/usr/bin/env bash
# provision-authority-keys.sh — generate the HomeBase authority ed25519 key set
# into ~/.local/state/homebase/keys, once. Refuses to overwrite. Prints NO
# private material; emits a public enrollment manifest (key IDs + digests).
#
# Authority roles (separate identities; see SYSTEM_MAP authority model):
#   captain   - the human owner signs contracts/grants
#   bridge    - Bridge transport identity (HomeBase holds bridge public)
#   admission - HomeBase signs admission responses
#   verifier  - detached verifier attests receipts (HomeBase holds public)
#   receipt   - HomeBase signs durable receipts
#
# Keys are generated with bridge's `keygen` (the already-proven generator that
# emits Go ed25519 private keys — 64-byte seed+pub — not a bare 32-byte seed,
# which HomeBase's loadKey would reject). Reuse, don't reinvent.
#
# This is a provisioning command, NOT a rebuild step. Run explicitly and only
# when the key set is missing or you intend to rotate.
set -euo pipefail

STATE="${FIRSTMATE_STATE_DIR:-${HOME}/.local/state/homebase}"
DIR="${STATE}/keys"

usage() { echo "usage: provision-authority-keys.sh [--force]" >&2; exit 2; }

FORCE=0
[[ "${1:-}" == "--force" ]] && FORCE=1
[[ $# -le 1 ]] || usage

if [[ -d "$DIR" ]] && ls "$DIR"/*.priv 2>/dev/null | grep -q . && [[ "$FORCE" -ne 1 ]]; then
  echo "provision-authority-keys: key set already exists at $DIR (use --force to rotate)" >&2
  exit 1
fi

mkdir -p "$DIR"
chmod 700 "$STATE" "$DIR" 2>/dev/null || true

# Resolve bridge's keygen binary. Prefer a built one; fall back to `go run`.
find_keygen() {
  if command -v keygen >/dev/null 2>&1; then echo "keygen"; return; fi
  if [[ -x "${HOME}/.local/bin/keygen" ]]; then echo "${HOME}/.local/bin/keygen"; return; fi
  if [[ -d "${HOME}/projects/bridge/cmd/keygen" ]]; then
    echo "go run -C ${HOME}/projects/bridge ./cmd/keygen"
    return
  fi
  echo "provision-authority-keys: no keygen binary found (build bridge or place keygen on PATH)" >&2
  exit 1
}
KEYGEN="$(find_keygen)"

declare -a ROLES=(captain bridge admission verifier receipt)
for role in "${ROLES[@]}"; do
  priv="$DIR/${role}.priv"; pub="$DIR/${role}.pub"
  if [[ -f "$priv" ]] && [[ "$FORCE" -ne 1 ]]; then
    echo "keep existing $role keys"
    continue
  fi
  # shellcheck disable=SC2086
  $KEYGEN -private "$priv" -public "$pub"
  chmod 600 "$priv"
  # HomeBase's loadKey rejects ANY file that is group/world readable (0o077),
  # including public-key files — so the .pub must be 0600 too, not 0644.
  chmod 600 "$pub"
  echo "generated $role (priv 0600, pub 0600)"
done

# Enrollment manifest: public key IDs + sha256 of private key DIGEST (NOT the key).
MANIFEST="$STATE/keys-manifest.txt"
: > "$MANIFEST"
{
  echo "# HomeBase authority enrollment — generated $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "# PUBLIC data: key IDs + private-key sha256 digests. NO key material."
  echo "# HomeBase binds 127.0.0.1:9102 (PORT=9102). Key files are hex, 0600."
  for role in "${ROLES[@]}"; do
    pub="$DIR/${role}.pub"; priv="$DIR/${role}.priv"
    [[ -f "$pub" ]] || continue
    keyid=$(shasum -a 256 "$pub" | awk '{print $1}')
    privdigest=$(shasum -a 256 "$priv" | awk '{print $1}')
    printf '%-12s keyid=%s priv_sha256=%s\n' "$role" "$keyid" "$privdigest" >> "$MANIFEST"
  done
} >> "$MANIFEST"

echo
echo "Authority keys provisioned:"
echo "  dir:      $DIR"
echo "  manifest: $MANIFEST"
echo "  NO private key material printed. Existing keys were left unchanged"
echo "  unless --force was given."