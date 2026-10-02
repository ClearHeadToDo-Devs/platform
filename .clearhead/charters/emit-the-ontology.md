---
id: 01a0faa1-ca17-72a9-8a6b-f05b6bd6dbd3
alias: emit-the-ontology
parent: platform
objectives: [data-integration]
state: Active
---
# Emit the Grounded Ontology

Core projects every workspace to the ontology's standard terms (CCO v2.2 and IAO, `ontology/docs/domain.md`), and the v4 vocabulary goes. That projection is the core code change; the specification says what it must produce, and the CLI's queries follow it. Decided in platform Decision 43; follows [[ground-the-ontology]].

## Done when

Re-planned 2026-10-02 by Decision 45: the application vocabulary is the graph; CCO is its meaning.

- The specification defines the application vocabulary, with its shapes and the fixture's exact `expected-app.ttl`; `ontology.md` describes the application graph first.
- The ontology repository maps the application vocabulary to CCO, and the mapping of `expected-app.ttl` is `expected.ttl`, which passes the CCO shapes, HermiT and the verify rules, in the pinned gate.
- Objectives are in Core's domain model: charters link to objective files, `init` seeds the root objective, and `doctor` reports a charter with none. (Done.)
- Core emits the application graph and matches `expected-app.ttl`.
- Every saved CLI query, and the workspace's own (`for-human`), answers from the application graph with the same rows as before.
- v4 is gone: namespace constants, Core fixtures, the ontology's `v4/` and its pytest suite.

## Sequence

Fix scheduled versus due in the mapping first, since the application vocabulary will say both and the mapping must not lose the difference. Then the vocabulary, then its mapping, then Core, then the queries, then removing v4.

## Log

- 2026-10-01 — Created New from ground-the-ontology, once the human confirmed Decision 43. Absorbs implement-objectives: V5 has no plan without an objective, so objectives in the model are a step of this work, not a separate stream.
- 2026-10-02 — Re-planned by Decision 45 after the query-surface spike (same answers three ways; view queries about a third of v4's length). The application vocabulary becomes the queried, exported graph with file and line; the ontology becomes its mapping to CCO; a CCO export is optional. nvim-locate cancelled. Found a mapping bug: scheduled and due were indistinguishable.
