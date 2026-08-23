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
ontology/.venv/bin/python scripts/rdf-interop/proof.py
```

rdflib comes from the ontology venv (`ontology/.venv`), which the ontology
pre-push gate already provisions. `scripts/validate-pinned` runs the proof as
part of the pinned-composition gate, after the CLI is built.

## What it asserts

- **Named-graph identity** — the export is exactly one graph,
  `urn:clearhead:workspace:<id>`, matching the fixture.
- **Canonical ids** — actions surface as `urn:uuid:…`, the spelling the CLI
  verbs accept.
- **Representative facts, via the CLI's saved queries run unchanged** — priority
  (`high-priority`), the GTD dependency filter (`next-actions` correctly drops a
  blocked successor and a completed action), the successor edge
  (`dependency-chain`), charter membership (`orphaned-actions` is empty), and a
  Plan (`all-plans-simple`).

The fixture lives in `fixture/data/clearhead/` — a charter of actions with a
priority, a `~` sequential chain, a context tag, and a completed action, plus
one recurring Plan.

## Recorded engine-local behavior

`all-plans.sparql` uses `GROUP_CONCAT` over an `OPTIONAL` (possibly unbound)
variable. That is legal SPARQL — unbound values are skipped — and Oxigraph
evaluates it. rdflib's aggregate implementation raises `NotBoundError` instead.
This is an **rdflib limitation, not a defect in ClearHead's published data**, so
the proof records it rather than treating it as a portability failure.
