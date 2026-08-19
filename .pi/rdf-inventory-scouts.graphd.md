# Code Context

## Files Retrieved

1. `clearhead-graphd/Cargo.toml` (lines 1-39) — package/bin, dependencies, in-memory Oxigraph choice, optional spec-conformance feature.
2. `clearhead-graphd/src/lib.rs` (lines 1-9) — public crate boundary (`graph`, `query`).
3. `clearhead-graphd/src/main.rs` (lines 7-161) — complete binary command surface and stdin JSON→JSON-LD route.
4. `clearhead-graphd/src/query.rs` (lines 1-836) — store assembly, saved-query discovery, query families, parameter injection, and all renderers.
5. `clearhead-graphd/src/graph/mod.rs` (lines 1-245) — named-graph architecture, ontology constants, exports, errors, in-memory store.
6. `clearhead-graphd/src/graph/insert.rs` (lines 1-658; tests 659-1155) — domain/workspace→RDF projection and projection tests.
7. `clearhead-graphd/src/graph/jsonld.rs` (lines 1-389; tests 390-560) — direct canonical JSON-LD construction, workspace enrichment, schema tests.
8. `clearhead-graphd/src/graph/query.rs` (lines 1-306; tests 307-717) — SPARQL execution, union-default behavior, graph results, vocabulary/shape-like validation.
9. `clearhead-graphd/src/graph/shape.rs` (lines 1-206; tests 207-332) — index/tree response contracts and framing.
10. `clearhead-graphd/src/graph/dot.rs` (lines 1-194; tests 195-233) — RDF CONSTRUCT result→Graphviz DOT presentation.
11. `clearhead-graphd/src/queries/` (all 19 `.sparql` files) — built-in index/tree/graph and unrestricted saved queries.
12. `clearhead-graphd/docs/query_contract.md` (lines 1-81) — stable family/output/application-seam contract.
13. `clearhead-graphd/docs/jsonld_export_contract.md` (lines 1-117) — intended export and validation contract, with stale details noted below.
14. `clearhead-graphd/tests/dependency_graph.rs` (lines 1-121), `graph_queries.rs` (1-513), `index_queries.rs` (1-639), `tree_queries.rs` (1-182), `spec_conformance.rs` (1-130), `tests/common/mod.rs` — integration/CLI contracts.
15. `clearhead-graphd/.github/workflows/ci.yml` (lines 1-56), `.githooks/pre-push` (1-20), `README.md` (1-72) — build/test/install-facing surfaces.

## Key Code

### Inventory and classification

