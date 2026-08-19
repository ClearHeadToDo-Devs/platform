Workflow completed with 3 child run(s). Return: ## graphd
# Code Context

## Files Retrieved

1. `clearhead-graphd/Cargo.toml` (lines 1-39) — package/bin, dependencies, in-memory Oxigraph choice, optional spec-conformance feature.
2. `clearhead-graphd/src/lib.rs` (lines 1-9) — public crate boundary (`graph`, `query`).
3. `clearhead-graphd/src/main.rs` (lines 7-161) — complete binary command surface and stdin JSON→JSON-LD route.
4. `clearhead-graphd/src/query.rs` (lines 1-836) — store assembly, saved-query discovery, query families, parameter injection, and all renderers.
5. `clearhead-graphd/src/graph/mod.rs` (lines 1-245) — named-graph architecture, ontology constants, exports, errors, in-memory store.
6. `clearhead-graphd/src/graph/insert.rs` (lines 1-658; tests 659-1155) — domain/workspace→RDF projection and projection tests.
7. `clearhead-graphd/src/graph/jsonld.rs` (lines 1-389; tests 390-560) — direct canonical JSON-LD construction, workspace enrichment, schema tests.
8. `clearhead-graphd/src/graph/query.rs` (lines 1-306; test Trace: 6 event(s).