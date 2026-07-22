---
id: 019f76ca-80b1-7b11-adf1-c4d0c3615af1
alias: graphd
parent: platform
---
# graphd query ownership and export boundary

The graph/LSP decoupling moved graph execution out of core into a separate
`clearhead-graphd`. This charter finishes what that started: making the pieces
genuinely independent tools rather than a mechanical binary implicitly coupled
to the CLI.

## Target architecture

- **Core is the shared substrate.** Workspace loading, the telemetry NDJSON
  emitter, and config loading (the source/precedence stack) all live in core so
  the CLI, LSP, and graphd share one implementation and extend with their own
  fields where needed. Core's older "no I/O / never reads config.json / concrete
  impls live downstream" comments were written for graph-in-core and no longer
  hold.
- **graphd is a standalone, first-class tool** usable directly by humans and
  agents, not just the CLI. The test of the decoupling: installing only graphd
  must work. It self-discovers config via core, owns the named-query registry,
  and owns its output modes behind a clean argument interface. The current
  stdin JSON-envelope-with-embedded-SPARQL is a coupling smell to remove. The
  `-d` suffix implies a daemon it is not; a resident daemon is deferred, not
  needed yet.
- **The CLI is a projection** over graphd's public interface — the same one
  humans and agents use, not a private protocol. It never parses graph formats
  and holds no SPARQL or prefixes.

## Output model

graphd owns the semantic representation and the query-family contracts. A
family is a consumer guarantee around ordinary, standalone SPARQL—not a custom
query language or per-query metadata schema. A query opts in by living under
`queries/index/`, `queries/tree/`, or `queries/graph/`; it remains runnable
unchanged in other SPARQL tooling.

- **Family picks the structured format and validation profile:**
  - index queries are ordered `SELECT` results with canonical identity,
    display, and locator bindings; they become NDJSON for a machine
  - tree queries are ordered `SELECT` results with identity and a parent edge;
    they become nested JSON
  - graph queries are standard `CONSTRUCT` queries; they become JSON-LD or
    another RDF serialization
  - unrestricted named/raw `SELECT` queries return their projected rows;
    aggregates are rows, not a fourth family
- **Destination picks render versus emit** — a terminal renders the human view
  (table, indented tree, graph summary); a pipe emits the family's structured
  format. Explicit format flags override both axes.

JSON-LD remains the semantic/federation boundary where meaning travels with the
data, but it is not mandatory stdout for consumers that deliberately choose a
shallower validated projection. The CLI forwards graphd's public interface and
never parses SPARQL or graph formats.
