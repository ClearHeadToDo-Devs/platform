---
id: 01a002d1-352f-78f2-8120-039b48d51a69
alias: spec-conformance-gate
parent: platform
objectives:
  - trustworthy-evolution
---
# The DSL Spec as Single Authority

`specifications/` is the authority for the `.actions` DSL. The grammar (tree-sitter-actions) and Core are **peer implementations** that conform to it — swap tree-sitter for a hand-written parser and the spec does not move, which is the test for who owns the contract. Core links the grammar to *do the parse* (tree-sitter/topiary): a **functionality dependency, not a spec dependency**. Each implementation takes only the parts of the spec it needs, validates against it where necessary, and holds no competing copy. The spec itself stays inert — it is data (schema, corpus, formatting forms, lint codes, prose), never a program, and nothing in `specifications/` executes.

## Why now: the duplication is real and drifting

- Two `actions.schema.json` exist — the grammar *generates* one (`scripts/generate-schema.js`, empty patterns, `priority min 0`), the spec holds a hand-enriched copy (real patterns, `priority 1–9`) that even carries the grammar's `$id`. `diff` confirms they have drifted; improvements landed on the copy and would be erased by regeneration.
- The `.actions` example corpus is duplicated across the grammar and the spec (`conformance_test.actions`, `laundry_workflow.actions`, …), plus Core keeps its own fixtures. Three divergent corpora for one language. The jq/sql query examples are likewise duplicated (`examples/queries/` in both grammar and spec).
- `conformance_test.actions` labels cases `(E012)`/`(E013)`; the linter and `linting.md` agree on `W002`/`W003` warnings, and no E012/E013 exists. The labels are stale.

## Ownership model

| Layer | Authority | Consumers |
| --- | --- | --- |
| DSL: surface syntax, `actions.schema.json`, canonical formatted forms, lint codes, example corpus, prose | **specifications** | grammar + Core |
| Concrete syntax tree (S-expression) shape | grammar (implementation detail, below the domain model) | grammar only |
| Parse/format *functionality* (tree-sitter, topiary) | grammar | Core links as a library |
| Domain model construction + linting | Core | — |

The one genuinely parser-specific artifact is the CST S-expression shape (`test/corpus/*.txt`): the spec says "an Action has a priority," not what the tree node is called. Its existence confirms the boundary rather than dents it. Everything above it points at the spec.

## What each implementation does (validate where necessary — no more)

- **Grammar** stops shipping a competing authoritative schema. `generate-schema.js` is **deleted**: it derives the schema from `patterns.js` to keep it in sync with the parser, but it isn't even delivering that (it emits empty patterns), and no consumer needs the schema *generated* — only a correct one to exist, which the spec provides. Its package `./schema` export and docs reference the spec's schema instead; `schema_validation_test.js` and formatting tests repoint at the spec's schema and `examples/formatting/`. The generator's intent — that the grammar parses what the schema calls valid — is preserved more cheaply by the grammar parsing the spec's valid corpus (accept the valid, reject the invalid). It keeps only its CST corpus.
- **Core** conforms at the semantic layer over the spec corpus: structure → validate serialized `ActionList` against the spec's `actions.schema.json` (net-new; adds a `jsonschema` dev-dep; aligns Core's serde shape to the schema); formatting → idempotence + roundtrip (already landed in `generated_invariants.rs`); linting → planted-condition properties (extend the reference/template generator pattern). Core does the lint layer because the grammar cannot.
- **Same corpus, different purposes:** one set of `.actions` examples in the spec; the grammar reads it with a syntactic/format oracle, Core with a semantic oracle.

## Simplicity guardrails

Duplication is the disease being treated — do not replace it with parallel test frameworks. One corpus, in the spec. Delete the grammar's and Core's overlapping copies rather than syncing them. Prefer the cheapest adequate oracle at each layer (idempotence/roundtrip over structural compare; planted-condition over model-traversal). Generator properties cover positive-space breadth; a *small* set of hand-authored fixtures covers the named negatives (`E001`–`E007`) and byte-level escaping edges the generator won't reach — kept minimal, not exhaustive.

## Independence

To test Core: clone Core beside its direct siblings — never the `platform` meta-repo. The grammar is a mandatory *functionality* dependency (path-dep, an existing standalone-build gap tracked separately). The spec is an *optional, test-only data* dependency: conformance sits behind a `spec-conformance` cargo feature that also gates the `jsonschema` dev-dep, with the spec located via `CLEARHEAD_SPEC_DIR` (default `../specifications`). Default `cargo test` needs no spec and stays green; the feature fails loudly only when enabled without the spec present. `scripts/validate-pinned` (which already gates the pinned composition) is unchanged; the spec never gets a runnable gate.

## Non-goals

- Any runnable gate inside `specifications/`, or a spec check that invokes an implementation.
- A second/third example corpus, or syncing copies instead of deleting them.
- A CLI `export json` command — Core's harness has direct type access and compares in-process.
- Pinning human-readable diagnostic message text (pin code + node span).
- Fixing the grammar's mandatory-path-dep standalone gap here (separate concern).

## Done gate

- `specifications/` is the sole `actions.schema.json` and the sole `.actions` example corpus; the grammar's and Core's duplicates are gone.
- The grammar validates its parsing/formatting against the spec (schema + formatting forms); `generate-schema.js` is removed and the grammar references the spec's schema.
- Core proves structure/format/lint conformance against the spec corpus behind the `spec-conformance` feature; its serde shape matches the spec schema.
- The stale `W`-code labels are corrected; the spec stays inert and `validate-pinned` unchanged.
