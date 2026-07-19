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

graphd emits JSON-LD as its semantic contract; the query output specification
governs that layer, where meaning travels with the data and consumers opt out
of depth rather than into it. CLI presentation is a client concern with two
orthogonal axes:

- **Shape picks the structured format** — the data's topology drives its
  serialization, and each named query declares its shape:
  - list (unscheduled, agenda, overdue) becomes NDJSON, one record per line
  - tree (charter-to-action hierarchy) becomes nested JSON
  - graph (dependencies, contexts, federation) becomes triples / JSON-LD
- **Destination picks render versus emit** — a terminal renders the human view
  (table, indented tree, graph summary); a pipe emits the shape's structured
  format. Explicit format flags override both axes.
