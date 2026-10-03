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

## Current status, 2026-10-03 (handoff)

The meaning side is done: the mapping exists and the gate enforces it. The time model is settled and implemented end to end (Decisions 47, 48, 51): `:` is the world's window and `@` is intent, both ISO 8601 `start/end` ranges, half-open; a date covers its day and a time is an instant, in both fields alike. Duration is the `@` block's length. Core has `domain::time::{Bound, Due, Planned}`; calendar sync carries the block only (VEVENT `DTEND`, VTODO `DURATION`) and never the window.

**Next, in order:**
1. `v5-projection`: Core emits `expected-app.ttl` (now with `app:plannedStart`, `app:plannedEnd` and a derived `app:durationMinutes`).
2. `window-lints` (E008, including an empty `@` block, and W015) whenever convenient; it is small.
3. `migrate-iris` (to `clearhead.dev`, Decision 49), then the `deployment` charter's `spec-site` and `spec-release-0-2`; `fold-ontology` after `retire-v4`.

**Know before starting:** the installed `clearhead` is current (reinstalled 2026-10-03); ROBOT 1.9.10 is in `~/.local/bin`, so `scripts/check-graph-shapes.py` runs fully on the desktop. The pinned gate's graph checks, Core conformance and the grammar gate pass; the full `validate-pinned` was not re-run end to end.

## Log

- 2026-10-01 — Created New from ground-the-ontology, once the human confirmed Decision 43. Absorbs implement-objectives: V5 has no plan without an objective, so objectives in the model are a step of this work, not a separate stream.
- 2026-10-02 — Re-planned by Decision 45 after the query-surface spike (same answers three ways; view queries about a third of v4's length). The application vocabulary becomes the queried, exported graph with file and line; the ontology becomes its mapping to CCO; a CCO export is optional. nvim-locate cancelled. Found a mapping bug: scheduled and due were indistinguishable.
- 2026-10-03 — intent-range done (Decision 51, amended twice the same day): a time end of `@` is the instant written, then a time is an instant in `:` too, so the same text means the same interval in both fields; deadlines stay off the calendar. Spec, examples, grammar, Core and calendar landed; do-bound folded in. Found a pre-existing duplicate on calendar import (support).
- 2026-10-03 — app-to-cco done: the mapping lives in the specification (Decision 50) as one CONSTRUCT per structure, reads the effective terms (waitsOn, notBefore, lateFrom), gives helper nodes no names (Decision 49), maps @ to a Prescriptive ICE (no act before the work starts), and says "not before" or "late from" on each time condition. Metric review_date removed. Decision 51 replaced the planned duration sigil with a range on @.
