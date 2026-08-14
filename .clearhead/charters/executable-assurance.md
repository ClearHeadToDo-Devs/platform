---
id: 019ff962-cac2-77b2-aa2f-fceea4697c98
alias: executable-assurance
parent: platform
objectives:
  - trustworthy-evolution
state: Active
---
# Establish Executable Assurance

ClearHead already has substantial unit, integration, protocol, conformance, and end-to-end coverage. The present trust gap is narrower: several high-consequence behaviors are either unexecuted or weakly asserted, especially reference routing, template targeting, and durable lifecycle mutations.

Coverage and mutation analysis made those gaps visible, but they are diagnostic tools rather than outcomes or permanent workstreams. This charter protects a fixed set of currently known critical seams, keeps only the support that proves useful while doing so, and then closes.

## Outcomes

1. The known critical identity, targeting, and lifecycle gaps have compact semantic regression coverage.
2. Reusable test support is retained only where it makes real tests clearer or serves more than one genuine consumer.
3. The exact pinned platform composition has one practical validation entry point.
4. Useful techniques, unresolved risks, and follow-up triggers are recorded from experience rather than designed in advance.

## Fixed scope

The remediation inventory for this charter is limited to:

- canonical reference routing across actions, plans, charters, and workspaces;
- template instantiation and target selection;
- the highest-risk action, charter, and plan lifecycle mutations revealed by the existing coverage and mutation investigation, including dry-run and failure atomicity;
- configuration or rendering behavior only when it directly participates in one of those paths;
- one validation of the exact submodule composition pinned by the platform repository.

Newly discovered defects may be fixed when they are small and directly adjacent. Larger or unrelated gaps are recorded for their owning feature or maintenance charter instead of expanding this charter indefinitely.

## Working approach

- First ask whether the behavior, state space, or ownership boundary can be simplified.
- Prefer reload-and-compare semantic contracts over assertions about incidental implementation details.
- Use coverage, mutation, properties, fixtures, and end-to-end tests only where each is the cheapest adequate technique.
- Tolerate local test duplication until a stable shared semantic abstraction makes at least two real consumers clearer.
- Do not refactor production code solely to improve a metric or accommodate a generalized test framework.
- Record a brief rationale when a consequential finding is deliberately left unresolved; introduce more structure only if the volume of findings makes it necessary.

## Evidence landed

- The first focused generator constructs valid Action forests with unique identities, bounded hierarchy, coherent timestamps, references, links, and every DSL-backed optional field. Five properties exercise 256 generated cases each for semantic round trips, formatter idempotence, link/literal boundaries, and subtree-closing locality.
- Those subtree properties replaced five narrow lifecycle examples while preserving stronger assertions over membership, order, source immutability, root detachment, descendant hierarchy, and both terminal states.
- Mutation analysis left no known surviving mutant in the exercised lifecycle and parser/formatter slices; two infinite-loop mutations were rejected by timeout.
- Generated combinations exposed and repaired omitted creation-date rendering, malformed-link preservation in non-link fields, and an escaped terminal-backslash ambiguity. Exact parser fixtures remain for the byte-level compatibility boundary.

## Non-goals

- defining a comprehensive assurance taxonomy or governance process;
- maximizing coverage or mutation scores;
- killing every generated mutant;
- building generalized property generators, fixture frameworks, or shared test packages without demonstrated demand;
- centralizing repository-owned tests in the platform repository;
- creating elaborate reporting, artifact-retention, or validation-depth machinery;
- turning newly discovered low-risk gaps into an indefinite testing backlog.

## Done gate

This charter may close when:

- the fixed reference-routing, template-targeting, and lifecycle inventory has focused semantic protection or an explicit residual-risk note;
- commands that materially helped find weak contracts are reproducible enough to run again, without requiring a permanent reporting system;
- any retained builder, property, or conformance fixture has demonstrated its value in the tests that use it;
- one command validates the pinned platform composition at a practical depth;
- remaining risks and concrete promotion triggers for future work are documented.
