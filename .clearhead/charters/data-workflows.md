---
id: 019fdfe3-dbd5-7f31-a58b-8570a8336cad
alias: data-workflows
parent: platform
objectives:
  - query-interface
  - data-integration
state: Active
---
# Validated Data Workflows

ClearHead already has the pieces of a clean machine workflow:

- graphd returns query results as structured data
- those results carry canonical action IDs
- the CLI accepts those canonical IDs for mutation
- Core can commit several file changes through one locked, recoverable
  `PendingBatch`

This charter joins those existing seams without creating another data model or
protocol:

```text
clearhead query index unscheduled --format json
        ↓ select canonical IDs with jq or another client
clearhead transact < request.json
        ↓ one validated semantic batch
clearhead query index unscheduled --format json
```

The query result is ordinary data. A consumer may pass one selected ID directly
to an existing CLI verb or transform several rows into a transaction request.

## What already works

Graphd already owns and emits the useful representations:

- index queries emit an ordered JSON array or NDJSON stream
- tree queries emit nested JSON
- unrestricted SELECT queries emit JSON rows
- graph queries emit JSON-LD, Turtle, or DOT

Index rows include canonical identities such as `urn:uuid:…`. The current CLI
resolver already accepts that spelling; a graphd result can therefore drive
`show`, `update`, `complete`, and the other identity-addressed verbs without an
adapter object.

The old `clearhead query` implementation was almost the desired design: it
forwarded arguments to graphd with inherited stdin/stdout/stderr and propagated
the process exit status. It did not decode or re-render results. Its only domain
adapter resolved a fuzzy action reference for the `chain` query and handed
graphd the canonical IRI.

Core's durability seam is also already shipped. A multi-file writer acquires the
workspace lock, recovers pending intent, stages every output, and commits one
`PendingBatch`. This charter adds semantic batch planning above that mechanism;
it does not replace the journal or locking policy.

## Ownership

- **graphd owns queries and query output:** RDF projection, SPARQL, named views,
  family contracts, JSON/NDJSON/JSON-LD, and terminal rendering
- **Core owns transaction meaning and persistence:** resolve operations against
  trusted workspace state, validate the whole batch, render affected files, and
  commit once through the existing durability seam
- **the CLI owns composition:** expose graphd through `clearhead query`,
  accept a transaction document through `clearhead transact`, and preserve machine-safe
  stdout and exit behavior
- **specifications own the JSON Schemas:** the current index result, transaction
  request, and transaction result contracts

The CLI query shim is deliberately transparent. It must not parse, wrap,
validate, or reserialize graphd output, and it must not absorb Oxigraph, SPARQL,
or graph-family logic. Schema conformance for query output is tested where the
bytes are produced: in graphd.

This narrowly supersedes the closed graphd charter's decision to remove the CLI
facade. It does not reverse the graph extraction or make the CLI the query
implementation.

## Minimal JSON contracts

Use JSON Schema Draft 2020-12 for three small contracts:

1. **index query output** — the JSON array graphd already emits, with canonical
   `id`, display fields, status, and source locator fields
2. **transaction request** — an ordered `operations` array whose tagged semantic
   operations target canonical IDs
3. **transaction result** — either a compact commit/dry-run receipt or a typed
   failure

The schemas describe intentional wire bytes before Rust types make them harder
to change. They do not introduce a universal response envelope, workspace
revision, JSON Patch dialect, or editable JSON-LD document.

The first transaction operation set stays deliberately small: action update,
complete, and cancel. That is enough to prove in-place edits and active-to-
completed multi-file moves. More operations should be added only after the
shape proves useful.

A request can be assembled directly from query data:

```bash
clearhead query index unscheduled --format json |
  jq '{operations: [
    {op: "update-action", target: .[0].id,
     set: {state: "in-progress"}}
  ]}' |
  clearhead transact -
```

Single-item work should continue to use the ordinary verbs. Transactions exist
for batches that must validate together and commit together, not to replace the
rest of the CLI.

## Transaction path

A transaction performs one straightforward sequence:

1. parse and schema-validate the request
2. acquire the workspace lock and recover pending intent
3. load trusted current workspace state
4. resolve and apply every operation in memory
5. reject the entire batch if any operation or resulting state is invalid
6. render every affected action file and sidecar
7. commit all outputs through one `PendingBatch`
8. emit a schema-valid receipt

`--dry-run` uses the same planner but stops before staging. There is no snapshot
hash or compare-and-swap token in the first version: targets have stable IDs,
and operations apply to the current state loaded under the lock. Preconditions
can be added later if real stale-update failures demonstrate the need.

## Non-goals

- a new graph or query implementation in the CLI
- parsing or normalizing graphd output in the forwarding shim
- preserving compatibility with pre-release consumers while establishing this
  first coherent contract
- universal schemas for every graphd format or every CLI command
- plans, charters, move, delete, or arbitrary JSON Patch in the first operation
  set
- routing all existing mutation commands through the transaction engine
- snapshot revisions, reader isolation, distributed transactions, undo, MCP, or
  a resident daemon

## Delivery order

1. publish schemas and fixtures for the existing index JSON, minimal transaction
   request, and transaction result
2. restore the transparent `clearhead query` facade with current graphd command
   and format coverage
3. implement the small action transaction planner and commit it through one
   existing `PendingBatch`
4. expose `clearhead transact`, then prove and document the complete shell loop

## Done gate

This charter is complete when:

- graphd's real index JSON validates against the published schema
- `clearhead query index unscheduled --format json` is byte-for-byte graphd's
  output with the same stdio behavior and exit status
- an emitted canonical query ID works directly with existing CLI verbs
- a schema-valid request can update, complete, or cancel multiple actions in one
  transaction
- any invalid operation rejects the whole batch before a write
- the resulting action files and sidecars commit through one recoverable
  `PendingBatch`
- dry-run and commit receipts validate against the transaction-result schema
- an end-to-end query→jq→transact→query test passes through the real binaries
