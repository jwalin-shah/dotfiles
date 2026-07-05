# Project agent memory

This file is the project's committed home for project-intrinsic agent knowledge: build, test, release, architecture, and sharp-edge notes that should travel with the code.

- Add durable project-specific notes here as they are discovered through real work.
- This repo is public (`github.com/kunchenguid/dotfiles`) and is used as an on-camera teaching artifact for a mac-setup video. `flake.nix`, `configuration.nix`, `home.nix`, and `rebuild.sh` are what the video shows on screen - do not modify them without an explicit human decision; add new files instead.
- `bootstrap.sh` (repo root) takes a fresh Mac from a bare clone to a built config: install Determinate Nix, symlink the repo to `~/.dotfiles` (required before the first build - `home.nix` resolves `mkOutOfStoreSymlink` paths through it), then run the first `darwin-rebuild switch` pinned to the `nix-darwin-26.05` channel (matching `flake.nix`). After that, `rebuild.sh` works normally.
- The correct Determinate Nix installer command is `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install` (confirmed against determinate.systems docs). A prior sibling repo shipped a wrong domain for this - don't guess it, re-verify from the official source if it ever needs to change.
- `herdr` in `configuration.nix`'s `brews` list is a real public Homebrew formula in homebrew-core (verified via `brew info herdr` / `brew search herdr`) - it is not a private/author-only tool and needs no tap.
- `configuration.nix` sets `homebrew.onActivation.cleanup = "zap"`, which uninstalls any Homebrew package/cask not listed in `brews`/`casks` on every switch. This is called out prominently in README.md; keep that warning if the README is ever rewritten.
