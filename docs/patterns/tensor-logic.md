# tensor-logic: Experiment Infrastructure

**Source**: `jwalin-shah/tensor-logic` (archived) -- `/tmp/audit-tensor-logic`

## Problem

Research codebases decay into "scripts that happened to run once." There is no
systematic way to track which experiment proved what, under what conditions,
with what caveats. READMEs drift; claims outlive their evidence.

## How It Works

Every experiment is a numbered `experiments/expN_descriptive_name.py` file with:

1. An **explicit hypothesis** stated at the top.
2. A **run command** (local or remote) that is reproducible.
3. A **result row** in `notes/EXPERIMENTS.md` -- append-only, never deleted.
4. Evidence lives in committed artifacts under `experiments/*_data/`.

The **no-overclaim rule** governs all communication: every claim must state its
evidence tier (toy, simulated, oracle, synthetic, internally-validated,
remote-only), its scope, and its caveats. You cannot promote a toy result into
a general capability claim.

`CONTEXT.md` serves as a binding agreement between human maintainers and coding
agents -- it defines the vocabulary, package map, experiment map, provenance
rules, claim boundaries, and validation commands. Agents read it before working.

## Interface / Contract

```python
# tensor_logic/program.py -- the core knowledge substrate
from dataclasses import dataclass

@dataclass(frozen=True)
class Program:
    domains: dict[str, Domain]       # named entity sets
    relations: dict[str, Relation]    # tensor-backed predicates
    rules: dict[str, list[Rule]]      # horn-clause rules
    sources: dict[tuple, FactSource]  # provenance for every fact

    def domain(self, name, symbols) -> Domain: ...
    def relation(self, name, *domain_names) -> Relation: ...
    def fact(self, relation, *symbols, value=1.0, source=None) -> None: ...
    def rule(self, text: str) -> None: ...
    def query(self, relation, *symbols, recursive=False) -> float: ...
```

```text
# CONTEXT.md claim-boundary section (the governance pattern)
- exp87-95 are support/stability slices -- toy/simulated only.
- exp94 is oracle upper-bound -- cite as upper bound only.
- exp95 is non-oracle, mixed: improves FP ranking but has identity gaps.
```

## Applying to jw-*

- **Any jw-* repo doing ML/research**: Adopt the experiment numbering + evidence
  tier + no-overclaim pattern. Every experiment gets a hypothesis, a run
  command, and an append-only result row.
- **jw-sentry**: If you benchmark collection throughput or query performance,
  number the benchmarks, record the exact conditions, and never delete a
  result row (supersede instead).
- **General**: The CONTEXT.md pattern (vocabulary, package map, claim
  boundaries, validation commands) is directly portable to any jw-* repo as
  the agent-facing source of truth.
