# Graph Modularization + Export Redesign

## Context

After the CLI/core rework, the codebase has accumulated several problems that make workspace-wide
serialization hard to extend cleanly:

1. **Duplicated graph code**: Both `clearhead-core/src/graph.rs` (~1091 lines) and
   `clearhead-cli/src/graph.rs` (~900 lines) exist with heavily overlapping v3 + v4 content.
   Core already has oxigraph as a dependency.
2. **Dead v3 legacy**: The v3 `Action`-based RDF path (insert_action, get_action_by_id,
   build_where_query with v3 namespace) exists in both crates and is no longer the domain
   model. v4 (Plan/PlannedAct/DomainModel) is the forward path.
3. **Broken SQL query tests**: `tests/sql_queries.rs` uses SQL predicates (`priority = 1`,
   `state = 'completed'`) injected into SPARQL templates — never worked, all pre-existing failures.
4. **Flat export**: `export.rs` in CLI operates on a single flat `ActionList`, not the full
   workspace (charters, plans, acts). Export should be workspace-wide via `DomainModel`.
5. **iCal coupled to old types**: `format_as_icalendar` takes `&ActionList` using the legacy
   `Action` type with `do_date_time`. Should operate on `PlannedAct` + `Plan` pairs from
   `DomainModel`.
6. **Export CLI API broken**: 12 integration tests in `tests/export.rs` use the pre-verb-noun
   CLI (`export <file>`) rather than the current `export plans <file>`.

**Goal**: Modularize `graph/` properly, delete v3, consolidate duplicate code into core,
redesign iCal export to operate on the full `DomainModel`, and fix the export CLI surface.

---

## Module Structure After Refactor

```
clearhead-core/src/
  graph/               ← RESTRUCTURED from graph.rs
    mod.rs             ← pub API: re-exports all public symbols
    vocab.rs           ← namespace constants (ACTIONS_V4_NS, CCO_NS, XSD_NS, SCHEMA_NS, SKOS_NS)
                          IRI builder helpers (ns(), v4_pred(), cco_class(), etc.)
    store.rs           ← oxigraph Store: create_store(), load_domain_model(),
                          insert_plan(), insert_planned_act(), load_tag_hierarchies()
    query.rs           ← SPARQL: query_plans(), query_acts(), query_action_ids(),
                          get_plan_by_id(), get_planned_act_by_id(), build_where_query()
    turtle.rs          ← Turtle output: serialize_acts_to_turtle(),
                          serialize_open_acts_to_turtle(), serialize_closed_acts_to_turtle(),
                          filter_model_by_phase(), store_to_turtle()
  calendar.rs          ← NEW: CalEvent struct, calendar_events(&DomainModel, bool) -> Vec<CalEvent>
  lib.rs               ← add `pub mod calendar;`, update graph re-exports

clearhead-cli/src/
  graph.rs             ← DELETE (everything moves to core or is removed with v3)
  export.rs            ← REWRITE: CalEvent → icalendar::Event → .ics string
                          fn to_ical_string(events: &[CalEvent]) -> Result<String>
  lib.rs               ← remove `pub mod graph`, delegate to clearhead_core::graph,
                          update run_sql_query/run_workspace_sql_query to use v4 path,
                          add `pub use clearhead_core::calendar::*`
  commands/plan.rs     ← update export_plans: load workspace → DomainModel → calendar_events → ical
  argparser.rs         ← rename ExportTarget::Plans → ExportTarget::Ical
                          add optional `file` positional arg (single file or workspace default)
  main.rs              ← update export dispatch arm

tests/
  sql_queries.rs       ← DELETE (SQL interface never materialized; all pre-existing failures)
  export.rs            ← REWRITE 12 tests to use `export ical [<file>]` new CLI surface
```

---

## Step-by-Step Changes

### Step 1 — Restructure `clearhead-core/src/graph.rs` → `graph/`

