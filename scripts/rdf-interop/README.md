# RDF interoperability proof (`external-rdf-proof`)

Proves that ClearHead's RDF publication is **engine-independent**: the data is
standard RDF and the saved queries are standard SPARQL, not an Oxigraph-shaped
artifact. A `cargo test` cannot show this — it would be Oxigraph validating
Oxigraph. So this exports a committed fixture workspace with the real
`clearhead` binary and answers the CLI's own saved `.sparql` files, unchanged,
in [rdflib](https://rdflib.dev/) — a wholly independent, pure-Python SPARQL
engine.

## Run it

```sh
CLEARHEAD_BIN=$PWD/clearhead-core/target/debug/clearhead \
    uv run --with rdflib python scripts/rdf-interop/proof.py
```

`CLEARHEAD_BIN` is the binary under test, as an absolute path: the proof never
uses a `clearhead` on `PATH`, which was built from some other revision.
`scripts/validate-pinned` runs the proof as part of the pinned-composition
gate, with the CLI it built.

## What it asserts

- **Named-graph identity** — the export is exactly one graph,
  `urn:clearhead:workspace:<id>`, matching the fixture.
- **Canonical ids** — actions surface as `urn:uuid:…`, the spelling the CLI
  verbs accept.
- **Representative facts, via the CLI's saved queries run unchanged** — priority
  (`high-priority`), the dependency, completion and container filters
  (`index/unscheduled` drops a waiting successor, a completed action and a
  parent with open work), what waits on what (`dependency-chain`), charter
  membership (`orphaned-actions` is empty), and that the backlog and velocity
  queries evaluate.

The fixture lives in `fixture/data/clearhead/` — a charter of actions with a
priority, a `~` sequential chain, a context tag, and a completed action, plus
one recurring Plan. The plan is not asserted: the application graph does not
define recurrence yet (Decision 53).
