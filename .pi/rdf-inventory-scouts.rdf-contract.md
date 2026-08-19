# Code Context

## Files Retrieved

1. `specifications/ontology.md` (lines 27-59, 61-156, 158-174) — implementation-agnostic authority claims, named-graph/query rules, term table, external identity profile.
2. `clearhead-graphd/src/graph/mod.rs` (lines 1-110, 147-244) — runtime architecture, exact namespace/CCO/BFO constants, workspace graph IRI.
3. `clearhead-graphd/src/graph/insert.rs` (lines 22-75, 77-116, 118-211, 246-587, 589-660) — actual RDF dataset emitted, workspace provenance, datatypes, context hierarchy.
4. `clearhead-graphd/src/graph/jsonld.rs` (lines 1-108, 110-376) — actual direct domain/workspace JSON-LD serializers, identity, fields, metadata, compaction and ordering.
5. `clearhead-graphd/src/graph/shape.rs` (lines 1-47, 49-143, 145-207) — query-family JSON/JSON-LD framing, required fields, datatype coercion, ordering semantics.
6. `clearhead-graphd/docs/query_contract.md` (lines 1-94) — stable query-family consumer contract.
7. `clearhead-graphd/docs/jsonld_export_contract.md` (lines 1-114) — stated export contract; materially stale against implementation.
8. `clearhead-graphd/src/resources/actions.context.v4.json` (lines 1-130) — graphd-vendored context actually compiled into exporter.
9. `ontology/v4/actions.context.json` (lines 1-122) — ontology repository context artifact; semantically near-identical to vendored context.
10. `ontology/v4/actions.schema.json` (lines 1-100+) — ontology-out generated/contract schema (title says v4.4.0).
11. `ontology/v4/ONTOLOGY_OUT_CONTRACT.md` (lines 1-89) — ontology repository canonical compact JSON-LD scope and fields (document title says v4.3.0).
12. `ontology/v4/actions-vocabulary.owl` (line 631) — canonical OWL artifact itself records OWL API generation.
13. `clearhead-graphd/src/graph/query.rs` (lines 80-232) — implemented graph validation checks.

## Key Code

### Exact runtime RDF dataset

**Namespaces and identities.** Runtime constants are actions `https://clearhead.us/vocab/actions/v4#`, workspace `https://clearhead.us/vocab/workspace/v1#`, CCO `https://www.commoncoreontologies.org/`, BFO `http://purl.obolibrary.org/obo/` (`graph/mod.rs:147-178`). Charter, Plan, and Action subjects are all `urn:uuid:<uuid>` (`insert.rs:246-249, 337-340, 410-413`). Context is `urn:context:<normalized-tag>` where insertion strips leading `+`, trims, lowercases, and replaces spaces with hyphens (`insert.rs:589-601`). Direct JSON-LD differs subtly: it strips leading `@`, not `+` (`jsonld.rs:318-327`). Workspace resource and graph name are both `urn:clearhead:workspace:<effective-id>` in normal loading (`insert.rs:130-134`; `mod.rs:220-239`); transient stores use `urn:clearhead:workspace:transient` (`mod.rs:241-244`).

**Graph naming.** Production workspace data is in exactly one named graph and never the default graph; query evaluation uses union-default unless the query declares `FROM`/`FROM NAMED` (`specifications/ontology.md:61-113`; `graph/mod.rs:8-62`). The default graph is only a temporary Turtle parse/archive exception (`specifications/ontology.md:75-81`; `insert.rs:213-240`). Workspace identity is therefore both graph provenance and an RDF node inside that graph.

**Types and predicates actually inserted.**

- Charter: `rdf:type actions:Charter`; `rdfs:label`; `actions:hasUUID`; optional `rdfs:comment`, `actions:hasAlias`, simple-literal `actions:hasCharterState`; parent emits inverse-ish `parent actions:hasSubCharter child`; contains plans and unplanned actions via `bfo:BFO_0000051` (`insert.rs:256-330`).
- Plan: `rdf:type cco:ont00000974`; `hasUUID`, label/comment; `actions:hasRecurrenceRule`, `hasDueRecurrenceRule`, `hasExternalScheduleId`, `hasTemplateName`; `cco:ont00001942` prescribes generated actions; optional scheduled anchor (`insert.rs:347-406`).
- Action: `rdf:type actions:Action`; UUID, label/comment, priority, context, parent via `bfo:BFO_0000050`, predecessor via `cco:ont00001775`, alias, sequential flag, plan via `cco:ont00001920`, occurrence key, status via `cco:ont00001868`, scheduled/due/completed/created datetimes, duration (`insert.rs:420-587`). Sequential parents additionally generate sibling predecessor edges in document order (`insert.rs:77-116`).
- Context: type `actions:Context`; `hasContextIdentifier`; config hierarchy materializes both child→parent `contextBroader` and parent→child `contextNarrower`, including unused configured tags (`insert.rs:589-660`).
- Workspace/provenance: `ws:Workspace`, label, `actions:hasAlias`, `ws:root`, `ws:charterRoot`; charter `ws:hasSourceFile`; action `ws:hasSourceFile` and `ws:hasSourceLine` (`insert.rs:118-211`).

