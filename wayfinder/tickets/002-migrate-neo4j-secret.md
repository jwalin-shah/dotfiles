# Ticket 002 — Remove tracked Neo4j credential

**Status:** open; design and credential rotation require captain approval

**Opened:** 2026-07-23

**Owner:** dotfiles / machine secrets boundary

**Repo:** dotfiles

## Finding

`configuration.nix` currently contains a plaintext `NEO4J_PASSWORD` value in a
tracked LaunchAgent environment block. The value is intentionally omitted from
this ticket. Removing only the current line is insufficient because the old
credential remains in Git history and may still be active.

## Required inventory before implementation

Per the service capability gate, write down and prove the native surfaces
before adding a wrapper or client:

1. How the installed Neo4j service accepts local authentication and rotation.
2. Whether the existing daemon wrapper can source a secret without putting it
   in argv, logs, the Nix store, or a tracked environment file.
3. Whether the machine's existing Keychain-first / Infisical-on-refresh path
   can project exactly this one secret for the knowledge-engine process.
4. Which running consumers use the credential and how each is restarted.

## Inventory evidence (2026-07-29)

- **Neo4j service:** the Homebrew `neo4j` LaunchAgent was observed started,
  with local Bolt and HTTP listeners on loopback. No credential value was
  printed or persisted by the inventory.
- **Current daemon boundary:** `bin/daemon-wrapper` can source a configured
  `DAEMON_ENV_FILE`, but it does not read macOS Keychain or Infisical itself.
  Using a tracked or Nix-store environment file for this credential would fail
  the required secrecy boundary, so no new env-file projection was added.
- **Existing secret authority:** Bridge's `bridge-secrets` store is
  Keychain-first with Infisical refresh/export on a miss. A direct Keychain
  presence check found no `NEO4J_PASSWORD` entry. The read-only
  `bridge secrets audit --json` command returned an empty report; its current
  implementation skips inaccessible Infisical folders, so that result is not
  proof that the Infisical root is empty or that rotation is unnecessary.
- **Consumers:** Dotfiles declares the
  `com.jwalinshah.knowledge-engine` LaunchAgent for
  `scripts/sync-and-embed.sh`; the on-change and graph-sync scripts also
  consume `NEO4J_PASSWORD`. The knowledge-engine LaunchAgent was not running
  during this inspection. The Bridge Go knowledge client no longer supplies a
  known fallback password and now rejects a missing value before connecting.
- **Boundary still open:** no credential was rotated or created. The approved
  Keychain/Infisical name, projection mechanism, restart order, and history
  decision remain captain-approved work items.

## Acceptance

- [ ] No Neo4j credential value in tracked files, generated Nix store paths,
      process argv, or persisted logs.
- [ ] Runtime reads the credential from an approved local secret authority.
- [ ] Existing credential is rotated after all consumers are migrated.
- [ ] Neo4j health and authenticated read/write probes pass after restart.
- [ ] `bridge verify-machine` passes all verifier-owned gates.
- [ ] A repository-history decision is recorded: rotate-only, history rewrite,
      or repository replacement. Do not rewrite history without captain approval.

## Safety boundary

Do not print the current value, pass it on a command line, or paste it into
chat. Authentication and rotation are human-approved operations.
