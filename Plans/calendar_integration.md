---
Status: Completed
Last Audited: 2026-02-27
---
# Calendar Export Gap Analysis

## Context

The UI.md spec describes a `read acts --format vcalendar --where "..."` command for exporting future
planned acts as iCalendar events. This is a powerful composition of existing primitives. The goal
is to identify every gap between the current implementation and making that command work.

---

## Target Command (from UI.md)

```
clearhead_cli read acts \
  --where "{ ?act a :PlannedAct ; :startTime ?startTime . FILTER(?startTime > NOW()) }" \
  --format vcalendar
```

---

## What Already Exists (Confirmed by Code Review)

| Component | Status | Location |
|---|---|---|
| `format_as_icalendar()` | ✅ Complete | `clearhead-cli/src/export.rs` |
| `icalendar` crate (v0.16.17) | ✅ Dependency | `clearhead-cli/Cargo.toml` |
| `export plans` verb | ✅ Works | `src/commands/plan.rs:399` |
| `--open-only` flag | ✅ Works | `src/argparser.rs:540` |
| `--where` SPARQL filter on `read plans` | ✅ Works | `src/argparser.rs:252` |
| SPARQL/Oxigraph RDF store | ✅ Functional | `src/graph.rs` |
| `load_domain_model()` for PlannedActs | ✅ Exists | `src/graph.rs:611` |
| `insert_planned_act()` | ✅ Exists | `src/graph.rs:759` |
| `scheduledAt` stored in RDF store | ✅ Stored | `src/graph.rs:789` |
| `Action.do_date_time` = scheduled time | ✅ Parsed | `clearhead-core/src/workspace/actions/parser.rs` |

---

## Gaps (in order of priority)

### Gap 0: graph.rs emits the wrong ontology (prerequisite for all RDF work)

**Severity:** Critical — every triple currently inserted under the "domain model" path lands
on non-existent URIs that will never match the ontology, the SHACL shapes, or anything else.
This must be fixed before any SPARQL query on ontology terms or SHACL validation can work.

**What the correct triple pattern looks like** (from `ontology/examples/v4/valid/simple-plan-and-act.ttl`):
```turtle
<urn:uuid:plan-buy-milk> a cco:ont00000974 ;
    rdfs:label "Buy milk" ;
    cco:ont00001942 <urn:uuid:act-buy-milk-001> .   # prescribes

<urn:uuid:act-buy-milk-001> a cco:ont00000228 ;
    cco:ont00001868 actions:NotStarted .            # is_measured_by_nominal
```

**Bug 1 — Wrong CCO namespace URL:**
```rust
// WRONG (old URL, different domain)
const CCO_NS: &str = "http://www.ontologyrepository.com/CommonCoreOntologies/";
// CORRECT (current CCO URL)
const CCO_NS: &str = "https://www.commoncoreontologies.org/";
```

**Bug 2 — Class URIs use human names instead of CCO opaque IDs:**
```rust
// WRONG: produces https://www.commoncoreontologies.org/PlannedAct (does not exist)
cco_class("PlannedAct")
// CORRECT: CCO uses opaque numeric IDs
const CCO_PLAN: &str         = "https://www.commoncoreontologies.org/ont00000974";
const CCO_PLANNED_ACT: &str  = "https://www.commoncoreontologies.org/ont00000228";
const CCO_OBJECTIVE: &str    = "https://www.commoncoreontologies.org/ont00000476";
const CCO_PRESCRIBES: &str   = "https://www.commoncoreontologies.org/ont00001942";
const CCO_STATUS_PROP: &str  = "https://www.commoncoreontologies.org/ont00001868"; // is_measured_by_nominal
const CCO_SUCCESSOR: &str    = "https://www.commoncoreontologies.org/ont00001775"; // is_successor_of
```