**Literal datatypes.** Labels/comments/UUID/state/alias/recurrence/external IDs/template/occurrence key are simple literals in insertion. Context identifier and workspace paths are explicit `xsd:string`; priority, duration, and source line are `xsd:integer`; sequential flag is `xsd:boolean`; scheduled/due/completed/created are `xsd:dateTime` serialized with `to_rfc3339()` (`insert.rs:141-169, 181-207, 256-406, 420-587, 608-614`). Status is an IRI, one of `actions:{NotStarted,InProgress,Completed,Blocked,Cancelled}` (`mod.rs:196-210`).

### Direct JSON-LD is not graph-derived

`serialize_domain_to_jsonld` calls `build_jsonld_document` directly over `DomainModel`, while `serialize_workspace_to_jsonld` reconstructs a model then decorates action nodes with source data (`jsonld.rs:26-108`). This contradicts the specification SHOULD for graph-derived interchange (`specifications/ontology.md:34-39`) and means insertion semantics and export semantics can drift.

Actual compact keys are `id`/`type` (context aliases of `@id`/`@type`), not literal `@id`/`@type` (`resources/actions.context.v4.json:3-5`; `jsonld.rs:340-344`). Current output:

- Charter: id/type/name/description and `subCharters`; **omits charter UUID, alias, state, plan/action containment** (`jsonld.rs:202-217`).
- Plan: id/type/name/description, `partOf`, compact `actions` (= CCO prescribes), UUID, recurrence and due recurrence; **omits external schedule ID, template, scheduled anchor** (`jsonld.rs:219-249`). Recurrence uses `to_string()` without insertion’s `R:` stripping.
- Action: id/type/name/description, alias, priority, contexts, parent, predecessors, UUID, status, scheduled/due/completed, duration, occurrence key; **omits plan prescribedBy, sequential flag, created datetime** (`jsonld.rs:251-295`).
- Context: id/type/name/contextIdentifier only; **omits configured context hierarchy because serializer has no config** (`jsonld.rs:297-316`).
- Objectives are never emitted despite ontology-out canonical scope including them (`ONTOLOGY_OUT_CONTRACT.md:5-20`; `jsonld.rs:110-191`).

The exporter always emits `_meta`; it is `{}` with no contexts, or provisional context notice/count otherwise (`jsonld.rs:179-199`). This differs from the stable doc saying `_meta` is present only when contexts exist (`docs/jsonld_export_contract.md:13-24`). Workspace export adds only action sourceFile/sourceLine and context terms; it does not emit a Workspace node/root/charterRoot or charter source (`jsonld.rs:32-108`).

### Ordering

Direct export sorts nodes deterministically by rank `Charter, Objective, Context, Plan, Action, ContextType`, then lexical compact `id` (`jsonld.rs:366-390`). Relationship arrays are not uniformly canonicalized: contexts are collected through a BTreeMap (sorted by context IRI), but action contexts/dependencies preserve domain order, plan actions preserve charter action order, and charter child vectors preserve model order (`jsonld.rs:110-177, 263-274, 297-307`). Single-value IRI properties compact to a scalar while 2+ become arrays (`jsonld.rs:351-365`), so cardinality changes JSON shape.

Query contracts have a distinct ordering contract: SELECT family row sequence is exactly SPARQL `ORDER BY`; relevant sort keys must be projected because RDF array order is not semantic (`docs/query_contract.md:75-81`). `frame_index` preserves row order as `@graph`; tree nesting preserves input sibling order (`shape.rs:1-12, 42-47, 75-113`). Raw row storage is `HashMap`, so JSON object member order is not contractual (`shape.rs:16, 145-161`). Index requires id/name/status/source_file/source_line/charter_root, coercing only source_line and priority to JSON numbers (`shape.rs:18-32, 145-161`); `charter_root` is deliberately unmapped denormalized join context and disappears on JSON-LD expansion (`shape.rs:163-207`).

### Validation

Runtime validation implements status presence/enum, Plan prescribes target typing, UUID on Action and Plan, completed-date requirement, recurrence anchor, direct self-successor, and per-named-graph action alias uniqueness (`query.rs:80-232`; summarized in `docs/jsonld_export_contract.md:75-95`). It is custom SPARQL validation, not demonstrated ingestion of `ontology/v4/actions-shapes-v4.ttl`. It does not validate Charter UUID, datatype/cardinality generally, longer dependency cycles, dangling parent/dependency/prescribedBy, inverse consistency, context identity, or cross-graph uniqueness.

## Architecture

