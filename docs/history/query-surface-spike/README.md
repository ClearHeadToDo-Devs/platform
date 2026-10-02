---
type: Fact
title: Query-surface spike — v4, raw CCO and a CCO-derived view
description: Evidence behind Decision 45. Three real queries written three ways over one workspace, with identical answers and very different readability; plus the generator for the spec fixture's CCO expected graph.
status: draft
generated: { by: agent/claude, at: 2026-10-02 }
sources:
  - id: decision
    resource: ../../DECISIONS.md
    title: Decision 45 (the application vocabulary is the graph)
  - id: fixture
    resource: ../../../specifications/examples/conformance/graph
    title: The spec's graph conformance fixture
---

# Query-surface spike (2026-10-02)

Question: is the CCO-shaped graph fit to be the surface people and agents write queries against? Three real queries (`for-human`, `index agenda`, `index unscheduled`) were written against the spec fixture's workspace, copied with the `groceries` charter Active and the fence tagged `+human` so each query has an answer.

| Query | v4 today | raw CCO | CCO-derived view |
| --- | --- | --- | --- |
| for-human | 12 | 27 | 6 |
| unscheduled | 48 | 55 | 17 |
| agenda | 50 | 53 | 17 |

Lines without comments or prefixes. All three forms return the same rows. The view is one CONSTRUCT (`view/view.rq`, 56 lines) that turns 178 CCO triples into 53. Raw CCO was barely longer than v4 but unreadable: opaque IRIs, and the closed-action check repeated three times because state is two kinds of record.

Findings:

- **Scheduled and due were indistinguishable** in the CCO mapping: same structure, differing only in a hashed IRI. Neither the shapes nor HermiT caught it. Tracked as the `scheduled-vs-due` action.
- **Times as written** make a date and a datetime incomparable in SPARQL; both forms here compare date prefixes as strings.

Outcome: Decision 45 inverts the view. A fresh-named application vocabulary becomes the queried graph, and the CCO graph is generated from it by a mapping in the ontology repository. `view/` is the starting sketch for that vocabulary, and `view/*.rq` for the rewritten saved queries.

## Files

- `run.py` — reruns the comparison (`uv run --with rdflib python docs/history/query-surface-spike/run.py`). It reads the v4 queries live, so it stops reproducing once they move to the new vocabulary.
- `v4.trig`, `v5.ttl` — the two graphs of the spike workspace.
- `raw/`, `view/` — the CCO and view versions of each query; `view/view.rq` is the CONSTRUCT.
- `gen_expected.py` — writes the spec fixture's `expected.ttl` (usage in its docstring). The working tool until the `app-to-cco` mapping generates that graph instead; delete it then.