**Bug 3 — Status property is custom instead of the CCO property:**
```rust
// WRONG: custom predicate, not in ontology, SHACL PlannedActStatusShape won't fire
v4_pred("hasPhase")
// CORRECT: use cco:ont00001868 (is_measured_by_nominal) with named individuals
// <act> cco:ont00001868 actions:NotStarted .
```
Status values must be the named individuals from the vocabulary:
`actions:NotStarted`, `actions:InProgress`, `actions:Completed`, `actions:Blocked`, `actions:Cancelled`

**Bug 4 — `prescribes` triple is missing from Plan:**
Only the inverse (`prescribedBy`) is stored on PlannedAct. The SHACL `PlanPrescribesShape`
validates `cco:ont00001942 (prescribes)` on Plans — it will never fire. Both directions
should be stored:
```
<plan> cco:ont00001942 <act> .      # prescribes (on Plan)
<act>  actions:prescribedBy <plan> . # inverse (on PlannedAct, optional but useful)
```

**Bug 5 — `scheduledAt` is not defined in the ontology:**
The code stores `v4_pred("scheduledAt")` on PlannedAct. The ontology defines
`actions:hasDoDateTime` with domain `cco:ont00000974` (Plan) — not PlannedAct. For
non-recurring plans, the Plan's `hasDoDateTime` IS the scheduled time. For recurring plans,
each PlannedAct needs its own specific datetime. **This is a genuine ontology gap**: there is
no property for "the specific scheduled datetime of this particular occurrence."

Resolution needed (pick one, update ontology accordingly):
- Add `actions:hasScheduledDateTime` with domain `cco:ont00000228` (PlannedAct)
- Or extend `actions:hasDoDateTime` domain to cover PlannedAct as well

Until this is resolved, SPARQL date filters on PlannedActs cannot use an ontologically
sanctioned predicate.

**Files to change:**
- `clearhead-cli/src/graph.rs`: Fix all CCO namespace constants and class/property references
- `clearhead-core/src/graph.rs`: Same fixes (the two files are near-duplicates and should
  ideally be consolidated — the CLI should use the core graph functions)
- `ontology/site/vocab/actions/actions-vocabulary.ttl`: Add `actions:hasScheduledDateTime`
  property (or extend `hasDoDateTime` domain) to cover PlannedAct occurrence scheduling

### Gap 1: `vcalendar` is not a valid `--format` option

**Severity:** Blocking.

The `Format` enum in `argparser.rs` has: `Actions`, `Json`, `Xml`, `Table`. No `VCalendar`.
The `OutputFormat` enum in `clearhead-core/src/workspace/actions/format.rs` mirrors this.

Currently calendar output requires the separate `export plans` verb — which is a dead end if the
goal is composable `read --format` output. The spec says `--format vcalendar`; that's the right
design and we should support it.

**Files to change:**
- `clearhead-cli/src/argparser.rs`: Add `VCalendar` variant to `Format` enum
- `clearhead-core/src/workspace/actions/format.rs`: Add `VCalendar` to `OutputFormat` enum
- `clearhead-cli/src/commands/plan.rs`: In `read_plans()`, handle `VCalendar` format by calling
  `format_as_icalendar(&actions, false)` instead of the normal format dispatch

### Gap 2: `read acts` subcommand does not exist

