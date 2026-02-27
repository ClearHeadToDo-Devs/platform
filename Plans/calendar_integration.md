---
Status: Planned
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
  2. Filter to `do_date_time.is_some()`
  3. Apply optional `--future-only` filter
  4. Apply SPARQL `--where` filter if provided (reuses existing `query_actions`)
  5. Dispatch on format: `VCalendar` → `format_as_icalendar`, others → standard format dispatch
- `clearhead-cli/src/main.rs`: Wire `ReadTarget::Acts` to `read_acts()`

### Gap 3: SPARQL datetime typing for `FILTER(?startTime > NOW())`

**Severity:** High — the spec's killer feature.

SPARQL `FILTER(?startTime > NOW())` only works if `scheduledAt` is stored as a typed
`xsd:dateTime` literal, not a plain string. If it's stored as a plain string, Oxigraph will
silently return no results rather than error.

**Files to check/fix:**
- `clearhead-cli/src/graph.rs` around line 789-795: Verify `scheduledAt` is inserted as:
  ```
  Literal::new_typed_literal(dt.to_rfc3339(), xsd::DATE_TIME)
  ```
  NOT as:
  ```
  Literal::new_simple_literal(dt.to_string())
  ```
- Same check for `completedAt`, `createdAt` in `insert_planned_act()` and `insert_action()`

### Gap 4: SPARQL namespace mismatch with UI.md example

**Severity:** Medium (documentation / UX correctness).

The UI.md example uses `:PlannedAct` and `:startTime` but:
- The actual class URI is `cco:PlannedAct` (not `:PlannedAct`)
- The actual property URI is `actions:scheduledAt` (not `:startTime`)

The query builder in `graph.rs` declares these prefixes:
```
PREFIX actions: <https://clearhead.us/vocab/actions/v4#>
PREFIX cco: <https://www.ontologyrepository.com/CommonCoreOntologies/Mid/...>
```

**Files to change:**
- `clearhead-cli/docs/UI.md`: Update the example to use correct property names:
  ```
  clearhead_cli read acts \
    --where "{ ?act a cco:PlannedAct ; actions:scheduledAt ?startTime . FILTER(?startTime > NOW()) }" \
    --format vcalendar
  ```
- `clearhead-cli/src/argparser.rs`: Add namespace cheat-sheet to the `--where` help text so
  users can discover the correct prefixes without reading source code.

### Gap 5: `--future-only` convenience flag (nice-to-have)

**Severity:** Low — the SPARQL `--where` covers this, but ergonomics matter.

The spec's calendar example is fundamentally "give me future scheduled acts as iCalendar". Forcing
users to write the SPARQL FILTER every time is bad UX for the primary use case. A `--future-only`
flag on `read acts` should apply `FILTER(?scheduledAt > NOW())` without requiring the user to know
SPARQL.

This can be implemented post-Gap-3 by adding an in-Rust filter: `action.do_date_time > Local::now()`.

---

## What Does NOT Need to Be Built

- **Recurrence expansion into individual events** — `format_as_icalendar` passes RRULE directly
  to the VEVENT, which is correct. Calendar apps (Google Calendar, macOS Calendar) handle
  expansion themselves. Expanding server-side would produce many duplicate events.
- **A new query language** — SPARQL `--where` is expressive enough.
- **New iCalendar library** — `icalendar` crate v0.16 is sufficient.
- **Separate export verb for acts** — Unifying under `read --format vcalendar` is better design.

---

## Recommended Implementation Order

1. **Gap 3** (xsd:dateTime typing) — audit first, fix if needed. Small but breaks the SPARQL
   date filter silently if wrong.
2. **Gap 1** (vcalendar format) — adds `VCalendar` to `Format` enum and wires it in `read plans`.
   Lets us test calendar output end-to-end before adding the new noun.
3. **Gap 2** (`read acts` noun) — once `--format vcalendar` works, add the `Acts` noun that
   defaults to it and applies the `do_date_time.is_some()` filter.
4. **Gap 4** (docs/namespace fix) — update UI.md example and --where help text.
5. **Gap 5** (`--future-only` flag) — last, purely ergonomic.

---

## Critical Files

| File | Change Needed |
|---|---|
| `clearhead-cli/src/argparser.rs` | Add `VCalendar` to `Format`, add `Acts` to `ReadTarget` |
| `clearhead-core/src/workspace/actions/format.rs` | Add `VCalendar` to `OutputFormat` |
| `clearhead-cli/src/commands/plan.rs` | Add `read_acts()`, update `read_plans()` for vcalendar |
| `clearhead-cli/src/main.rs` | Wire `ReadTarget::Acts` |
| `clearhead-cli/src/graph.rs` | Verify xsd:dateTime typing on scheduledAt |
| `clearhead-cli/docs/UI.md` | Fix namespace example |

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