| Area | Evidence | Classification | Finding |
|---|---|---|---|
| Crate facade | `src/lib.rs:1-9`; `src/graph/mod.rs:110-127` | **Core RDF publication** | Public library owns RDF insert/query, validation, JSON-LD; query module is also exported. |
| RDF store | `src/graph/mod.rs:1-106,225-245`; `src/query.rs:85-124` | **Core RDF publication** | Fresh in-memory Oxigraph store per invocation. Every workspace uses `urn:clearhead:workspace:<id>` named graph; query evaluator exposes union of named graphs as default. Primary plus configured additional workspaces are materialized. |
| Domain→RDF | `src/graph/insert.rs:20-55,58-101,253-657` | **Core RDF publication** | Projects Charter/Plan/Action, containment, aliases/states, recurrence, occurrence keys, dates, priority, contexts, predecessors, generated sequential sibling edges, and tag hierarchy. This is the central publication implementation. |
| Workspace/provenance→RDF | `src/graph/insert.rs:103-228`; `src/query.rs:88-123` | **Core RDF publication** | Publishes Workspace identity/root/charterRoot and source file/line locators. Important dependency for index contracts and editor clients. |
| Turtle test loader | `src/graph/insert.rs:230-249` | **Core RDF publication** (test support) | Rehomes parsed default-graph Turtle into a named graph. Not a user import/database surface. |
| Direct DomainModel JSON-LD | `src/main.rs:18-25,145-161`; `src/graph/jsonld.rs:1-30,110-188,190-389` | **Core RDF publication** | `export-jsonld` reads serialized Core `DomainModel` from stdin. Implementation constructs compact JSON-LD directly from domain objects; it does **not** serialize the Oxigraph projection. Uses vendored context and deterministic node sorting. |
| Workspace JSON-LD enrichment | `src/graph/jsonld.rs:31-108`; re-export `src/graph/mod.rs:120` | **Core RDF publication**, unresolved reachability | Adds `ws` context and source fields. Public library API, but binary does not call it; workspace query graph JSON-LD instead serializes CONSTRUCT triples (`src/query.rs:494-528`). Decide whether this is required publication API or dead parallel path. |
| Vendored resources | `src/resources/actions.context.v4.json`, `actions.schema.v4.json`, `ontology-out.example.v4.jsonld`; includes at `src/graph/jsonld.rs:23,390-397` | **Core RDF publication** | Offline context/schema/example are export fixtures/contracts. |
| SELECT/SPARQL executor | `src/graph/query.rs:13-78,267-305` | **Optional CLI SPARQL** | Supports SELECT rows; ASK and graph forms rejected on row path. Prefix/WHERE helpers exist. Union-default is enabled unless query declares dataset. |
| CONSTRUCT/DESCRIBE executor | `src/graph/query.rs:21-44` | **Optional CLI SPARQL** | Returns RDF triples and rejects SELECT/ASK for graph family. |
| Hand-coded “SHACL” validation | `src/graph/query.rs:80-254`; `docs/jsonld_export_contract.md:90-105` | **Core RDF publication**, **unresolved naming/scope** | No SHACL files/library/parser exist. `validate_actions_vocabulary` executes SPARQL checks corresponding to a bounded shape subset: status presence/domain, prescribes target, UUID presence, completed date, recurrence anchor, direct self-loop, alias uniqueness. It is not invoked by normal build/export/query paths (only tests/public API). Do not claim standards-compliant SHACL validation. |
| CLI command tree | `src/main.rs:7-82,110-138` | **Optional CLI SPARQL** except `export-jsonld` | `query index/tree/graph/named/raw/list/show`; standalone, no resident daemon or CLI proxy. |
| Parameter/prefix injection | `src/query.rs:127-196` | **Optional CLI SPARQL** | Adds standard prefixes and textually substitutes time/status/target placeholders. Raw textual replacement is a risk (not bound parameters; caller must supply safe canonical IRIs). |
| Saved-query registry | `src/query.rs:199-347` | **Optional CLI SPARQL** | Built-ins plus user `<config>/queries` plus project `.clearhead/queries`; insertion order gives project > user > built-in for unrestricted queries. Typed index/tree/graph user/project queries are resolved separately, project before built-in but user-vs-project shadowing is implicit HashMap insertion. |
| Built-in index queries | `src/query.rs:207-217`; `src/queries/index/{agenda,chain,default,unscheduled,weekly}.sparql` | **Optional CLI SPARQL** (contract); results are **client presentation** | Ordered addressable action views. Required locator fields are enforced by `INDEX_REQUIRED` (`src/graph/shape.rs:18-31`). Agenda/unscheduled/weekly embody application selection policy, not RDF publication. |
| Tree query | `src/query.rs:218-220,447-491`; `src/queries/tree/work-map.sparql:1-49` | **Client presentation** | SELECT bindings validated/nested into a work map. |
| Graph query | `src/query.rs:221-224,494-535`; `src/queries/graph/dependencies.sparql:1-40` | **Optional CLI SPARQL**; DOT/summary are **client presentation** | CONSTRUCT RDF is semantic result; machine defaults JSON-LD, supports Turtle. |
| Unrestricted built-ins | registry `src/query.rs:226-262`; root `.sparql` files | **Optional CLI SPARQL**, some **deletion candidates/unresolved** | `actions-by-phase`, `all-plans`, `all-plans-simple`, `completion-velocity`, `dependency-chain`, `high-priority`, `next-actions`, `orphaned-actions`, `overdue-tasks`, `open-plans`, `plans-with-contexts`. Several appear legacy/overlapping (two all-plans; dependency-chain vs typed chain/graph; open-plans actually actions) and are only registry assets. Confirm consumers before deletion. |
| Index JSON-LD shape | `src/graph/shape.rs:18-48,113-205` | **Client presentation** with semantic context | Frames validated rows into `@context` + `@graph`; plain `id` aliases `@id`; locator join-context retained for direct clients. |
| NDJSON/IDs/table/tree renderers | `src/query.rs:34-80,426-440,472-490,633-796` | **Client presentation** | Destination-aware defaults: index→NDJSON, rows→JSON, tree→nested JSON; TTY→table/tree. IDs preserve canonical identity. These are not RDF publication formats. |
| RDF JSON-LD/Turtle renderer | `src/query.rs:494-528,657-684` | **Core RDF publication** for serialization, exposed through **Optional CLI SPARQL** | Oxigraph `RdfSerializer` serializes CONSTRUCT triples. Distinct from direct domain JSON-LD path. |
| DOT | `src/graph/dot.rs:1-194`; dispatch `src/query.rs:527-528` | **Client presentation** | Petgraph/Graphviz text projection; reverses predecessor edge visually and decorates nodes. RDF remains contract. |
| External database | `Cargo.toml:20-24`; `src/graph/mod.rs:239-245`; README `1-7` | **External database concern: absent** | Oxigraph default features disabled; only `Store::new()` in memory, no RocksDB/server/persistence/network/database lifecycle. Any durable triplestore/federation is explicitly outside current implementation. |
| Duplicate validation tests | `src/graph/query.rs:307-534` and near-duplicates `536-682` | **Deletion candidate** | The UUID/completed/recurrence/self-loop/alias tests are duplicated in a second module. Remove duplicate module after verifying coverage. |
| `build_where_query` | `src/graph/query.rs:60-78`; re-export `src/graph/mod.rs:123-126` | **Unresolved / deletion candidate** | `_select` and `_from` are ignored and no in-repo call was found beyond tests/exports. Potential stale API. |
| Documentation contract | `docs/query_contract.md:11-81` | **Core contract** | Clearly separates portable SPARQL families, renderings, stateless read→act-by-id→re-read application seam (`lines 73-81`). |