**Source of truth**: `clearhead-core/src/graph.rs` is the canonical version (more complete: has
`query_plans`, `query_acts`, `serialize_*_to_turtle`, `filter_model_by_phase`, full hydration).

1. Create `clearhead-core/src/graph/` directory
2. Create `graph/vocab.rs` — extract all namespace constants and `ns()`/`v4_pred()`/`cco_class()`/
   `phase_node()` helper functions. No oxigraph types needed here, just `NamedNode` for the
   IRI builders (or make them return `String` and move NamedNode construction to store.rs).
3. Create `graph/store.rs` — `create_store()`, `load_domain_model()`, `insert_plan()`,
   `insert_planned_act()`, `load_tag_hierarchies()`. Imports from `vocab.rs`.
   **DELETE all v3 code**: remove `insert_action()`, `load_actions()`, `load_actions_with_source()`,
   `action_pred()`, `schema_pred()` (if v3 only), v3 ACTIONS_NS constant.
4. Create `graph/query.rs` — `query_plans()`, `query_acts()`, `query_action_ids()`,
   `get_plan_by_id()`, `get_planned_act_by_id()`, `build_where_query()` (v4 namespace).
   **DELETE v3 query functions**: remove `query_actions()` (string id), `get_actions_from_query()`,
   `get_action_by_id()`, `get_actions_from_sql()`, `query_actions_by_context()`,
   `query_actions_by_project()`.
5. Create `graph/turtle.rs` — `serialize_acts_to_turtle()`, `serialize_open_acts_to_turtle()`,
   `serialize_closed_acts_to_turtle()`, `filter_model_by_phase()`, `store_to_turtle()`.
6. Create `graph/mod.rs` — `pub mod vocab; pub mod store; pub mod query; pub mod turtle;`
   plus `pub use` re-exports for all public API symbols.
7. Update `clearhead-core/src/lib.rs` — change `pub mod graph;` (stays) but ensure the
   public re-exports reflect the new submodule structure.
8. Delete `clearhead-core/src/graph.rs`.

**Move tests**: The `#[cfg(test)] mod v4_tests` block at the bottom of core's graph.rs should
be split into per-file inline tests in `store.rs`, `query.rs`, and `turtle.rs`.

---

### Step 2 — Delete `clearhead-cli/src/graph.rs`

CLI's graph.rs is largely duplicate of core's. After Step 1:

1. In `clearhead-cli/src/lib.rs`:
   - Remove `pub mod graph;` and `pub use graph as sql;`
   - Add `pub use clearhead_core::graph;` and keep `pub use graph as sql;` alias for any
     callers not yet updated
   - Update `run_sql_query()` and `run_workspace_sql_query()` to use
     `clearhead_core::graph::store::load_domain_model()` and v4 query path instead of v3
     `load_actions_with_source()`. The workspace path needs:
     ```
     load_workspace() → Workspace
     convert::from_actions(workspace.actions) → DomainModel
     load_domain_model(&store, &model)
     query_plans(&store, sparql)  ← returns Vec<Plan>, map back to ActionList via to_action_list()
     ```
   - Update `build_where_query` references to use v4 namespace version from `clearhead_core::graph`
2. Delete `clearhead-cli/src/graph.rs`.
3. The only CLI-specific graph function was `load_tag_hierarchies` taking `&Config` — this is
   now in `clearhead_core::graph::store` taking `&HashMap<String, Vec<String>>` which is
   what Config.tag_hierarchies already is. No special CLI wrapper needed.

---

### Step 3 — Add `clearhead-core/src/calendar.rs`

New file implementing the iCal data model in pure domain terms (no `icalendar` crate dep):

