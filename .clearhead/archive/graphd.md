---
id: 019f76ca-80b1-7b11-adf1-c4d0c3615af1
alias: graphd
parent: platform
state: Closed
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
- **graphd is the standalone, first-class read/query/export tool** used
  directly by humans, editors, and agents. The test of the decoupling:
  installing only graphd must support workspace discovery, saved and ad-hoc
  queries, validation, and every public output format. It self-discovers config
  via core and owns the named-query registry, SPARQL execution, query-family
  contracts, serialization, terminal rendering, stdout/stderr, and exit
  semantics. The `-d` suffix implies a daemon it is not; a resident daemon is
  deferred, not needed yet.
- **The CLI is a separate mutation and workspace-lifecycle convenience.** It
  resolves human references, invokes core's durable write path, and returns
  structured mutation outcomes. It does not forward graphd commands, inspect
  dependencies, hold SPARQL or prefixes, decode graph results, or reserialize
  query output. Dependency traversal and actionability remain inspectable
  SPARQL rather than bespoke CLI logic.
- **Clients compose the tools directly.** Neovim and agents call graphd for
  reads, the CLI for identity-addressed mutations, and the LSP for document
  intelligence. The living loop is graphd read → CLI act by canonical ID →
  graphd re-read; no tool is middleware for another.

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
shallower validated projection. graphd alone owns those bytes; clients request
an explicit stable format and map it onto their own interfaces.

## Outcome (2026-07-22)

The boundary is now explicit and dogfooded end to end:

- clearhead.nvim invokes graphd directly for index reads and uses the CLI only
  for canonical-ID mutations; the three-process living-loop test passes
- `clearhead query` and its forwarding implementation were removed; the 27
  index behavior tests moved into graphd
- `tree/work-map.sparql` ships as standard `SELECT`, validates identity/parent
  structure, and emits nested JSON or an indented terminal tree
- `graph/dependencies.sparql` ships as standard `CONSTRUCT` and emits JSON-LD,
  Turtle, or a terminal graph summary
- both proving queries run unchanged under external `roqet`; graphd's Turtle
  output was loaded and queried there as ordinary RDF
- work-map dogfood exposed and fixed charter parent resolution by alias

## Delivery order and done gate

1. move clearhead.nvim's query reads from the CLI facade to graphd and prove the
   three-tool living loop
2. remove `clearhead query` and its forwarding/format surface so the process
   boundary is explicit
3. implement `tree/work-map.sparql` as the first parent-linked `SELECT` family
   and prove the same file in external SPARQL tooling
4. implement `graph/dependencies.sparql` as the first standard `CONSTRUCT`
   family and prove its RDF output in external tooling

This charter is done when graphd independently owns all query families and
formats, the CLI contains no graph query facade or dependency reasoning, and
Neovim consumes graphd directly while mutating through canonical CLI verbs.
