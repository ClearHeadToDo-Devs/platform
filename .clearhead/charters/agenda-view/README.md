---
state: Active
description: Cross-cutting agenda view spanning core query logic, CLI index queries, and Neovim quickfix integration with change routing via canonical ids
---

# Agenda View

A named-query agenda system that surfaces the right actions at the right time.
Built-in opinionated views encode a sensible default process — users get daily
and weekly perspectives without having to invent their own query language.

## The Core Idea

Each agenda is a named SPARQL query against the workspace graph. The query *is*
the wisdom — transparent, inspectable, overridable. The plugin renders results as
a virtual `ft=actions` buffer so all existing keybindings and LSP features work.
State mutations route back to source files via UUID.

## Built-in Views

**unscheduled** — shows unplanned stuff that is not specifically due 
  - open/in-progress, no open predecessors
    - IE NOT blocked 
  - due/start date is empty for action and parents
  - sorted by priority

**upcoming**: intended to be the "calendar" view that shows upcoming work
  - root action due/start date of this week or earlier
  - sorted by due date, then priority

## Layers

- **core** — named agenda queries alongside `run_workspace_sql_query`
- **cli** — `clearhead query index agenda` command
- **lsp** — decide: new LSP command vs plugin calls CLI directly
- **nvim** — picker client today; quickfix/user_data loop and verb routing still to land

## Output Contract & Direction (2026-07-05)

The agenda conforms to the [Query Output Specification](../../../specifications/query_output.md).
The current slice ships the **core/CLI index seam** and a thin picker client in
Neovim; the forward direction closes that into a **live index**, not an editable
projection:

- The agenda is a flat, ordered **list** — a `SELECT` framed as a JSON-LD `@graph`. Its
  "aliveness" is emergent: predicates over mutable relational state (open predecessors,
  open parents) mean completing one action surfaces its successors on the next run. No
  reactive machinery — just a cheap, idempotent re-query.
- Identity is canonical and stable, exported to clients as **`id`** (the compacted
  JSON-LD alias of semantic `@id`, not `source_line` — a line number is fine to *jump*
  to but too fragile to *act* on). This is the address mutation verbs target.
- The loop is **read → verb-by-id → re-read**, refresh gated on an explicit save.
  The plugin work still to land is mapping each JSON-LD node to a quickfix entry:
  `id` → `user_data`, locator → `filename`/`lnum`, composed display → `text`. The line
  number navigates; the `id` acts.
- Celebration/provenance of *how* an action surfaced belongs to analytics, not here —
  this is the workhorse "just do it" list. Silent re-settle; keep the user's place.

## The Index Shape (2026-07-07)

The response shape formerly called `qflist` is renamed **index** — the widget name
leaked Neovim into the engine, exactly the seam violation query_output.md warns
against. An index is the dictionary sense: ordered, display-labeled, locator-bearing
entries, plus canonical identity exported as `id` so each entry is addressable.

The logic/shape border is the SPARQL query itself: `WHERE` carries the query logic
(the wisdom), the `SELECT` projection satisfies the shape's contract (`id`, `name`,
`status`, `source_file`, `source_line`, `charter_root`; sort keys when bound). The
engine validates the projection, never composes or repairs. Future shapes slot
alongside: `table` for aggregates, `graph` for networks.

Consequences landed with the rename: the duplicate contract-less agenda query is
collapsed (one agenda, one source of truth) and `read agenda` is removed — an agenda
is a query, so `clearhead query index agenda` is the single entry point.