The ontology submodule is declared normative for term/schema artifacts (`specifications/ontology.md:54-59`). Within it, `v4/actions-vocabulary.owl` is advertised as canonical format but is itself generated by OWL API (`actions-vocabulary.owl:631`); context/schema/contract/examples are publication artifacts around it. The ontology-out contract calls itself canonical (`ONTOLOGY_OUT_CONTRACT.md:1-18`) but its heading is v4.3.0 while schema title is v4.4.0 (`actions.schema.json:1-5`). graphd copies the context/schema/example under `src/resources` and compiles them with `include_str!` (`jsonld.rs:21, 394-398`), creating a generated/vendored snapshot boundary. The graphd docs incorrectly name `clearhead-core/src/graph/jsonld.rs` as authoritative (`docs/jsonld_export_contract.md:5-9`); implementation now lives in graphd.

There are therefore three surfaces: (1) ontology RDF/SHACL/context/schema normative publication artifacts; (2) graphd’s named-quad insertion/reconstruction and validation; (3) two JSON-LD mechanisms—direct domain export and query response framing. Query `CONSTRUCT` JSON-LD preserves returned ontology RDF, whereas index JSON-LD is an application response profile with provenance and one intentionally non-semantic locator (`docs/query_contract.md:38-48, 75-88`; `shape.rs:163-207`). They should not be described as one dataset contract.

## Minimal deterministic dataset contract (recommendation)

1. **Canonical dataset:** a workspace snapshot is an RDF Dataset containing exactly one named graph `<urn:clearhead:workspace:{stable UUID}>`; no domain/workspace snapshot quads in default graph. Entity IRIs are `urn:uuid:{UUID}`; workspace node equals graph IRI. Keep `urn:context:*` explicitly document-local/provisional until a stable scheme is chosen.
2. **Canonical terms:** freeze the insertion vocabulary listed above, with explicit XSD datatypes. Require Action/Plan/Charter UUID, Action status, and workspace provenance separately from domain semantics. Define containment direction(s) and whether inverses must both be present.
3. **Publication path:** construct JSON-LD from the canonical named graph (or a canonical RDF dataset serializer), using the ontology repository context pinned by content/version; do not independently walk `DomainModel`. `_meta` is JSON envelope metadata, not RDF; either always emit it (current behavior) or omit when empty, but specify one.
4. **Determinism:** canonicalize RFC3339 (recommend UTC `Z` or preserve offsets—choose explicitly); sort nodes by fixed expanded-type rank then expanded IRI; sort all set-valued IRI/literal arrays lexically by expanded RDF term; preserve order only where modeled explicitly (sequential sibling order currently becomes predecessor edges). Specify scalar-vs-array compaction; safest deterministic API is arrays for all multivalued predicates.
5. **Profiles:** keep canonical ontology-out separate from query response profiles. Index ordering remains SPARQL sequence and locator fields are a workspace/application profile. `CONSTRUCT` results are RDF graphs and have no semantic triple order.
6. **Authority:** ontology OWL + SHACL + versioned context should be authoritative for terms/shapes; schema/example/docs are generated or conformance artifacts. Add a reproducible sync/hash check for graphd vendored resources. Implementation docs describe behavior but must not supersede ontology terms.

### Unresolved choices requiring an explicit decision

- Context stable identity and normalization (`+` vs `@`, Unicode/IRI escaping), and whether hierarchy enters canonical ontology-out now (ontology says first-class; graphd doc says provisional).
- Whether Objective is in supported publication scope (ontology says yes; runtime omits it).
- Whether Charter’s children use `actions:hasSubCharter`, BFO `hasPart`, or both; and whether Plan→Charter is materialized (JSON-LD has `partOf`, insertion only Charter→Plan).
- Whether descriptions are `dcterms:description` (context/export) or `rdfs:comment` (insertion)—currently semantically different.
- Plan scheduling contradiction: ontology-out note says dates are act-level, but insertion emits Plan scheduled anchor and validation requires it for recurrence (`ONTOLOGY_OUT_CONTRACT.md:75-82`; `insert.rs:397-406`; `query.rs:182-198`).
- Exact recurrence lexical form (`R:` stripped in RDF, retained by direct JSON-LD).
- Whether external schedule ID/template/created/sequential/charter state and aliases belong in canonical publication; current RDF and JSON-LD are asymmetric.
- Workspace provenance: canonical RDF includes workspace/root/charterRoot and charter source, workspace JSON-LD does not; decide dataset vs editor projection scope and privacy/path portability.
- Date canonicalization (offset-preserving `to_rfc3339()` versus normalized UTC), graph replacement/snapshot semantics, blank-node policy, and whether cross-workspace union queries may merge identical `urn:uuid` or provisional context IRIs.

## Start Here

Open `clearhead-graphd/src/graph/insert.rs` first: it is the most complete statement of the dataset graph actually queried in production. Then compare `clearhead-graphd/src/graph/jsonld.rs` side-by-side; nearly every publication risk is an insertion/export asymmetry.
