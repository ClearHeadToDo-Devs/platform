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
- The specification maps the application vocabulary to CCO (`specifications/ontology/mapping/`, Decision 50), and the mapping of `expected-app.ttl` is `expected.ttl`, which passes the CCO shapes, HermiT and the verify rules, in the pinned gate. (Done 2026-10-03.)
- Objectives are in Core's domain model: charters link to objective files, `init` seeds the root objective, and `doctor` reports a charter with none. (Done.)
- Core emits the application graph and matches `expected-app.ttl`.
- Every saved CLI query, and the workspace's own (`for-human`), answers from the application graph with the same rows as before.
- v4 is gone: namespace constants, Core fixtures, the ontology's `v4/` and its pytest suite.

## Sequence

Fix scheduled versus due in the mapping first, since the application vocabulary will say both and the mapping must not lose the difference. Then the vocabulary, then its mapping, then Core, then the queries, then removing v4. Core does not depend on the mapping (it emits only the application graph, and the fixture is their contract), but the mapping goes first by choice: it can still change the vocabulary, and it is the executable test of the design (2026-10-02).

## Current status, 2026-10-04, evening (handoff)

The meaning side is done: the mapping exists and the gate enforces it. The time model is settled (Decisions 47, 48, 51, 52): `:` is the window and `@` is intent, both half-open `start/end` ranges; a date covers its day and a time is an instant. A `Bound` is its written form (local time, an offset only if written, precision) and resolves in the viewer's zone per RFC 5545, so files never change with the machine.

Core emits the application graph (`rdf::app::project_app`, matching `expected-app.ttl`) and it is the only projection: the CLI's SPARQL dataset, every saved query, export and JSON-LD reads use it (Decision 53), and v4 is gone from Core, the CLI, the ontology repository and the specification (`retire-v4`).

**Next, in order:**
1. `fold-ontology`: the ontology repository now holds only `v5/` and `docs/`; move them into `specifications/ontology/` with history and drop the submodule.
2. Keep created and closed times as written; `objective-actions-view`; `window-lints` whenever convenient.
3. `migrate-iris` (to `clearhead.dev`), then `deployment`'s `spec-site` and `spec-release-0-2` (the index schema change ships there).

## Log

- 2026-10-01 — Created New from ground-the-ontology, once the human confirmed Decision 43. Absorbs implement-objectives: V5 has no plan without an objective, so objectives in the model are a step of this work, not a separate stream.
- 2026-10-02 — Re-planned by Decision 45 after the query-surface spike (same answers three ways; view queries about a third of v4's length). The application vocabulary becomes the queried, exported graph with file and line; the ontology becomes its mapping to CCO; a CCO export is optional. nvim-locate cancelled. Found a mapping bug: scheduled and due were indistinguishable.
- 2026-10-03 — intent-range done (Decision 51, amended twice the same day): a time end of `@` is the instant written, then a time is an instant in `:` too, so the same text means the same interval in both fields; deadlines stay off the calendar. Spec, examples, grammar, Core and calendar landed; do-bound folded in. Found a pre-existing duplicate on calendar import (support).
- 2026-10-03 — app-to-cco done: the mapping lives in the specification (Decision 50) as one CONSTRUCT per structure, reads the effective terms (waitsOn, notBefore, lateFrom), gives helper nodes no names (Decision 49), maps @ to a Prescriptive ICE (no act before the work starts), and says "not before" or "late from" on each time condition. Metric review_date removed. Decision 51 replaced the planned duration sigil with a range on @.
- 2026-10-04 — v5-projection done: the app graph projects from Core and matches expected-app.ttl. Found on the way and fixed first: Bound lost written offsets and did not round-trip in the hour clocks go back, and a time with an offset but no seconds, or in the spring-forward gap, failed to parse and format dropped the field (Decision 52).
- 2026-10-04 — v5-queries done (Decision 53): queries read the app graph. A snapshot of every query on four workspaces matched except where Decision 53 changes rows; the human chose data_root rows, app:plannedFrom, as-written row dates, local day bounds, and retiring the plan queries until recurrence. Found: charters load in a random order (support).
- 2026-10-04 — retire-v4 done: the v4 projection, ws: layer and namespace constants left Core; the ontology repository dropped v4, the clearhead.us site and worker (the domain lapsed) and its Python tooling; the interop proof takes rdflib from uv.
