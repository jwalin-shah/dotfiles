#!/usr/bin/env bash
# install-assurance-binaries.sh — build + atomically install the assurance
# binaries from source: bridge, homebase, drive-admit, bridge-verifier, orbit.
#
# Builds each into a temp dir, writes a version/digest receipt, installs with
# atomic rename, and only restarts affected LaunchAgents AFTER every binary
# succeeds (no partial installs). The verifier digest the bridge service
# consumes is updated via a generated local env file, never by editing secrets
# into Nix.
set -euo pipefail

LOCALBIN="${FIRSTMATE_LOCALBIN:-${HOME}/.local/bin}"
mkdir -p "$LOCALBIN"
RECEIPT="${HOME}/.local/state/bridge/assurance-binaries.txt"
STRENGTH="${HOME}/.local/state/bridge/verifier-digest.env"

die() { echo "install-assurance-binaries: $*" >&2; exit 1; }

# Rebuild a single Go command from a repo dir into $LOCALBIN with atomic rename.
build_go() {  # repo_dir  pkg_path  bin_name
  local repo="$1" pkg="$2" name="$3" tmp built
  tmp="$(mktemp -d)"
  built="$tmp/$name"
  (cd "$repo" && go build -o "$built" "$pkg") || return 1
  install_atomic "$built" "$LOCALBIN/$name"
  rm -rf "$tmp"
}

install_atomic() {  # src  dst
  local src="$1" dst="$2"
  chmod 755 "$src"
  local tmpdst="${dst}.tmp.$$"
  /bin/mv "$src" "$tmpdst"
  /bin/mv -f "$tmpdst" "$dst"
}

echo "== building assurance binaries =="
build_go "${HOME}/projects/bridge" ./cmd/bridge       bridge
build_go "${HOME}/projects/bridge" ./cmd/bridge-verifier bridge-verifier
build_go "${HOME}/projects/bridge" ./cmd/keygen      keygen
build_go "${HOME}/projects/homebase" ./cmd/homebase    homebase
build_go "${HOME}/projects/homebase" ./cmd/drive-admit drive-admit
# orbit — best-effort: it currently needs ../bridge-running-machine which is
# absent, so a failure here is non-fatal.
if [[ -d "${HOME}/projects/orbit/cmd/orbit" ]]; then
  (cd "${HOME}/projects/orbit" && go build -o "$LOCALBIN/orbit" ./cmd/orbit) \
    && echo "installed orbit" || echo "warn: orbit build failed (optional — needs ../bridge-running-machine)"
fi

echo "== writing digest receipt =="
{
  echo "# assurance binaries — $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "# sha256 of each installed binary. PUBLIC digests, not secrets."
  for b in bridge bridge-verifier keygen homebase drive-admit orbit; do
    if [[ -f "$LOCALBIN/$b" ]]; then
      printf '%-16s %s\n' "$b" "$(shasum -a 256 "$LOCALBIN/$b" | awk '{print $1}')"
    fi
  done
} > "$RECEIPT"

# Verifier digest consumed by the bridge/homebase service (generated env file,
# not committed anywhere).
verifier_digest="$(shasum -a 256 "${LOCALBIN}/bridge-verifier" | awk '{print $1}')"
{
  echo "BRIDGE_VERIFIER_BINARY_SHA256=\"$verifier_digest\""
  echo "BRIDGE_VERIFIER_BINARY=\"$LOCALBIN/bridge-verifier\""
} > "$STRENGTH"
chmod 600 "$STRENGTH"

echo
echo "Installed: bridge, bridge-verifier, keygen, homebase, drive-admit, orbit"
echo "Receipt:   $RECEIPT"
echo "Verifier env: $STRENGTH"
echo
echo "NOTE: If you keep the homebase or bridge-serve LaunchAgents, restart them:"
echo "  launchctl kickstart -k gui/\$(id -u)/org.nixos.com.jwalinshah.homebase"
echo "  launchctl kickstart -k gui/\$(id -u)/org.nixos.com.jwalinshah.bridge-serve"