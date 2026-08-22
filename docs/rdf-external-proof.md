# RDF Publication — External Engine Proof

This is the evidence artifact for the `rdf-publication` charter's
`external-rdf-proof` action: the ClearHead-exported dataset loads into
independent RDF/SPARQL implementations, and the same saved `.sparql` queries run
unchanged there as well as in the CLI's optional in-process evaluator.

Reproduce with `bash docs/rdf-external-proof/run.sh` from the platform root
(requires `rapper`, `python3` + `rdflib`; set `CLEARHEAD`/`RDFLIB` to override
the default binary/interpreter paths).

## What is proven

1. **Dataset fidelity (independent parser).** `rapper` (Raptor 2.0.16, a C RDF
   parser — independent of Oxigraph/Rust) parses our TriG export and reproduces
   the *exact same quad set*, graph terms included. Named-graph identity
   (`urn:clearhead:workspace:<uuid>`), canonical `urn:uuid:` entity IRIs, and
   every typed literal survive the round trip byte-for-byte as a set.
2. **Determinism.** Two consecutive exports are byte-identical (sha256-stable
   for a workspace with durable manifest identity), so exports are diffable and
   replaceable.
3. **SPARQL equivalence (independent engine).** The portable saved queries run
   unchanged in `rdflib` 7.6.0 (an independent Python SPARQL 1.1 implementation)
   and in the ClearHead in-process evaluator (Oxigraph) over the same exported
   dataset, returning identical result sets — including `FILTER NOT EXISTS`
   (`next-actions`), `GROUP BY` (`completion-velocity`), and `ORDER BY`
   (`next-actions`, `high-priority`, `dependency-chain`, all ordered).
4. **Replace-snapshot.** After a workspace mutation, the re-export surfaces only
   the new state in both engines; the prior export did not contain it
   (publication is a replaceable snapshot, not an incremental merge).

## Engines

| Engine | Version | Role |
| --- | --- | --- |
| `clearhead` | 0.2.1 | export + in-process SPARQL evaluator (Oxigraph) |
| `rapper` (Raptor) | 2.0.16 | independent TriG/N-Quads parser (dataset fidelity) |
| `rdflib` | 7.6.0 | independent SPARQL 1.1 evaluator (query equivalence) |

## Exact commands

```bash
# Export the fixture workspace (TriG preserves the named graph).
clearhead export workspace --format trig -o export.trig
clearhead export workspace --format nquads -o export.nq

# Independent parser round-trip: Raptor's TriG→N-Quads must equal our N-Quads.
rapper -i trig -o nquads export.trig | sort > rapper.nq
sort export.nq > ours.nq
cmp ours.nq rapper.nq   # identical quad set, graph terms included

# A proving query, unchanged, in the in-process evaluator (SPARQL Results JSON).
clearhead query raw "$(cat next-actions.sparql)" --format json > ours.json

# The same query, unchanged, in an independent SPARQL 1.1 engine (CSV).
python rdflib_query.py export.trig trig next-actions.sparql theirs.csv
# rdflib loads TriG into a Dataset with default_union=True (see below).
python compare.py ours.json theirs.csv priority
```

## Intentionally engine-local behavior

These are conventions or engine gaps, not dataset/query defects:

- **Union default graph.** The ClearHead evaluator applies a union default graph
  for queries that declare no `FROM`/`FROM NAMED` dataset
  (`specifications/ontology.md`), so workspace-agnostic queries (the recommended
  style for the built-ins) match across every named graph. This is an
  *evaluator configuration*, not dataset content: each independent engine sets
  its own equivalent — rdflib via `Dataset.default_union = True`; Oxigraph via
  `set_default_graph_as_union`. The same `.sparql` file runs unchanged in both.
- **Parameterized built-ins excluded from the "unchanged" proof.** The graphd-era
  built-ins `agenda`, `weekly`, `chain` (`?END_OF_TODAY`/`?END_OF_WEEK`/
  `?TARGET_ACTION`), `actions-by-phase` (`?STATUS_FILTER`), and `overdue-tasks`
  (`?CUTOFF_DATE`) rely on graphd's parameter injection, which the in-process
  evaluator does not perform (saved queries must be complete, portable standard
  SPARQL). They are rewritten or retired as portable standard SPARQL in the
  `migrate-graph-consumers` action; until then they are intentionally absent
  from this proof's portable set.
- **rdflib `GROUP_CONCAT(DISTINCT ?opt)` gap.** `all-plans.sparql` uses
  `GROUP_CONCAT(DISTINCT ?context)` over an `OPTIONAL` variable. rdflib 7.6.0
  raises `NotBoundError` instead of skipping unbound values per the SPARQL 1.1
  spec; the query is standard and runs correctly in ClearHead. Recorded as an
  rdflib engine limitation, not gated.
- **Rasqal 0.9.33 predates SPARQL 1.1.** `roqet` (Rasqal) is installed on the
  proof machine but cannot parse `FILTER NOT EXISTS` ("unexpected NOT") and
  fails most built-ins; it also does not preserve TriG named-graph addressing
  under `-D`. rdflib is used for the SPARQL 1.1 query proof instead; Raptor
  (same family) remains a valid independent *parser* for the dataset-fidelity
  check.
- **`ws:` snapshot properties are machine-local.** `ws:root`, `ws:charterRoot`,
  and per-action `ws:hasSourceFile`/`ws:hasSourceLine` carry the publishing
  host's filesystem paths and are workspace-snapshot conveniences for editor
  integration, not portable cross-machine identity (per
  `specifications/ontology.md`).
- **Name-form predecessor references don't resolve at load.** The fixture uses
  alias-form predecessors (`<alpha`), which resolve to `is_successor_of` edges.
  Name-form references (`<Alpha report`) are a search convenience
  (`specifications/reference_syntax.md`) and do not auto-resolve in the load
  path today — a reference-resolution tech-debt item, independent of RDF
  publication.

## Fixture

`docs/rdf-external-proof/fixture/` is a project-layout workspace exercising the
representative facts the charter names: Charter (with state/alias/description,
sub-charter `hasSubCharter`), Plan (`cco:ont00000974` with `hasRecurrenceRule`,
`part_of` its charter), Action (states, priority, `requiresContext`, scheduled/
due/completed datetimes, sub-action `part_of`, `is_successor_of` dependency),
Context nodes, and the `ws:` workspace-snapshot layer. The proof runner copies
it to a scratch dir so the replace-snapshot mutation leaves the checked-in
fixture pristine.
