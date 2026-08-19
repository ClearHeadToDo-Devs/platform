---
id: 01a01833-3f9d-7b03-b0c7-8701aa1517df
alias: rdf-publication
parent: platform
state: Active
---
# RDF Publication and Optional Local SPARQL

ClearHead's canonical data is the human-editable plaintext workspace. RDF is the
semantic publication of the validated domain model, not a second authoritative
workspace format and not a commitment to an embedded graph database. This
charter separates that durable data contract from the optional convenience of
running SPARQL locally.

## Problem

`clearhead-graphd` currently combines several concerns: the canonical
DomainModel-to-RDF mapping, JSON-LD and RDF serialization, an ephemeral
Oxigraph store, saved-query discovery, ClearHead-specific query families,
shape validation, terminal rendering, and graph visualizations. The extraction
kept graph dependencies out of Core and the CLI, but it also made one particular
query runtime look like the platform's graph backend.

The ontology exists so independent applications can exchange meaning at the
data layer. A semantic-web consumer should be able to ingest a standard
ClearHead RDF dataset into its own store and run ordinary SPARQL without
installing a ClearHead database wrapper. At the same time, requiring every
local user to operate a persistent RDF service merely to run `agenda.sparql`
would violate the local-first, low-administration workflow.

## Decisions

### The workspace remains the only canonical write model

The read path remains:

```text
plaintext workspace -> validated DomainModel -> RDF dataset
```

RDF publication is a deterministic, replaceable snapshot. Missing triples are
not interpreted as workspace deletions, external graph mutations do not sync
back into plaintext, and this charter adds no generic RDF import or arbitrary
Turtle-loading surface. Query results address ordinary mutation verbs through
the same canonical `urn:uuid:...` identities already accepted by the CLI.

### Core owns the canonical RDF projection

Core gains an always-available `rdf` module. It maps a `DomainModel` to the
ontology-aligned RDF dataset, owns stable entity and named-graph IRIs,
datatypes, deterministic serialization, and semantic export validation. JSON-LD
is an RDF serialization of this same dataset, not a parallel hand-built export
path; compact framing may differ by format, but it must preserve the same facts
and graph identity. It uses only lightweight RDF term/serialization
dependencies. Core remains query-engine-neutral: it does not acquire Oxigraph,
persistence, SPARQL, endpoint, reasoning, terminal, or network concerns.

RDF is not feature-gated in Core. It is a foundational platform representation,
and a lightweight always-present module is simpler than conditional public
APIs and a matrix in which ordinary CLI export may or may not exist. The
internal dependency direction remains one-way: `rdf` consumes `domain`; domain
semantics do not depend on RDF.

### The CLI always publishes RDF

The CLI exposes whole-workspace export in standard syntaxes. Dataset-capable
formats such as TriG and N-Quads preserve the stable named graph for each
workspace; JSON-LD and graph-only formats remain available where their contract
is well-defined. The CLI owns arguments, workspace selection, stdout/files,
errors, and broken-pipe behavior, but delegates every semantic statement to
Core's single projection.

External RDF databases own persistent indexing, federation, reasoning,
additional datasets, endpoint operation, authentication, and graph replacement.
ClearHead publishes bytes and portable query artifacts rather than abstracting
or proxying those systems.

### Local SPARQL is an optional evaluator, not a backend

The CLI may be built with a `sparql` feature. That capability uses Oxigraph as
an in-memory, one-shot evaluator over exactly the RDF dataset Core produces:

```text
workspace -> DomainModel -> Core RDF dataset
                                  |
                                  v
                         ephemeral Oxigraph -> SPARQL result
```

It loads only ClearHead's generated dataset and the trusted bundled ontology or
shape resources required by the contract. It does not accept arbitrary RDF
files, persist a database, federate sources, connect to remote endpoints, or
own a second data lifecycle. Complete saved queries remain ordinary `.sparql`
files and must run unchanged in independent SPARQL tooling.

Oxigraph and its build cost belong only to the CLI's optional query feature.
Core and a minimal CLI build do not compile a query engine. Machine output
should prefer standard SPARQL result and RDF serializations; client-specific
views may validate the bindings they consume without turning those conventions
into a query language.

## Target ownership

| Concern | Owner |
| --- | --- |
| Domain and workspace semantics | `clearhead-core` |
| DomainModel to RDF dataset | Core `rdf` module |
| RDF mapping, identity, serialization, validation | Core `rdf` module |
| `clearhead export workspace` invocation and I/O | CLI |
| Optional ephemeral SPARQL execution | CLI `sparql` feature |
| Persistent/federated semantic graph | External RDF database |
| Saved portable SPARQL | Query artifacts, runnable independently |
| Quickfix, table, tree, and other interaction models | Consuming clients |

## Non-goals

- making RDF or an RDF database authoritative over the workspace
- generic RDF-to-workspace import, synchronization, or round-trip source recovery
- loading arbitrary foreign RDF into the local evaluator
- inventing a ClearHead query language or universal graph-backend trait
- introducing SQL, GQL, or a property-graph projection in this charter
- proxying remote SPARQL endpoints or managing an external database
- preserving graphd merely as a subprocess boundary after its responsibilities move

## Delivery strategy

Land and prove the canonical publication path before removing graphd. Existing
queries and consumers continue to work until Core export, CLI export, optional
local execution, and an independent external-tool round trip are all evidenced.
Retirement is a consequence of those replacements, not the first step.

## Done gate

This charter is complete when:

- one Core RDF projection is the source of every ClearHead RDF statement,
  including JSON-LD
- Core's normal dependency graph contains no query engine or database
- whole-workspace TriG/N-Quads export preserves stable named-graph identity and
  deterministic ontology-aligned content
- the CLI builds and tests both without and with its optional `sparql` feature
- the optional evaluator executes the existing proving queries over Core's
  dataset without persistent state or foreign-data loading
- the same exported dataset and saved queries work unchanged in an independent
  RDF/SPARQL implementation
- current clients have a documented replacement for every graphd capability
  they actually retain
- graphd and its stale contracts, subprocess plumbing, installation steps, and
  platform gitlink are removed or explicitly retained only for a demonstrated
  responsibility not covered above
- specifications, ontology artifacts, user documentation, decision history,
  and pinned-platform validation agree on the final boundary
