---
id: c207c553-0408-4379-be65-a3a2d5336203
alias: action-lifecycle
state: Active
---
# Action Lifecycle Tracking

Formalizes how lifecycle events (creation, completion, cancellation, reopening) are
modeled, stored, and propagated across the platform stack.

## Design Decisions

**Two parallel domain models, not one.**
The entity model (Action, Plan, Charter) describes what exists. The event model
describes semantic modifications to those entities. These evolve independently.

**ActionStateRecord is a Descriptive ICE.**
A record of a state change is itself an information artifact — a Descriptive
Information Content Entity that describes a characteristic change in an Action.
This belongs in the InformationEntityOntology, not the EventOntology. The telemetry
log is a collection of ActionStateRecords; the sidecar is a materialized summary of
the most recent record per event type.

**Single event class, enumerated types.**
Rather than a class per event type (explosion), one `actions:ActionStateRecord` class
with `hasEventType` whose range is `owl:oneOf` named individuals:
ActionCreated, ActionCompleted, ActionCancelled, ActionReopened.

**No implementation details in the ontology.**
Predicates define meaning, not storage. Comments referencing DSL syntax (`%`, `^`),
JSON paths, or UUIDv7 derivation are implementation leakage and must be stripped.
Implementation mappings belong in the JSON schema and code documentation.

**Sidecar rename and schema redesign.**
`acts` → `actions` throughout (post-Decision 25 nomenclature). `created` moves from
top-level into a `lifecycle` object. New fields: `completed`, `cancelled`, `reopened`.
Clean break — no migration shims. Existing sidecar files re-stamp on next save.

**Correct propagation order.**
Ontology → JSON Schema → Domain Struct → Sidecar → CLI → LSP → Plugin.
No layer should be modified before the layer above it is settled.

## Open Questions

- Should `ActionStateRecord` subclass a specific CCO Descriptive ICE subtype, or
  sit directly under DescriptiveInformationContentEntity?
- Does the event ontology file live alongside `actions-vocabulary.owl` or merge in?

## Open Question: Is the Sidecar Still Needed for Lifecycle Fields?

The telemetry system (`~/.local/state/clearhead/telemetry/events-YYYY-MM.ndjson`)
already emits `action_completed`, `action_cancelled`, `action_restarted` with
`action_uuid` as the correlation key. This IS a queryable event store (DuckDB, jq).
`ActionStateRecord` in the ontology maps directly to what each NDJSON entry is.

The observability spec explicitly says telemetry is NOT for current state — that
boundary was deliberate. So the sidecar lifecycle fields (`completed`, `cancelled`,
`reopened`) would serve as the current-state snapshot that tooling reads without
querying NDJSON files.

But the question stands: is that snapshot worth the sync complexity, or should
tooling query telemetry directly for lifecycle timestamps when needed? If queries
are cheap enough (DuckDB on local NDJSON is fast), the sidecar lifecycle fields
may be unnecessary — and `created` + `source_vevent` might be all the sidecar
ever needs to carry.