```rust
pub struct CalEvent {
    pub uid: String,           // UUID of the PlannedAct
    pub summary: String,       // Plan name
    pub description: Option<String>,
    pub dtstart: DateTime<Utc>,
    pub dtend: DateTime<Utc>,
    pub rrule: Option<String>, // pre-formatted "FREQ=DAILY;..." (no "R:" prefix)
    pub status: CalEventStatus,
    pub priority: Option<u32>, // iCal priority (1-9 scale)
    pub categories: Option<Vec<String>>,
    pub completed: Option<DateTime<Utc>>,
}

pub enum CalEventStatus { Tentative, Confirmed, Cancelled }

/// Produce calendar events from a DomainModel.
/// Pairs each PlannedAct with its Plan to get summary/contexts/recurrence.
/// `open_only`: skip Completed and Cancelled acts.
pub fn calendar_events(model: &DomainModel, open_only: bool) -> Vec<CalEvent>
```

Key logic in `calendar_events`:
- For each `PlannedAct` in `model.all_acts()` that has `scheduled_at`:
  - Find its `Plan` via `model.plan(act.plan_id)`
  - Map `act.phase` → `CalEventStatus`
  - Map `plan.priority` → iCal scale (1→1, 2→3, 3→5, 4→7, _→5)
  - Strip `"R:"` prefix from plan's recurrence Display string
  - Duration: `act.duration.or(plan.duration).unwrap_or(15)` minutes

Export the priority mapping and status mapping functions so CLI export.rs can reuse them.

Update `clearhead-core/src/lib.rs`: add `pub mod calendar; pub use calendar::*;`

---

### Step 4 — Rewrite `clearhead-cli/src/export.rs`

