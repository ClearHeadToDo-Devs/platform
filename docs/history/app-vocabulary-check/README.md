---
type: Fact
title: App-vocabulary check — the draft app: terms against today's answers
description: The query-surface spike's three queries rewritten in the draft application vocabulary, run on the spec fixture's expected-app.ttl and compared with the shipping v4 CLI on the same workspace.
status: draft
generated: { by: agent/claude, at: 2026-10-02 }
sources:
  - id: fixture
    resource: ../../../specifications/examples/conformance/graph
    title: The spec's graph conformance fixture (expected-app.ttl)
  - id: spike
    resource: ../query-surface-spike/README.md
    title: The query-surface spike these queries come from
---

# App-vocabulary check (2026-10-02)

Question: does the draft `app:` vocabulary answer real queries as v4 does today, and more simply?

| Query | v4 | app: |
| --- | --- | --- |
| for-human | 12 lines | 6 |
| unscheduled | 48 | 10 |
| agenda | 50 | 13 |

Same answers on Oxigraph and rdflib. `unscheduled` and `agenda` no longer climb ancestors: the effective window (`notBefore`, `lateFrom`) and effective waits (`waitsOn`) are derived by the projection (Decision 47).

Findings:

- **The fixture now tests inheritance.** Five lines were added to its `next.actions`: a child inheriting its parent's wait, one inheriting a due date, one narrowing it. Before them, every query returned one row and no derived term was ever exercised.
- **v4's agenda ignores inherited dates.** It reads only an action's own `@` and `:`; the spec says queries use the effective window. *Bake the cake*, whose parent is due today, is missing from v4's agenda and present in `app:`'s. The runner records this as a known v4 miss rather than hiding it. v4's `unscheduled` does inherit, and agrees.
- **The CCO graph states no inheritance.** `expected.ttl` gives each action only its own bounds and waits. Whether inherited waits and windows map to CCO conditions on each child (true, but redundant) is open for `app-to-cco`.
- **Conformance needs a stated zone.** A floating time's `notBefore` depends on the viewer's zone, so `expected-app.ttl` is written for UTC.

## Files

- `app/*.rq` — the three queries in `app:` terms.
- `run.py` — copies the fixture workspace to a scratch directory, applies the spike's two changes (groceries Active, the fence tagged `+human`), asks the installed `clearhead` (v4) and both engines over `expected-app.ttl`, and compares (`uv run --with pyoxigraph --with rdflib python docs/history/app-vocabulary-check/run.py`).