**Severity:** Blocking (it's the literal noun in the spec).

`ReadTarget` in `argparser.rs` has `Plans`, `Charters`, `Agenda` — no `Acts`.
`Acts` is the natural noun for "things that are scheduled to happen" (per BFO/CCO alignment). It
should filter the ActionList to only items with `do_date_time` set, i.e., the subset that are
actually scheduled events rather than indefinite tasks.

**Files to change:**
- `clearhead-cli/src/argparser.rs`: Add `Acts` variant to `ReadTarget` with:
  - `--format` (default: `VCalendar` since that's the primary use case)
  - `--where` / `--sparql` / `--sparql-file` (same as Plans)
  - `--file` / `--stdio` for input source
  - `--future-only` (boolean, filter to `do_date_time > now()` without requiring SPARQL)
  - `--output` (write .ics to file instead of stdout)
- `clearhead-cli/src/commands/plan.rs`: Add `read_acts()` function:
  1. Load ActionList from workspace/file/stdin
  2. Filter to `do_date_time.is_some()` (this is the Acts semantic boundary)
  3. Apply optional `--future-only` filter (pure Rust, no SPARQL needed)
  4. Apply SPARQL `--where` filter if provided — **must use new `run_sql_query_planned_acts`
     from Gap 4, NOT the existing v3 `query_actions`**. The existing infrastructure loads
     Actions (v3 schema) and has no cco: prefix, so `cco:PlannedAct` queries would silently
     return nothing.
  5. Dispatch on format: `VCalendar` → `format_as_icalendar`, others → standard format dispatch
- `clearhead-cli/src/main.rs`: Wire `ReadTarget::Acts` to `read_acts()`

### Gap 3: SPARQL datetime typing for `FILTER(?startTime > NOW())`

**Severity:** ~~High~~ → **RESOLVED — no work needed.**

Audited 2026-02-27: `scheduledAt`, `completedAt`, and `createdAt` are already stored as
`xsd:dateTime` typed literals in both `clearhead-cli/src/graph.rs:789-820` and
`clearhead-core/src/graph.rs`. The code is:
```rust
Literal::new_typed_literal(dt.to_rfc3339(), ns(XSD_NS, "dateTime"))
```
Oxigraph's `FILTER(? > NOW())` will work correctly. Nothing to fix here.

### Gap 4: SPARQL query infrastructure uses the wrong vocabulary

**Severity:** High — `read acts --where` cannot work without this, and `read plans --where`
is silently using incorrect predicates.

**Root cause:**

`graph.rs` contains a dead-end legacy loading path (`load_actions`, using `ACTIONS_NS`) that
inserts data under the wrong vocabulary. This path is what `run_sql_query` and
`run_workspace_sql_query` in `lib.rs` call. There is only one domain model and one ontology
— there should be one loading path: `load_domain_model`.

The `ACTIONS_NS` constant (the one with a version number in the URL) is a code smell and
should be removed. The canonical URIs are:
- `https://clearhead.us/vocab/actions/` (the actions ontology, no version suffix)
- `http://www.ontologyrepository.com/CommonCoreOntologies/` (CCO)

Ontologies are not versioned breaking changes. There is no "v3" and "v4". There is just
the domain model.

**What needs to be fixed:**

1. **`build_where_query()` in `graph.rs`**: Replace the legacy actions namespace with
   the canonical one. Add `PREFIX cco:`. The id binding should use the domain model
   predicate (`actions:id` under the canonical namespace).

2. **`run_sql_query` / `run_workspace_sql_query` in `lib.rs`**: Replace `load_actions`
   with `load_domain_model`. Both `read plans` and `read acts` then use the same
   vocabulary consistently.

3. **Remove `ACTIONS_NS` and the legacy `load_actions` / `insert_action` path** from
   `graph.rs` once the above callers are updated. This is cleanup, not new functionality.

4. **Load the ontology vocabulary into the store alongside data.** When Oxigraph is
   initialized with RDFS reasoning enabled, loading the vocabulary TTL gives you:
   - Type propagation up the class hierarchy (`Charter` → `DirectiveICE` automatically)
   - Named individuals as real IRIs for SPARQL matching
   - Property domain/range entailment
   This makes queries more expressive without hardcoding every class name.

The PlannedAct → Action mapping is clean: `convert::split_action` sets `plan_id = action.id`,
so a matched PlannedAct's `plan_id` directly identifies the source Action.

**Files to change:**
- `clearhead-cli/src/graph.rs`: Fix `build_where_query()` prefix declarations; remove legacy namespace constant and loading path; load vocabulary TTL at store init
- `clearhead-cli/src/lib.rs`: Update query functions to use `load_domain_model`
- `clearhead-cli/docs/UI.md`: Fix the example predicates (`:PlannedAct` → `cco:PlannedAct`, `:startTime` → `actions:scheduledAt`)
- `clearhead-cli/src/argparser.rs`: Add namespace cheat-sheet to `--where` help text on `Acts` subcommand

### Gap 6 (was Gap 5): `--future-only` convenience flag (nice-to-have)

**Severity:** Low — the SPARQL `--where` covers this, but ergonomics matter.

The spec's calendar example is fundamentally "give me future scheduled acts as iCalendar". Forcing
users to write the SPARQL FILTER every time is bad UX for the primary use case. A `--future-only`
flag on `read acts` should apply `FILTER(?scheduledAt > NOW())` without requiring the user to know
SPARQL.

This can be implemented as an in-Rust filter before the SPARQL step: `action.do_date_time > Local::now()`.

---

## Vendoring: Ontology Files in clearhead-cli

The `ontology/` repo is already a platform-level submodule. But `clearhead-cli` is its own
submodule — when built standalone it has no access to the platform tree. Two files need to be
available at runtime and test time:

| File | How to vendor | Purpose |
|---|---|---|
| `actions-vocabulary.ttl` | `include_str!` in `graph.rs` | Loaded into Oxigraph store at init; gives RDFS inference, named individuals as IRIs, class hierarchy traversal |
| `shapes.ttl` | `include_str!` in validation module | Passed to SHACL processor (`rudof`) at save/lint boundaries |
| `examples/v4/valid/*.ttl` | Copy to `clearhead-cli/tests/fixtures/ontology/valid/` | Roundtrip tests: assert graph.rs output matches known-correct Turtle |
| `examples/v4/invalid/*.ttl` | Copy to `clearhead-cli/tests/fixtures/ontology/invalid/` | SHACL violation tests: assert each invalid example triggers the right constraint |

**What NOT to vendor:** The `.owl` files are for Protégé and OWL reasoners. The CLI does not
need OWL DL reasoning at runtime — RDFS inference from the TTL is sufficient.

**Oxigraph RDFS reasoning note:** Oxigraph's RDFS reasoning flag enables type propagation,
domain/range entailment, and property hierarchy inference. It does NOT do OWL DL (no property
chains, no disjointness, no owl:inverseOf inference). Forward and inverse triples (`prescribes`/
`prescribedBy`) must both be stored explicitly — Oxigraph will not infer one from the other even
with the owl:inverseOf declaration in the ontology.

**SHACL runtime note:** Oxigraph has no built-in SHACL processor. Add `rudof` (or equivalent
Rust SHACL crate) as a `clearhead-cli` dependency to execute the shapes at validation boundaries.
The shapes file's SPARQL-based constraints (`NoCyclicDependenciesShape`, `CompletedActDateShape`,
etc.) will execute correctly because they embed their own SPARQL queries.

---

## What Does NOT Need to Be Built

- **Recurrence expansion** — **OPEN QUESTION.** Currently `format_as_icalendar` passes RRULE
  directly to the VEVENT. The user has noted we should support BOTH RRULE and per-occurrence
  expansion, with individual events as the default.
  - Concern with individual-events-as-default: requires bounding expansion ("how far?"),
    loses series grouping in calendar apps, RRULE is the semantically correct representation.
  - Counter-argument: simpler importers and debugging tools benefit from seeing concrete dates.
  - Proposed resolution: add `--expand-recurrences` flag (opt-in, requires `--until DATE` or
    `--count N` to bound), keep RRULE as default. Revisit before shipping if the primary
    use-case data says otherwise.
- **A new query language** — SPARQL `--where` is expressive enough.
- **New iCalendar library** — `icalendar` crate v0.16 is sufficient.
- **Separate export verb for acts** — Unifying under `read --format vcalendar` is better design.

---

## Recommended Implementation Order

1. ~~**Gap 3** (xsd:dateTime typing)~~ — **DONE**. Already correct. Skip.
2. **Gap 0** (fix graph.rs ontology alignment) — prerequisite for all RDF work:
   - Fix CCO namespace URL and replace human-name class references with CCO OBO IDs
   - Fix status property (`hasPhase` → `cco:ont00001868` + named individuals)
   - Add `prescribes` forward triple on Plan
   - Resolve `hasScheduledDateTime` gap in ontology + update graph.rs accordingly
   - Add roundtrip tests: load ontology examples (valid/ and invalid/), assert RDF output
     matches known-correct Turtle and SHACL violations fire on invalid examples
3. **Gap 1** (vcalendar format) — add `VCalendar` to `Format` enum and `OutputFormat` enum,
   wire it in `read plans`. End-to-end calendar output test before adding the new noun.
4. **Gap 2** (`read acts` noun, basic) — add `Acts` to `ReadTarget` with `--format`,
   `--future-only`, `--file`, `--stdio`. Implement `read_acts()` with:
   - `do_date_time.is_some()` filter
   - `--future-only` in-Rust filter
   - `VCalendar` dispatch
   - No SPARQL yet (defer `--where` to step 5)
5. **Gap 4** (fix query infrastructure) — fix `build_where_query()` to use canonical
   namespace URIs and `cco:`, update query functions to load DomainModel, delete the
   legacy `ACTIONS_NS` loading path. Wire `--where` / `--sparql` / `--sparql-file`
   into `read_acts()`.
6. **Gap 5** (docs/namespace fix) — update UI.md example and add namespace cheat-sheet
   to `--where` help text. Now that the infrastructure exists, the example is testable.
7. **Gap 6** (`--future-only` flag) — already wired in step 4; confirm it works correctly
   when combined with `--where` SPARQL.

---

## Critical Files

| File | Change Needed |
|---|---|
| `clearhead-cli/src/graph.rs` | Fix CCO namespace, class/property URIs, status property, prescribes triple |
| `clearhead-core/src/graph.rs` | Same fixes as CLI graph.rs (near-duplicate — consider consolidating) |
| `ontology/site/vocab/actions/actions-vocabulary.ttl` | Add `actions:hasScheduledDateTime` on PlannedAct |
| `clearhead-cli/src/argparser.rs` | Add `VCalendar` to `Format`, add `Acts` to `ReadTarget` |
| `clearhead-core/src/workspace/actions/format.rs` | Add `VCalendar` to `OutputFormat` |
| `clearhead-cli/src/commands/plan.rs` | Add `read_acts()`, update `read_plans()` for vcalendar |
| `clearhead-cli/src/main.rs` | Wire `ReadTarget::Acts` |
| `clearhead-cli/src/lib.rs` | Update query functions to use `load_domain_model` |
| `clearhead-cli/docs/UI.md` | Fix namespace example (`:PlannedAct` → `cco:PlannedAct`, `:startTime` → `actions:scheduledAt`) |

---

## Verification

End-to-end test after implementation:

```bash
# Basic: all acts as calendar
clearhead_cli read acts --format vcalendar

# Filtered to future acts only (ergonomic flag)
clearhead_cli read acts --format vcalendar --future-only

# Full SPARQL filter (as spec'd in UI.md)
clearhead_cli read acts \
  --where "{ ?act a cco:PlannedAct ; actions:scheduledAt ?t . FILTER(?t > NOW()) }" \
  --format vcalendar

# Pipe to calendar app (macOS example)
clearhead_cli read acts --format vcalendar --future-only > /tmp/clearhead.ics
open /tmp/clearhead.ics

# Table view of acts (non-calendar format)
clearhead_cli read acts --format table
```

Unit test additions:
- `format_as_icalendar` with future-only filter
- `read_acts()` with no datetime actions filtered out
- SPARQL FILTER on xsd:dateTime (integration test)
