# RDF publication migration baseline

This inventory freezes the active `clearhead-graphd` responsibilities and
consumer contracts before the RDF publication path moves. It is a migration
baseline, not a commitment to retain every current presentation feature.

## Classification

### Canonical RDF publication

These responsibilities move to the always-available Core RDF module:

- `clearhead-core/crates/clearhead-graphd/src/graph/insert.rs`: the current DomainModel-to-RDF map,
  stable entity IRIs, workspace named graphs, domain relationships, context
  hierarchy, sequential-chain edges, datatypes, and workspace/source metadata.
- `clearhead-core/crates/clearhead-graphd/src/graph/jsonld.rs`: the compact JSON-LD contract and its
  deterministic ordering tests. This is currently a second hand-built mapping;
  it must become a serialization of the canonical dataset.
- `clearhead-core/crates/clearhead-graphd/src/resources/`: pinned context, schema, and example
  fixtures. Their authority belongs in `ontology/v4`; implementations should
  consume or verify that source rather than silently fork it.
- The bounded publication checks currently named
  `validate_actions_vocabulary`. They are custom SPARQL checks, not a SHACL
  engine, and currently cover only status, plan target typing, UUID presence,
  completion/recurrence requirements, direct self-successors, and alias
  uniqueness.

The current projection includes Charter, Plan, Action, Context, workspace, and
source-locator statements. It omits Objective statements even though Objective
is in the ontology-out scope. The RDF insertion and direct JSON-LD mappings are
not equivalent; the dataset contract must resolve that before migration.

### Optional local SPARQL

These responsibilities may move behind the CLI `sparql` feature:

- a fresh in-memory Oxigraph store per invocation
- loading each workspace snapshot into its stable named graph
- union-default evaluation for queries without `FROM` or `FROM NAMED`
- unrestricted raw and saved `SELECT`, `CONSTRUCT`, and `DESCRIBE` execution
- saved-query discovery and standard-prefix convenience
- standard SPARQL Results and RDF result serialization

Oxigraph currently has default features disabled and no persistence, endpoint,
federation, authentication, or network lifecycle. Those remain external RDF
database concerns rather than migration requirements.

### Client presentation and application policy

These are not part of canonical RDF publication:

- index-family required bindings and agenda/weekly/unscheduled/chain policies
- tree-family validation and nested JSON framing
- terminal tables, summaries, and indented trees
- NDJSON and canonical-ID convenience projections
- Graphviz DOT construction and visual edge decoration
- query-family-specific compact JSON-LD response framing
- textual placeholder substitution for status, target, and current time

They may remain only where a demonstrated client still needs them. Their
portable `.sparql` files remain ordinary query artifacts.

### Deletion candidates

The following have no demonstrated semantic-publication requirement:

- duplicate validation tests in `graph/query.rs`
- the apparently unused `build_where_query` public helper
- the apparently unused `serialize_workspace_to_jsonld` parallel path
- overlapping legacy root queries such as the two `all-plans` variants
- graph summaries, DOT, nested-tree, and custom NDJSON renderers once their
  current clients have migrated or intentionally dropped those views

Deletion still requires a tracked-reference search and replacement proof.

## Current consumers

### CLI

`clearhead-core/crates/clearhead-cli/src/graph_backend.rs` has two hard process dependencies:

1. `clearhead query` forwards inherited stdio and exit status to graphd.
2. Action, Charter, and Plan `--format json-ld` serialize a filtered
   `DomainModel` to JSON, invoke `graphd export-jsonld`, and return its UTF-8
   output.

`CLEARHEAD_GRAPHD` selects the executable. The workspace CI builds graphd alongside the CLI, and the facade tests require byte-identical stdout and exact exit
status. Removing only the query facade would still break ordinary JSON-LD
reads.

### Neovim

`clearhead.nvim` invokes graphd directly and consumes three distinct contracts:

- index JSON-LD rows with canonical IDs and source locators for quickfix and
  mutation handoff
- nested tree JSON for the work-map view
- raw DOT for graph visualization

Executable configuration, health checks, tests, and documentation refer to
`clearhead-graphd` and `CLEARHEAD_NVIM_GRAPHD_BINARY_PATH`.

### Platform composition

The platform pins graphd as a git submodule. `scripts/startup`,
`scripts/validate-pinned`, the root README, workspace configuration, graphd CI,
and CLI CI all build, install, validate, or describe it. Core, LSP, ontology,
and tree-sitter-actions contain no direct graphd process dependency.

### Shared contracts

- `specifications/ontology.md` defines graph names, query dataset behavior, and
  the canonical term cross-reference.
- `specifications/schemas/index_query_result.schema.json` covers only index JSON
  rows, not index JSON-LD, tree JSON, DOT, unrestricted SPARQL, or domain
  JSON-LD.
- `clearhead-core/crates/clearhead-graphd/docs/query_contract.md` defines the wider family and output
  conventions.
- `clearhead-core/crates/clearhead-graphd/docs/jsonld_export_contract.md` is materially stale: it
  names the wrong owning repository and differs from actual compact keys and
  `_meta` behavior.

## Known projection asymmetries

The RDF insertion path currently publishes more information than direct
JSON-LD, including Charter aliases/state/containment, Plan external identity,
template and scheduled anchor, Action plan/sequential/created data, configured
context hierarchy, and complete workspace metadata. JSON-LD publishes some
relationships under different compact terms and does not preserve the named
workspace graph identity. Context normalization also differs (`+` versus `@`).

The migration must therefore compare expanded RDF statements, not preserve the
old JSON bytes as if both paths were already equivalent.

## Baseline proof

The baseline was captured on 2026-08-18 before implementation changes:

```text
cd clearhead-graphd && cargo test
  42 unit tests
   5 dependency_graph integration tests
  16 graph_queries integration tests
  29 index_queries integration tests
   6 tree_queries integration tests
   1 doctest
  all passed

cd clearhead-cli && \
  cargo test --test query_facade --test query_to_transact
  4 tests passed
```

The migration gate is:

```sh
cargo fmt --manifest-path clearhead-core/crates/clearhead-graphd/Cargo.toml --check
cargo clippy --manifest-path clearhead-core/crates/clearhead-graphd/Cargo.toml \
  --all-targets --no-deps --locked -- -D warnings
cargo test --manifest-path clearhead-core/crates/clearhead-graphd/Cargo.toml --locked

CLEARHEAD_SPEC_DIR="$PWD/specifications" cargo test \
  --manifest-path clearhead-core/crates/clearhead-graphd/Cargo.toml --locked \
  --features spec-conformance --test spec_conformance

CLEARHEAD_GRAPHD="$PWD/clearhead-core/target/debug/clearhead-graphd" \
  cargo test --manifest-path clearhead-core/crates/clearhead-cli/Cargo.toml --locked

scripts/validate-pinned
```

Before graphd removal, active references must be re-inventoried across the root
and every submodule; CLI and Neovim tests that currently skip when graphd is
absent must be changed to require their replacement.