Replace the current `ActionList`-based implementation with one that:
- Takes `&[CalEvent]` (from core's `calendar_events()`)
- Maps each `CalEvent` → `icalendar::Event`
- Returns `Result<String>`

```rust
pub fn to_ical_string(events: &[CalEvent]) -> Result<String, String>
```

The `format_as_icalendar(list: &ActionList, open_only: bool)` function is removed.
Update `clearhead-cli/src/lib.rs` to remove `pub use export::format_as_icalendar`.

---

### Step 5 — Update export CLI surface

**`clearhead-cli/src/argparser.rs`**:

```rust
#[derive(Subcommand)]
pub enum ExportTarget {
    /// Export planned acts to iCalendar (.ics) format
    Ical {
        /// File to export (.actions format). If omitted, exports the full workspace.
        file: Option<PathBuf>,
        /// Output file. If omitted, writes to stdout.
        #[arg(short, long)]
        output: Option<PathBuf>,
        /// Only export open acts (pending, in-progress, blocked)
        #[arg(long)]
        open_only: bool,
    },
    /// Export workspace as RDF Turtle (.ttl) format
    Rdf {
        #[arg(short, long)]
        output: Option<PathBuf>,
        /// Only export open acts
        #[arg(long)]
        open_only: bool,
    },
}
```

**`clearhead-cli/src/commands/plan.rs`** — `export_plans` → `export_ical`:

```rust
pub fn export_ical(ctx, file, output, open_only) -> Result<(), String> {
    let model = if let Some(path) = file {
        // Single file: parse → DomainModel
        let actions = load_file(path)?;
        clearhead_core::workspace::actions::convert::from_actions(&actions)
    } else {
        // Workspace: discover all files → DomainModel
        let workspace = clearhead_cli::workspace::load_workspace(&ctx.data_dir)?;
        clearhead_core::workspace::actions::convert::from_actions(
            &workspace.actions.to_action_list()
        )
    };
    let events = clearhead_core::calendar::calendar_events(&model, open_only);
    let ical = clearhead_cli::export::to_ical_string(&events)?;
    // write to output or stdout
}
```

Add `export_rdf` similarly: load workspace → DomainModel → `serialize_acts_to_turtle()`.

**`clearhead-cli/src/main.rs`** — update the `Verb::Export` match arm for `Ical` and `Rdf`.

---

### Step 6 — Fix test suite

**Delete** `clearhead-cli/tests/sql_queries.rs` — the SQL-predicate-in-SPARQL interface
(`priority = 1`, `state = 'completed'`) was never implemented and all 9 tests are
pre-existing failures. The v4 SPARQL interface is the correct path forward.

**Rewrite** `clearhead-cli/tests/export.rs` — 12 tests use the old `export <file>` API.
Update to `export ical <file>` (positional arg, no `plans` subcommand):

```rust
env.command()
    .arg("export")
    .arg("ical")
    .arg(&file)      // positional file arg
    .assert()
    .success()
    ...
```

Tests for stdin: `.arg("export").arg("ical")` with `.write_stdin(actions)`.
Tests for output file: add `.arg("-o").arg(&output_file)`.
Tests for open-only: add `.arg("--open-only")`.

---

### Step 7 — Cleanup `clearhead-core/Cargo.toml`

Remove `automerge` and `autosurgeon` dependencies — they were part of the CRDT module that
was removed from active use (reserved for future JS sync server per Decision 19, but the
Rust crate no longer needs these deps since `crdt.rs` is now a stub).

---

## Files Changed Summary

| File | Action |
|------|--------|
| `clearhead-core/src/graph.rs` | DELETE → split into `graph/` |
| `clearhead-core/src/graph/mod.rs` | CREATE |
| `clearhead-core/src/graph/vocab.rs` | CREATE |
| `clearhead-core/src/graph/store.rs` | CREATE |
| `clearhead-core/src/graph/query.rs` | CREATE |
| `clearhead-core/src/graph/turtle.rs` | CREATE |
| `clearhead-core/src/calendar.rs` | CREATE |
| `clearhead-core/src/lib.rs` | EDIT (add calendar, update graph exports) |
| `clearhead-core/Cargo.toml` | EDIT (remove automerge/autosurgeon) |
| `clearhead-cli/src/graph.rs` | DELETE |
| `clearhead-cli/src/export.rs` | REWRITE |
| `clearhead-cli/src/lib.rs` | EDIT (delegate graph to core, update run_sql_*) |
| `clearhead-cli/src/argparser.rs` | EDIT (ExportTarget::Plans→Ical, add Rdf) |
| `clearhead-cli/src/commands/plan.rs` | EDIT (export_plans→export_ical, add export_rdf) |
| `clearhead-cli/src/main.rs` | EDIT (update Verb::Export dispatch) |
| `clearhead-cli/tests/sql_queries.rs` | DELETE |
| `clearhead-cli/tests/export.rs` | REWRITE |

---

## Important Notes

**Charter-DomainModel wiring gap**: `workspace::load_workspace()` returns
`Workspace { charters, actions }` but `convert::from_actions()` puts everything in a synthetic
"inbox" charter. For a future "fully-chartered export" (events grouped by charter in iCal,
charter nodes in RDF), a `convert::from_workspace()` function would be needed. This is
**out of scope** for this PR — the current `from_actions()` path is sufficient to fix the
broken export and unblock the architecture. File an issue.

**`--where` integration tests**: The `read plans --where "priority = 1"` integration tests
are pre-existing failures that use SQL predicates. After the v4 SPARQL rebuild, they need to
be rewritten with proper SPARQL triple patterns
(`?s actions:hasPriority "1"^^xsd:integer`). Out of scope here — they were already failing.

---

## Verification

```bash
# 1. Core builds and tests pass
cd clearhead-core && cargo test

# 2. CLI builds
cd clearhead-cli && cargo build

# 3. Export tests pass (after rewrite)
cd clearhead-cli && cargo test --test export

# 4. Turtle serialization still works (core graph tests)
cd clearhead-core && cargo test graph

# 5. End-to-end: export a single file to ical
echo "[ ] Meeting @2026-02-25T14:00 D30" | cargo run -- export ical

# 6. End-to-end: export workspace to turtle
cargo run -- export rdf
```
