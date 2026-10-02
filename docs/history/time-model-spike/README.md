---
type: Fact
title: Time-model spike — times as written, or as written plus the instants they mean
description: Evidence for the application vocabulary's time model. Fourteen awkward bounds, three real questions, two graph shapes, both SPARQL engines we rely on.
status: draft
generated: { by: agent/claude, at: 2026-10-02 }
sources:
  - id: decisions
    resource: ../../DECISIONS.md
    title: Decisions 46 (duration) and 47 (a date means the whole day)
  - id: previous
    resource: ../query-surface-spike/README.md
    title: The query-surface spike, which found scheduled and due indistinguishable
---

# Time-model spike (2026-10-02)

Question: what shape must the application graph give time so that ordinary questions are plain to write and correct on every engine?

`run.py` holds the fixture: fourteen bounds chosen to break naive comparison. They include date-only bounds (whole days, Decision 47), floating times, times with an offset that land on a different local day or hour than they read (`:2026-10-06T01:00Z` is 18:00 on the 5th in Los Angeles; `@2026-10-05T16:00+02:00` is 07:00), and durations with and without a start (Decision 46). The viewer is in `America/Los_Angeles` at 2026-10-05T14:30. Expected answers are hand-computed in the fixture table.

| Question | S1: as written only | S2: as written + instants |
| --- | --- | --- |
| agenda (starts today or earlier, or due by end of today) | 10 lines | 8 |
| overdue | 9 | 6 |
| fits (startable now, 30 minutes or less) | 13, **wrong on rdflib** | 7 |

Lines without comments or prefixes. Oxigraph is the CLI's engine; rdflib runs the external proof.

- **S1** keeps each bound as written (`xsd:date`, or `xsd:dateTime` floating or with offset). Every query branches on the datatype, glues the viewer's offset onto floating times, and compares dates as strings. The offset is one fixed value, so it is wrong across a daylight-saving change. In `fits`, rdflib does not substitute the outer `?offset` into a `BIND` inside `NOT EXISTS`, so it returns an action that cannot start yet. The engines disagree only because S1 makes the query compute.
- **S2** keeps the written value (`app:start`, `app:due`) and adds the instant each bound means: `app:notBefore` (the start; a date's first instant) and `app:lateFrom` (the first late instant; a date's next midnight). Floating times resolve in the viewer's zone, from the time-zone database, at projection. Queries compare instants and nothing else.

Findings:

- **Resolve time in the projection, not the query.** SPARQL has no time-zone database and no date arithmetic both engines share; every question S1 answers right, it answers through string tricks one engine already breaks.
- **The projection is the right place for the viewer's zone**, because the CLI projects the workspace locally for each query, so the viewer's zone is the machine's zone at query time. An exported graph fixes the exporter's zone into its floating instants, so an export should say which zone it used.
- **Inclusive start, exclusive end.** `notBefore` is the first allowed instant and `lateFrom` the first late one. This makes a whole-day date exact without a 23:59:59.999. It also maps directly onto the CCO window that `scheduled-vs-due` planned: a temporal interval whose first instant is `notBefore`. The upper end needs care, because BFO's *has last instant* is inclusive and `lateFrom` is not.
- **Recurrence adds nothing here.** A materialized occurrence (M) is an ordinary action with ordinary bounds.
- **Still open, for app-vocabulary:** effective bounds inherited from ancestors (the spec says queries use them). Either the projection emits them too, or each query walks ancestors with an aggregate.
- **SPARQL scoping trap, again:** a `FILTER` inside a `UNION` branch cannot see a `BIND` made outside it. My first S2 agenda query returned nothing because of it. Saved queries should prefer `OPTIONAL` with one `FILTER`.

## Files

- `run.py` emits `s1.ttl` and `s2.ttl` from the fixture and runs `s1/*.rq` and `s2/*.rq` on both engines (`uv run --with pyoxigraph --with rdflib python docs/history/time-model-spike/run.py`).
