---
id: 01a0faa1-ca17-72a9-8a6b-f05b6bd6dbd3
alias: emit-the-ontology
parent: platform
objectives: [data-integration]
state: Blocked
---
# Emit the Grounded Ontology

> **Paused 2026-11-14 (Darrion):** waits while semantic merge, the calendar and templates get over the line; together they make the system ClearHead has to be first. State is Blocked because charters have no paused state.

Core projects every workspace to the ontology's standard terms (CCO v2.2 and IAO, `ontology/docs/domain.md`), and the v4 vocabulary goes. That projection is the core code change; the specification says what it must produce, and the CLI's queries follow it. Decided in platform Decision 43; follows [[ground-the-ontology]].

## Done when

Re-planned 2026-10-02 by Decision 45: the application vocabulary is the graph; CCO is its meaning.

- The specification defines the application vocabulary, with its shapes and the fixture's exact `expected-app.ttl`; `ontology.md` describes the application graph first.
- The specification maps the application vocabulary to CCO (`specifications/ontology/mapping/`, Decision 50), and the mapping of `expected-app.ttl` is `expected.ttl`, which passes the CCO shapes, HermiT and the verify rules, in the pinned gate. (Done 2026-10-03.)
- Objectives are in Core's domain model: charters link to objective files, `init` seeds the root objective, and `doctor` reports a charter with none. (Done.)
- Core emits the application graph and matches `expected-app.ttl`.
- Every saved CLI query, and the workspace's own (`for-human`), answers from the application graph with the same rows as before.
- v4 is gone: namespace constants, Core fixtures, the ontology's `v4/` and its pytest suite.

## Sequence

Fix scheduled versus due in the mapping first, since the application vocabulary will say both and the mapping must not lose the difference. Then the vocabulary, then its mapping, then Core, then the queries, then removing v4. Core does not depend on the mapping (it emits only the application graph, and the fixture is their contract), but the mapping goes first by choice: it can still change the vocabulary, and it is the executable test of the design (2026-10-02).

## Current status, 2026-10-04, evening (handoff)

The meaning side is done: the mapping exists and the gate enforces it. The time model is settled (Decisions 47, 48, 51, 52): `:` is the window and `@` is intent, both half-open `start/end` ranges; a date covers its day and a time is an instant. A `Bound` is its written form (local time, an offset only if written, precision) and resolves in the viewer's zone per RFC 5545, so files never change with the machine.

Core emits the application graph (`rdf::app::project_app`, matching `expected-app.ttl`) and it is the only projection: the CLI's SPARQL dataset, every saved query, export and JSON-LD reads use it (Decision 53), and v4 is gone (`retire-v4`). The ontology now lives in `specifications/ontology/` (`fold-ontology`).

The specification is published at `clearhead.dev` as v0.2.0 (2026-10-05), so the names in the graph resolve.

**Next:** `objective-actions-view`; `window-lints` whenever convenient.
