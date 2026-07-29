# Formal toolchain ownership

The machine has one owner per formal-verification capability. Homebrew cleanup
is allowed to remove undeclared duplicate packages; it must not remove the
active owner below.

| Capability | Owner | Live proof surface |
|---|---|---|
| Dafny | Home Manager/Nix (`home.nix`) | `dafny verify verification/linearity.dfy` |
| Z3 | uv exact receipt (`config/agent-toolchain.tsv`) | `python3 verification/z3/*.py` |
| Lean and Lake | elan (`home.nix`) | `cd verification/lean && lake build` |
| TLC | versioned `verification/tla/tools/tla2tools.jar` | `verification/tla/run-tlc.sh` |
| Java runtime | Homebrew JDK | TLC execution |

`dotnet`, a separate Homebrew `dafny`, and a separate Homebrew `z3` are not
required by the active proof commands. The launcher gate checks the actual
commands, and Bridge CI runs the proofs themselves. A package may be added
only when a proof command fails and its ownership is recorded here first.

TLC is explicitly bounded. The 2-worker configuration is the exhaustive
CI-sized model; larger configurations are research runs and must set an
explicit timeout. No rebuild or unattended agent may launch an unbounded TLC
process.