### Query and presentation architecture

`main.rs` discovers Core config, creates a `QueryContext`, and dispatches. `query::build_store` loads Core `Workspace`, converts to `DomainModel`, inserts workspace metadata and RDF into distinct named graphs. Saved/raw SPARQL is prepared by Oxigraph with named graphs unioned as the default dataset. Results split into:

- SELECT rows → unrestricted JSON/NDJSON/table;
- index SELECT → validate/frame JSON-LD document → table/JSON/NDJSON/IDs;
- tree SELECT → validate parent graph → nested JSON/terminal tree;
- graph CONSTRUCT → triples → RDF JSON-LD/Turtle, DOT, or summary.

The independent `export-jsonld` flow bypasses workspace loading and Oxigraph: stdin JSON → Core `DomainModel` → direct JSON object construction. This dual projection is the largest architectural reconciliation point for an RDF-publication charter.

### Tests and proving contracts

- Unit projection/ontology tests: `src/graph/insert.rs:659-1155` (canonical v4 terms, negative legacy terms, sequential edges, context hierarchy/property paths).
- JSON-LD/schema tests: `src/graph/jsonld.rs:390-560` (shape, deterministic sort, fields, vendored schema/example).
- SPARQL/validation tests: `src/graph/query.rs:307-717` (query kinds, each validation rule, named-graph union behavior; duplicated block noted).
- Shape tests: `src/graph/shape.rs:207-332` (required fields, numeric coercion, ordering, empty results, tree integrity, JSON-LD context).
- DOT test: `src/graph/dot.rs:195-233`.
- Graph CLI contract: `tests/dependency_graph.rs:16-120` (Turtle, default JSON-LD, DOT direction, SELECT rejection, list/show).
- RDF/query fixture behavior: `tests/graph_queries.rs:40-512` (flat actions, status, scope, date filters, named queries, charter state).
- Index contract/policy/shadowing: `tests/index_queries.rs:22-638` (NDJSON, IDs, agenda/weekly/unscheduled/chain, project override, list/show).
- Tree contract: `tests/tree_queries.rs:13-181`.
- Specification schema opt-in: `tests/spec_conformance.rs:1-130`; feature declared `Cargo.toml:29-35`. Requires `CLEARHEAD_SPEC_DIR` and `--features spec-conformance`.

### Build/install surfaces and risks

- Package/binary: `Cargo.toml:1-12`, binary name `clearhead-graphd`; README only documents source-tree testing (`README.md:66-72`), not `cargo install` or release artifacts.
- Core is a sibling path dependency (`Cargo.toml:16`), so graphd is **not standalone-clone installable** despite README wording. CI explicitly checks out sibling Core and tree-sitter (`.github/workflows/ci.yml:7-32`). This is an unresolved build/publication concern.
- Read-only dependency boundary: Core default features off, Oxigraph default features off (`Cargo.toml:14-24`); CI rejects Topiary/Tokio (`.github/workflows/ci.yml:45-52`).
- CI runs fmt, clippy locked, dependency boundary, tests locked (`.github/workflows/ci.yml:34-56`); pre-push mirrors checks (`.githooks/pre-push:1-20`).
- There is no install workflow, container, service unit, daemon protocol, HTTP endpoint, or database migration/config.

### Contract/documentation discrepancies to resolve

