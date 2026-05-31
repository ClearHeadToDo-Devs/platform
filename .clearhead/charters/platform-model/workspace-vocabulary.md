---
id: 019e7c9c-37ae-7d62-8784-e791ce20c0c0
alias: workspace-vocabulary
state: Active
---
# Workspace Vocabulary

SPARQL is the one query language for clearhead. The `read actions` filter flags (`--state`, `--priority`, `--charter`, etc.) represent a second query language that has emerged organically and must not be allowed to grow into a parallel system. The resolution is to make SPARQL complete enough that no second language is needed.

The gap that forced the second language: SPARQL queries over the domain graph cannot answer "where in the filesystem does this action live?" The graph holds ontological properties of actions but not their source location. This gap caused the `read actions` filter path to exist alongside SPARQL.

## Design Decisions

**SPARQL is the query language. There is no other.**
The `read actions` filter flags are a convenience shim, not a query system. They either generate SPARQL internally or are deprecated. No new filter flags are added.

**Source location is workspace-layer, not domain-layer.**
`actions:hasPriority` is a property of an action. `clearhead-ws:hasSourceFile` is a property of an action-in-this-workspace. These belong in separate vocabularies. The domain ontology stays pure.

**A new workspace vocabulary extends the domain ontology.**
`clearhead-ws:` at `https://clearhead.us/vocab/workspace/v1#` imports `actions:` and declares predicates for filesystem-layer facts. The vocabulary file lives in the ontology repo and is published at clearhead.us alongside v4, through the same Cloudflare Pages pipeline. These triples are stored in the working graph at load time and are valid for the current workspace snapshot.

**The working graph is a complete snapshot.**
When `load_domain_model` runs, it stores both ontological triples and workspace-layer triples (`clearhead-ws:hasSourceFile`, `clearhead-ws:hasSourceLine`). The graph answers all queries — domain and location — without a second lookup step.

**JSON-LD from the workspace vocabulary is the single structured output format.**
The workspace vocabulary imports the domain vocabulary, so a JSON-LD export shaped by `clearhead-ws:` already contains all domain triples plus `hasSourceFile` and `hasSourceLine`. There is no separate flat JSON format — that would reintroduce the "when to use which" confusion. Editor integrations, scripts, and RDF tools all consume the same JSON-LD. `vim.fn.json_decode()` reads JSON-LD without ceremony.

## Vocabulary Sketch

```turtle
@prefix clearhead-ws: <https://clearhead.us/vocab/workspace/v1#> .

clearhead-ws:hasSourceFile a owl:DatatypeProperty ;
    rdfs:domain actions:Action ;
    rdfs:range xsd:string ;
    rdfs:comment "Relative path to the .actions file containing this action." .

clearhead-ws:hasSourceLine a owl:DatatypeProperty ;
    rdfs:domain actions:Action ;
    rdfs:range xsd:integer ;
    rdfs:comment "1-based line number within the source file." .
```
