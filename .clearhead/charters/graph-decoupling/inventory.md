# Graph Decoupling Inventory

_Date: 2026-07-17_

## Final ownership

The graph extraction is complete.

### `clearhead-core`

Core is graph-neutral. It owns domain and workspace plumbing only:

- no `src/graph/` module
- no Oxigraph dependency
- no RDF, SPARQL, Turtle, shape-framing, or JSON-LD resources/tests
- public domain/workspace types remain the integration contract consumed by
  graphd

Both `clearhead-core` and `clearhead-cli` dependency trees are Oxigraph-free.

### `clearhead-graphd`

Graphd encapsulates the graph dependency and all graph-specific functionality:

- `src/graph/insert.rs` — domain/workspace model to RDF
- `src/graph/query.rs` — SPARQL execution and validation
- `src/graph/serialize.rs` — Turtle serialization
- `src/graph/shape.rs` — query response contracts and index JSON-LD framing
- `src/graph/jsonld.rs` — canonical JSON-LD export
- `src/graph/mod.rs` — graph API and Oxigraph types
- `src/resources/` — JSON-LD context, schema, and canonical example
- `tests/graph_queries.rs` — fixture-backed query behavior previously owned by
  core
- `src/lib.rs` — graphd-owned library surface used by the binary
- `src/main.rs` — one-shot JSON process contract

Oxigraph now appears only under `clearhead-graphd` in the platform dependency
trees.

### `clearhead-cli`

The CLI remains a graph client:

- `src/graph_backend.rs` is an out-of-process JSON adapter
- raw, named, index, and chain queries invoke graphd
- plain row results are JSON
- index contract validation and JSON-LD framing happen in graphd
- action/charter JSON-LD export sends a JSON `DomainModel` to graphd
- the CLI renders tables and other human-facing output without graph libraries

## Boundary discovered during the move

One core-internal helper, `resolve_workspace_layout`, had been used by graph
insertion to derive `charterRoot`. The extracted implementation now uses core's
public `charter_root` API instead. No private core API had to be exposed for the
move.

The JSON `DomainModel` handoff remains an intentionally internal process
contract. It lets the CLI perform ordinary filtering while graphd alone owns
linked-data serialization. If the process protocol becomes independently
versioned or remotely addressable later, that payload should receive an
explicit wire schema rather than silently inheriting every serde change.

## Tests moved with ownership

- graph module unit tests and schema conformance tests run in graphd
- fixture-backed SPARQL integration tests run in graphd
- core's full domain/workspace suite runs without graph dependencies
- CLI query tests exercise the graphd process seam

## Bottom line

The architecture now matches the charter:

- workspace files are truth
- core parses and models them without a graph database
- graphd builds a disposable semantic read model
- CLI and future clients speak JSON to graphd
- graphd alone owns graph execution and linked-data output
