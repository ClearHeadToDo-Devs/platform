---
alias: graph-federation
state: New
description: Prove the cross-application graph vision with an importer over real data and one killer cross-domain query — then write the publishing convention that makes a second application possible
---

# Graph Federation

The five-year answer to "why the ontology": queries that **span applications
without pairwise integration**. A fitness app, a calendar, a task system —
each publishes into the personal graph under shared semantic commitments, and
the join happens in SPARQL, not in an API contract between apps.

Stated precisely: RDF doesn't eliminate integration, it changes its shape —
from N×N pairwise APIs to N×1 agreement on a shared semantic layer. The
product of this charter is therefore not the store (it exists); it is the
**publishing convention** and the **proof that the join is worth it**.

## The tangibility problem

This is the platform's load-bearing bet, and today it is evidence-free: no
second graph exists, so no cross-domain query has ever run. The ontology pays
rent through alignment sweeps and JSON-LD contract maintenance while its
defining capability remains hypothetical. The fix is not to build a fitness
app — it is an **importer over data that already exists** (sleep tracker
export, Apple Health / Garmin, git history, or the platform's own telemetry
NDJSON that nothing currently reads).

## The killer query

The demo the whole vision stands on, or something like it:

> completion throughput on days with under six hours of sleep, by context

No pairwise integration answers that. SQLite doesn't answer it without
hand-building the join schema — which is exactly the point being proven.
Importing data *we didn't design* is also the first honest stress test of the
ontology alignment.

## The pod contract (not a dumping ground)

A pile of triples where graphs "find what they need" degrades into the mess
RDF critics predict. Federation works because the pile has a contract:

- one **named graph per source**, stable graph URIs
- stable entity URIs and a declared vocabulary per source
- **provenance**: what produced this graph, when, from what upstream
- where the files live and how mounting works (extends `additional_workspaces`)

Prior art to study by name: **Solid** — this is a Solid pod rebuilt on
local-first files. Its cautionary lesson is sequencing: Solid led with
protocol and identity and never shipped the app that made pods worth having.
We invert: killer app first, the convention written only when the importer
forces its questions (health data forces time-alignment; git/telemetry force
identity).

## Promotion trigger

Promote when [[core-seam]] is done (the write path must be trustworthy before
new data flows in) and the ontology's next alignment sweep would otherwise be
speculative — the importer should be that sweep's justification.

## First actions on promotion

1. choose the first dataset — sleep/health export vs git+telemetry — and
   record the choice and why in DECISIONS.md
2. write the importer mapping the export into triples in its own named graph
3. run and publish the killer cross-domain query as a saved query-system view
4. write the publishing-convention spec in the specifications repo from what
   the importer forced, not before
