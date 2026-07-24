# Home Manager activation PATH incident — 2026-07-23

## Outcome

The first rebuild after dotfiles PR #3 stopped during Home Manager
`linkGeneration`. The Nix system derivation built, but the generated activation
program failed before home-file links and user LaunchAgents completed.

## Reproduction

The generated activation script contained two global PATH exports:

1. Home Manager's initial PATH, with GNU coreutils before system tools.
2. The custom `agentToolchain` node, which prepended `/usr/bin` globally.

Standard `linkGeneration` later called `readlink -e`. Because the custom export
had changed command resolution for every later node, macOS `/usr/bin/readlink`
ran and rejected `-e`.

## Why the earlier proof missed it

`nix build '.#darwinConfigurations.mac.system' --no-link` proved that Nix could
construct the derivation. It did not execute or inspect the generated Home
Manager activation program. `llm-tldr change-impact home.nix` also returned no
changed functions or affected tests because Nix activation DAGs are outside its
language model.

Source search, TLDR, code embeddings, and Neo4j remain useful for ownership,
prior art, and blast-radius discovery. They are not runtime certification. The
generated representation is the actual program that must be checked.

## Permanent invariant

```text
source config
  -> build Nix closure
  -> inspect generated Home Manager activation
  -> require one global PATH export and GNU readlink -e
  -> only then mutate live links or request sudo
  -> certify live projections and LaunchAgents
```

Custom activation nodes must scope PATH to one command. They must not export a
new global PATH into later Home Manager nodes.

## Enforcement

- `bin/prove-home-activation.sh` builds and inspects the generated closure.
- `rebuild.sh` runs that proof before changing live paths.
- The global pre-commit hook runs it when activation-related dotfiles are staged.

This incident is closed only after a subsequent `./rebuild.sh` completes and
the live `preflight` skill projections, Neovim configuration, and LaunchAgents
pass their post-activation proofs.