1. `docs/jsonld_export_contract.md:7` still names `clearhead-core/src/graph/jsonld.rs`; authority actually resides at `clearhead-graphd/src/graph/jsonld.rs:27-29`.
2. The doc describes `@id`/`@type`, `hasPart`, `prescribes`, and ontology-style field names (`docs/jsonld_export_contract.md:26-76`), while implementation emits compact keys `id`/`type`, `subCharters`, `actions`, `partOf`, `status`, etc. (`src/graph/jsonld.rs:190-321`). Vendored context may make some compact forms semantically valid, but prose is not an exact wire-format contract.
3. Doc says `_meta` is present only when contexts exist (`docs/jsonld_export_contract.md:14-22`); implementation always emits `_meta`, using `{}` when none (`src/graph/jsonld.rs:168-187`).
4. JSON-LD context normalization strips `@` (`src/graph/jsonld.rs:308-316`) whereas RDF insertion strips `+` (`src/graph/insert.rs:564-571`); DSL conventions and identity equivalence need verification.
5. “SHACL” is only a conceptual label. No `.ttl` shape asset or SHACL engine exists; public validator is a custom SPARQL subset.

## Architecture

Core supplies graph-neutral domain/config/workspace loading. graphd owns publication and querying. Publication currently has two parallel representations: (1) materialized Oxigraph quads used for workspace SPARQL/CONSTRUCT, and (2) hand-built compact JSON-LD used for stdin export/workspace library export. Query-family framing adds a third, client-oriented JSON-LD context for ordered index rows. RDF/Turtle/CONSTRUCT belongs to semantic publication; NDJSON, table, tree, IDs, and DOT belong to presentation/composition. No external database exists.

For charter scoping, preserve `insert.rs`, named graph identity, ontology resources, semantic RDF serializers, and conformance tests as the likely Core RDF publication. Treat ad-hoc/saved SPARQL as optional CLI capability. Keep output-family validators if client contracts remain in graphd, but classify their renderers as presentation. Do not accidentally turn Oxigraph into a persistent service concern.

## Proving commands

Run from `/home/dab/Products/platform`:

```sh
# Baseline, locked quality gates
cargo fmt --manifest-path clearhead-graphd/Cargo.toml --check
cargo clippy --manifest-path clearhead-graphd/Cargo.toml --all-targets --no-deps --locked -- -D warnings
cargo test --manifest-path clearhead-graphd/Cargo.toml --locked

# Published specification schema (requires specification checkout)
CLEARHEAD_SPEC_DIR="$PWD/specifications" cargo test \
  --manifest-path clearhead-graphd/Cargo.toml --locked \
  --features spec-conformance --test spec_conformance

# Prove no persistent/runtime-heavy database stack
cargo tree --manifest-path clearhead-graphd/Cargo.toml --locked --edges all --target all --prefix none \
  | grep -E '^(rocksdb|topiary-core|topiary-tree-sitter-facade|tokio) v' && exit 1 || true

# Query registry and inspect portable SPARQL
cargo run --manifest-path clearhead-graphd/Cargo.toml -- --workspace "$PWD" query list
cargo run --manifest-path clearhead-graphd/Cargo.toml -- --workspace "$PWD" query show dependencies

# Family projections (use a workspace containing actions)
cargo run --manifest-path clearhead-graphd/Cargo.toml -- --workspace /path/to/ws query index default --format ndjson
cargo run --manifest-path clearhead-graphd/Cargo.toml -- --workspace /path/to/ws query tree work-map --format json
cargo run --manifest-path clearhead-graphd/Cargo.toml -- --workspace /path/to/ws query graph dependencies --format turtle
cargo run --manifest-path clearhead-graphd/Cargo.toml -- --workspace /path/to/ws query graph dependencies --format jsonld
cargo run --manifest-path clearhead-graphd/Cargo.toml -- --workspace /path/to/ws query graph dependencies --format dot

# Direct publication path (given a serialized DomainModel)
cargo run --manifest-path clearhead-graphd/Cargo.toml -- export-jsonld < /path/to/domain-model.json \
  | jq -e 'has("@context") and has("@graph")'

# Locate dead/duplicate surfaces before deletion
grep -RIn 'build_where_query\|serialize_workspace_to_jsonld\|validate_actions_vocabulary' clearhead-graphd --exclude-dir=target
grep -n 'fn validates_missing_uuid_literal\|fn validates_completed_action_requires_date' clearhead-graphd/src/graph/query.rs
```

## Start Here

Open `clearhead-graphd/src/graph/insert.rs` first: it is the authoritative domain/workspace→RDF publication map. Then compare `src/graph/jsonld.rs` to determine whether direct JSON-LD construction should converge on the RDF projection. Read `src/query.rs` only after that to separate optional SPARQL and presentation surfaces from publication.
