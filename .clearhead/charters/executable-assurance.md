---
id: 019ff962-cac2-77b2-aa2f-fceea4697c98
alias: executable-assurance
parent: platform
objectives:
  - trustworthy-evolution
state: Active
---
# Establish Executable Assurance

ClearHead already has substantial fast unit, integration, protocol, conformance, and end-to-end coverage. The remaining trust gap is not simply a shortage of tests: assurance is unevenly distributed, some frequently executed behavior is weakly asserted, and several important seams have no executable contract.

Initial measurements in `clearhead-cli` made that distinction visible. Subprocess-aware LLVM coverage reports about 63% line coverage overall, while reference routing and template application are wholly unexecuted and charter lifecycle behavior is sparse. A partial mutation run caught roughly half of attempted viable mutants, but meaningful changes to action fields, update predicates, configuration defaults, and public rendering survived. These numbers are diagnostic inputs, not delivery targets.

This charter establishes the smallest reusable assurance system that protects the platform's important invariants without turning coverage work into an indefinite parallel project.

## Outcomes

1. Coverage and mutation reports are reproducible and interpreted consistently.
2. Current high-risk identity and mutation gaps have compact semantic contracts.
3. Test workspaces and conformance cases can be reused without coupling repository release cycles.
4. Property testing protects a small initial set of genuine domain invariants.
5. One command can validate the exact pinned platform composition at an appropriate depth.
6. Future feature charters have a clear pattern for selecting and recording their own evidence.

## Scope

The initial implementation focuses on behavior where a defect can change durable meaning or route work incorrectly:

- canonical reference resolution across actions, plans, charters, and workspaces;
- action, charter, and plan lifecycle mutations, including dry-run and failure atomicity;
- template instantiation and target selection;
- configuration values that cross into Core behavior;
- public machine and human rendering contracts where downstream consumers depend on exact shape;
- parser/formatter, mutation-locality, identity, recurrence, and durability invariants;
- agreement among specification fixtures, producers, and consumers.

The current CLI measurements provide the first prioritized inventory, but shared mechanisms should live at the narrowest owning layer and serve other repositories when a real contract crosses their boundary.

## Assurance layers

- **Per change:** formatting, linting, unit tests, focused integration tests, and changed-contract conformance checks.
- **Scheduled:** broader property runs, mutation sampling, fixture-drift checks, and platform composition validation.
- **Release:** pinned cross-repository workflow, schema/protocol conformance, and explicit review of unresolved critical findings.

## Non-goals

- maximizing a global coverage percentage;
- killing every generated mutant;
- replacing named regressions and readable examples with generated cases;
- centralizing every repository's tests in the platform repository;
- introducing shared test infrastructure before at least two consumers need it;
- refactoring large modules merely to improve test metrics;
- blocking feature delivery on low-risk display, debug, or defensive branches.

## Done gate

This charter may close when:

- subprocess-aware coverage and focused mutation commands are documented and reproducible;
- surviving mutants are classifiable by criticality and disposition rather than presented as an undifferentiated count;
- resolver, template, and the highest-risk action/charter/plan mutation paths have semantic regression coverage;
- one reusable workspace builder or fixture pattern demonstrably reduces setup duplication;
- a canonical conformance case is exercised by at least two owning layers without making either repository depend on a sibling checkout at runtime;
- an initial set of Core properties protects round-trip, mutation-locality, identity, recurrence, or durability invariants;
- the pinned platform has one validation entry point with documented fast, scheduled, and release depths;
- the approach and residual risks are documented well enough for later feature charters to apply it without reopening this charter.
