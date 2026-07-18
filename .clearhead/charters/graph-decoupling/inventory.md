# Graph Decoupling Inventory

_Date: 2026-07-17_

This note records the current graph/Oxigraph surface after the first CLI seam extraction.

## Summary

The first useful extraction has landed in `clearhead-cli`: command handlers no longer call `clearhead_core::graph` directly. They now go through `clearhead-cli/src/graph_backend.rs`, which is the single in-process graph runtime seam to replace with `clearhead-graphd`.

That means the remaining work is now much more legible:

1. keep narrowing the CLI to that seam
2. introduce `clearhead-graphd` as the implementation behind it
3. move graph-specific shaping/serialization behind the daemon
4. remove the Oxigraph dependency from CLI, then from core when the graph module is no longer used in-process

## Current ownership

### `clearhead-core`

`clearhead-core` still owns the entire in-process graph implementation today:

- `Cargo.toml` — direct `oxigraph = "0.5.3"` dependency
- `src/graph/insert.rs` — load `DomainModel` and workspace metadata into RDF
- `src/graph/query.rs` — SPARQL execution and helper query construction
- `src/graph/serialize.rs` — Turtle serialization helpers
- `src/graph/shape.rs` — index framing / contract validation
- `src/graph/jsonld.rs` — JSON-LD serialization
- `src/graph/mod.rs` — graph API surface and Oxigraph type re-exports
- `src/lib.rs` — `pub mod graph`

Important observation: the graph code is already relatively well-contained inside `src/graph/`. The main decoupling pressure is therefore not “find graph code everywhere” but “stop other crates from depending on that module directly at runtime.”

### `clearhead-cli`

`clearhead-cli` still depends on Oxigraph today (`Cargo.toml`), but command handlers have been narrowed to a single backend module:

- `src/graph_backend.rs`
  - workspace loading into store
  - additional-workspace merge
  - raw query execution
  - raw-WHERE helper
  - index framing pass-through
  - JSON-LD serialization pass-through

Direct command-layer usage now routes through that seam:

- `src/commands/query.rs`
  - `query run`
  - named queries
  - index queries
  - chain query
- `src/commands/action.rs`
  - JSON-LD action output
- `src/commands/charter.rs`
  - JSON-LD charter output
- `src/lib.rs`
  - re-exports the backend surface

## Findings

## 1. The first seam should be the CLI/backend boundary, not core internals

The cleanest first move is exactly what was just done: stop scattering `clearhead_core::graph::*` calls through command handlers.

That lets `clearhead-graphd` replace one backend module instead of many command sites.

## 2. Query execution is the real first consumer

The graph charter says views/queries belong to the graph binary, and the code agrees. The most direct graph-specific runtime path is:

- load workspace(s)
- build graph store
- run SPARQL
- emit rows / shaped index output

So the first graphd slice should target query execution, not every graph-adjacent feature at once.

## 3. JSON-LD and index framing are graph-adjacent, but not necessarily Oxigraph-bound

Two pieces still live under `clearhead_core::graph` even though they are not query execution itself:

- `shape.rs` — `frame_index`
- `jsonld.rs` — `serialize_domain_to_jsonld`

These can go either way:

- stay library-side, but move out of `graph/` into a more neutral application/output layer
- or move behind graphd if we want “all graph-shaped output” owned by the daemon

They do **not** block the first query-runtime extraction, but they do block the final “no graph module in normal CLI flow” endpoint.

## 4. Core is already close to a split point

Because graph functionality is largely isolated under `clearhead-core/src/graph/`, there are two plausible end states:

- **A.** `clearhead-graphd` depends on `clearhead-core` and keeps using `clearhead_core::graph` internally for a while
- **B.** graph code moves to a dedicated crate later (`clearhead-graph` / `clearhead-graphd` library)

The first slice should choose **A**. It is cheaper and still satisfies the architectural seam the charter wants: the CLI no longer embeds graph execution.

## 5. The contract question is smaller than “RPC protocol”

If `clearhead-graphd` is first shipped as a one-shot binary, the boundary is just:

- CLI args / env / stdin in
- JSON / table-ready payloads / exit codes out

So the immediate contract to define is not a daemon protocol; it is the **invocation and output contract** for shelling out without changing user-visible results.

## Recommended transition sequence

1. keep `clearhead-cli/src/graph_backend.rs` as the only graph runtime entrypoint in CLI
2. define the minimal `clearhead-graphd` command contract for raw query execution
3. implement one-shot workspace load + query execution in `clearhead-graphd` using existing library functionality
4. switch `query run` first
5. switch named/index/chain queries next
6. decide whether `frame_index` and JSON-LD belong in graphd or in a non-graph output layer
7. once command handlers no longer embed graph execution, remove Oxigraph from `clearhead-cli`
8. only then decide whether `clearhead-core` graph code remains as a library dependency of graphd or moves to its own crate

## Concrete remaining surface

### Still graph-runtime in CLI

- `clearhead-cli/src/graph_backend.rs`

### Still graph-owned in core

- `clearhead-core/src/graph/mod.rs`
- `clearhead-core/src/graph/insert.rs`
- `clearhead-core/src/graph/query.rs`
- `clearhead-core/src/graph/serialize.rs`
- `clearhead-core/src/graph/shape.rs`
- `clearhead-core/src/graph/jsonld.rs`
- `clearhead-core/Cargo.toml` (`oxigraph`)

### Already removed from direct CLI command usage

- direct `clearhead_core::graph::*` calls in `src/commands/query.rs`
- direct JSON-LD serialization calls in `src/commands/action.rs`
- direct JSON-LD serialization calls in `src/commands/charter.rs`

## Bottom line

The meaningful boundary is now visible:

- **CLI command layer** → should talk to a graph backend surface
- **graph backend surface** → can be swapped from in-process library calls to `clearhead-graphd`
- **workspace/domain library** → remains shared plumbing

So the next step is not a grand refactor. It is a thin replacement of the implementation behind that backend seam.
