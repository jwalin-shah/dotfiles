# Nix Layer

`machine-scratch` is the active source of truth. Nix adds a reproducible machine
layer around the existing agent policy and installer.

## What Nix Owns

- macOS defaults through nix-darwin
- Homebrew formulae and casks through nix-homebrew
- user-level packages through home-manager
- stable symlinks from live config locations back into this repo
- Git identity and shared Git defaults

## What Nix Does Not Own

- secrets, API keys, OAuth state, private SSH keys
- Claude/Codex/OpenCode session databases and logs
- generated indexes, caches, `node_modules`, model downloads
- policy rendering logic that already lives in `bin/install-active-config.sh`

For package ownership details, see `docs/PACKAGE_MANAGEMENT.md`.

## Layering

```text
flake.nix
  -> nix/darwin.nix     system defaults, Homebrew apps, casks
  -> nix/home.nix       user packages, Git, symlinks
  -> install-active-config.sh  dynamic harness policy and launchers
```

`bin/nix-bootstrap.sh` runs the first nix-darwin switch, then installs active
agent config. After the first switch, use `bin/nix-rebuild.sh`.

## First Run

Install Determinate Nix:

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Then:

```bash
cd ~/machine-scratch
./bin/nix-bootstrap.sh
```

Daily use:

```bash
./bin/nix-rebuild.sh
```

## Homebrew Cleanup

`nix/darwin.nix` intentionally starts with:

```nix
homebrew.onActivation.cleanup = "none";
```

Keep it there while migrating. Only change it to `"zap"` after the declared
`brews` and `casks` lists are complete, because `"zap"` removes Homebrew
packages that are not listed.
