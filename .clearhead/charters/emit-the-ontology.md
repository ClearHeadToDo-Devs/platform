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

- The specification maps every DSL, charter and objective field to its pattern in the ontology, with SHACL shapes for the output and a fixture (a workspace and its expected graph) that any implementation is checked against.
- Objectives are in Core's domain model: charters link to objective files, `init` seeds the root charter one, and `doctor` reports a charter with none.
- Core emits only the new graph. It passes the specification's shapes and is consistent under HermiT with the ontology.
- Every saved CLI query, and the workspace's own (`for-human`), answers from the new graph with the same rows as before.
- v4 is gone: namespace constants, Core fixtures, the ontology's `v4/` and its pytest suite; the specification's `ontology.md` points at the ontology's `docs/domain.md`.

## Sequence

Specification first (mapping, then shapes and fixture), objectives alongside it; then Core's projection; then the queries; then removing v4. The mapping is where the remaining design lives, so nothing in Core starts before it is settled.

## Log

- 2026-10-01 — Created New from ground-the-ontology, once the human confirmed Decision 43. Absorbs implement-objectives: V5 has no plan without an objective, so objectives in the model are a step of this work, not a separate stream.
