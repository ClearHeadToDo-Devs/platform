---
id: 019f5841-1012-7fa2-9d9d-57dec5d906c7
alias: caldav-integration
parent: platform
objectives:
  - calendar-view
  - data-integration
state: Active
---
# VTODO Bidirectional sync

While the VEVENT is fine for integration, the true next-steps for us will be about building out the VTODO integration such that we can manage scheduled actions entirely from the calendar view exactly where they were always destined to be.

while we got the sync mechanism down for a single column we have a few functionality and non-functional goals for this charter

## Bidrectional sync
the first goal is that both layers can both read and edit. changes in actions should flow to the calendar, changes in the events should flow to actions

this includes:
- start date
- due date
- state 
- title
- description

we will use the integration points that already exist, especially templates
and the configured plans vdir. Sync bookkeeping does not belong in charter
sidecars or the domain model.

still, we are going to need to go another level of strong to get it all working properly and we are going to want to be doing the most cononacle version of this so that we are able to do this right rather than just this event structure we have

## The vdir boundary

ClearHead integrates with a configured plans path containing one RFC 5545
component per `.ics` file: a vdir. That filesystem convention is the complete
boundary. A user may put vdirsyncer and CalDAV, Syncthing, Git, a mounted
filesystem, or nothing at all behind it; core and the CLI neither know nor
care. Configuring the plans path is the only integration configuration.

## Design notes (2026-07-12)

Grounded in the existing code (`clearhead-core/src/workspace/calendar/{ics,reconcile}.rs`), not just the abstract goal:

**VTODO is primary, full stop — for actions *and* recurring plans.** `action_to_vevent`
requires `scheduled_at` — an unscheduled action can't be represented at all
today. VTODO doesn't require `DTSTART`; it uses `DUE`/`COMPLETED` instead.
Recurrence isn't a VEVENT-specific feature either — RRULE/EXDATE apply to any
recurring component per RFC 5545, and the `icalendar` crate (0.17) reflects
that: `Todo` gets `event_impl!` same as `Event`, so `.starts()`, `.recurrence()`
(RRULE), `.exdate()` all work identically, alongside `Todo`-specific
`.due()`/`.completed()`/`.status()`. (Earlier draft of this doc assumed VEVENT
had to own recurrence — that was an unexamined carryover from "that's what the
current code does," not an actual constraint.)

So: VTODO becomes the *only* representation ClearHead emits for its own data —
both one-off actions and recurring plans (RRULE lives right on the VTODO, no
separate event-shaped plan format). VEVENT is reserved for **reading external,
non-ClearHead-owned calendar data** (a meeting invite, someone else's event) —
context to avoid double-booking, never something we author.

The coupling to VEVENT in the current code is contained to two spots, both
mechanical to swap: `ics.rs::parse_ics_file` (filters `CalendarComponent::Event`)
and `plan.rs::plan_to_event` (builds `Event::new()`). `expand.rs`'s expansion
logic operates on the domain `Plan` struct, not `icalendar::Event` directly, so
it's untouched by the swap. Most of `action_to_vevent`'s field mapping (SUMMARY,
DESCRIPTION, PRIORITY via `map_priority`, CATEGORIES from contexts, COMPLETED
timestamp) carries over close to as-is via the shared `Component` trait.

**State → VTODO STATUS is lossy — by design, not by accident.** iCalendar's
`TodoStatus` only has 4 values (`NeedsAction`/`InProcess`/`Completed`/`Cancelled`);
ClearHead's `ActionState` has 5 (`BlockedOrAwaiting` has no home). Decision:
emit `STATUS:NEEDS-ACTION` plus `X-CLEARHEAD-STATUS:blocked` — generic iCalendar
clients see actionable work, but ClearHead restores the exact state on import.

**Reconcile generalizes, doesn't get replaced.** `reconcile(action, base, ics)
-> Reconcile` (`reconcile.rs`) is a clean pure 3-way diff, just hardcoded to
`Option<DateTime<Local>>`. Genericize to `reconcile<T: PartialEq + Clone>` and
run it once per synced field (state, title, description, due_date), each with
its own merge base. Keeping fields independent means one field's conflict
doesn't block sync of the others (matches decision 31's "respect edits on
either side"). *Where the merge bases live is superseded by the 2026-07-14
notes below — per-field `_sync` columns on `Action`/`ActionMeta` are out.*

**Decided: one `.ics` per action**, same shape as the existing VEVENT mirror
(`action_mirror_path`) — matches the vdir convention of one item per file.

## Recurrence and identity decision (2026-07-17)

**RRULE remains exclusively Plan semantics.** Decision 21 stands: `.actions`
contains executable instances, never recurrence definitions. A VTODO with
RRULE is a Plan master; a VTODO without RRULE is an Action projection. We will
not add temporary RRULE syntax to the DSL, mutate files on read, or maintain
two recurrence authoring models. Convenient recurring capture belongs in
`add plan`/calendar UX, which writes the VTODO+RRULE directly and then invokes
normal expansion into primary and upcoming Action instances.

**Standalone identity is one-to-one and needs no charter-sidecar link.** For
ClearHead-authored resources the canonical shape remains:

```text
Action.id == VTODO UID == vdir filename
```

Calendar clients may legally mint any globally unique text UID, not only a
UUID. Calendar-authored standalone VTODOs therefore retain their original UID
and derive `Action.id` deterministically with UUIDv5. The plans projection
store remembers that UID only so a missing resource can be recreated without
changing interoperable identity. Transport-selected filenames are preserved.
This is projection bookkeeping, not domain or charter-sidecar identity.

Recurring instances are intentionally different: the VTODO+RRULE master has
the Plan identity, while each executable occurrence has its own deterministic
UUIDv5 from the Plan UID and recurrence key. Any retained plan/occurrence
linkage records that real prescriptive relationship; it must not be confused
with identity linkage for standalone Action mirrors.

**Decided: one-time migration command** for plan files currently on disk as
VEVENT+RRULE, converting them to VTODO+RRULE. Normal workspace loading accepts
only VTODO Plan masters; a separately named legacy parser exists solely for
explicit import/migration. This is not a permanent read-both-write-one path.

**Calendar-authored standalone VTODOs create root Actions** in the charter
selected by the containing vdir directory. Resource deletion has no lifecycle
meaning: a missing projection is recreated from the Action. Only VTODO STATUS
changes Action state, including cancellation.

**PRIORITY and CATEGORIES synchronize directly** through their standard RFC
5545 properties. ClearHead priorities now use the same 1–9 range. Contexts map
to category strings; predecessors, sequential behavior, Action hierarchy, and
charter hierarchy remain ClearHead-only because RFC 5545 has no equivalent.

## Design notes (2026-07-17): sync state belongs to the plans vdir projection

The merge base (B) is **the value at the last agreement between the actions
workspace and its configured plans vdir**. The vdir is the abstraction; there
is no remote, account, server, or sync-pair concept in core or the CLI.
CalDAV, when present, is an optional transport outside ClearHead.

**B lives in one machine-local projection store, not the sidecar and not
`Action`.** `.clearhead/sync/plans.json` is a map of
`action-uuid -> { field -> merge-base value }`, owned by the plans-vdir
projection. There is one configured plans path, so there is one store — no
`<pair>` names and no CalDAV-named default.

The store is gitignored because it records local projection history, while
sidecars and actions remain durable workspace data. Changing the configured
plans path means establishing a new first sync, not inventing remote identity
inside ClearHead.

**No legacy compatibility path.** The code does not scan old sidecars, define
legacy metadata structs, or carry migration aliases. A missing store simply
gets first-sync semantics: agreeing action/vdir values converge; differing
values surface as conflicts. Keeping the current code and model clean is more
important than preserving obsolete sync bookkeeping.

**Code shape:**
- `plan_sync` takes an explicit `base_map`, symmetric with the vdir values.
- `scheduled_at_sync`/`due_date_sync` stay off `Action` and `ActionMeta`.
- `apply_sync` atomically stages the one plans sync store with `.actions`
  changes; it has no pair parameter.
- terminology throughout is actions, plans, iCalendar/VTODO, and vdir — never
  a CalDAV server integration.

**Two moves, not one:**
1. Keep the decoupled implementation in `clearhead-core::workspace::calendar`
   while VTODO bidirectional behavior settles.
2. If extraction later pays for itself, lift the vdir projection into a crate
   named for that boundary (not `clearhead-caldav`) while retaining core's
   parsing and `PendingBatch` durability seams.

## Client-surface projection (2026-07-24): occurrences are rendered, not filed

Core sync is settled (above). What is *not* yet built is what happens to the
**clients** once a recurring Plan projects executable occurrences. Decision 21
already says a VTODO+RRULE master is a Plan and each occurrence is an Action
projection with its own UUIDv5 (Plan UID + recurrence key). The consequence
that layer never spelled out: **the action list is now a windowed union of
materialized actions ∪ projected occurrences**, where an occurrence is
`render(master + deviations, window)` — it has no line in any `.actions` file.
The window reuses the existing configurable defaults.

This breaks the founding ergonomic where *the file is both the truth and the
interface*. So we draw one seam and hold it:

**Operations are uniform; text-editing is not.** A materialized action supports
both direct text edits and operations (complete / reschedule / skip). A
projected occurrence supports **only operations** — there is no text to edit;
completing or moving one writes a *deviation* (a `RECURRENCE-ID` override, or
`EXDATE`) into the single Plan resource, never a line. No consumer — query, CLI,
resolver — may branch on "materialized vs projected"; the difference lives
behind the operation, not in front of it.

The client shape follows org-mode's agenda precedent (leverage the pattern,
don't reinvent it): raw-file editing stays exactly as-is for materialized
actions; occurrences are surfaced through the rendered views and acted on via
commands. In nvim specifically, **keep the buffer honest** — occurrences render
as virtual lines / extmarks, never as editable buffer text that would have
nowhere to save back to, and their operations are LSP code-actions.

**Two interop invariants this exposes** (verify against current code — they may
already hold):

- **Canonicalize the recurrence-id before it enters the UUIDv5.** RFC 5545 lets
  peers emit the same slot as UTC, TZID-local, or floating. Same occurrence,
  different bytes → different handle → ghost/duplicate instances. Normalize the
  recurrence key to the master's DTSTART value-type/TZID *before* hashing, so
  two peers derive the identical occurrence UUID. Hash the slot, never the
  occurrence's mutable DUE.
- **Ingest a foreign roll-forward as a completion.** A camp-B client (Apple
  Reminders, etc.) completes a recurring VTODO by *advancing the master* with no
  override. Import must recognize "master DTSTART advanced one period, no new
  override" as completion of the prior occurrence and record that deviation —
  not silently reinterpret it as a reschedule of the series.

  ### thought experiment: datedness
  one other thought that was explored is the concept of having the actions with dates flip to have the ics own our actions file but this was decided against because it would break the flow of the line by having new actions "vanish" from the file to be replaced by a projection.

  dated actions are synced to plans but they are still the primary owner 

  this ensures that wherever possible we are still using the standard methods of file editing and only using projections when necessary such has handling rrule recurrence.

  the main distinction is the rrule role as a generator rather than an individual instance

  in particular, we are working with the issue of lossy conversion and the fact that an action has MORE properties than are supported in the VTODO format

  therefore, we keep the action as the primary unit of abstraction UNLESS it is an RRULE-based plan and this is more of a compromise than a structure

## Design notes (2026-07-24, cont.): occurrences project, they don't expand

Locking the client-surface decisions above into the mechanism they imply. The
section above said occurrences are "rendered, not filed"; this states what that
*demolishes* and what replaces it — it is a replacement of shipped behavior, not
an addition on top of it.

**Retire `expand` materialization.** The currently shipped path —
`expand_plans_into_actions` writing occurrence lines into `<charter>.actions` and
`<charter>.upcoming.actions` with slot accounting (`primary_cap` / `upcoming_cap`
/ completed-vacates-slot) — is removed for recurring plans. A materialized
occurrence line is a *second master* that drifts from its RRULE the instant either
side is edited; the slot accounting only ever existed to police that drift.
Projection dissolves it: one master, occurrences always freshly rendered.

Consequences:
- `<charter>.upcoming.actions` stops existing, and `expansion_primary_instances`
  retires with it.
- The window is a **single per-plan instance count** — `expansion_total_instances`,
  read as "project N occurrences of each plan." Deliberately *not* a time horizon:
  a next-action queue wants the next standup **and** the next annual review, which
  a fixed 14-day window would hide. The count is per-plan, so each plan surfaces
  its own next N regardless of frequency. (Rejected the org-agenda time-window
  framing: that fits a calendar grid, not a queue.)
- No two-tier primary/upcoming render survives — the split only ever chose a file.

**The union has exactly one address.** Projected occurrences enter the Action
stream at the domain-load boundary (`load_domain_model`): load materialized
actions, render plans-in-window, union into one uniform list. Query / CLI / LSP
stay ignorant of materialized-vs-projected. The seam is "the union happens in one
place," not "no code knows."

**Deviations are net-new domain model.** `render(master + deviations, window)`
needs deviations as input, and today `Plan` (`domain/mod.rs`) has none: no EXDATE
set, no RECURRENCE-ID override map, and `expand_occurrences` parses raw
DTSTART+RRULE with nothing subtracted or applied. This is the greenfield core the
whole surface sits on; both `!1` invariants above (canonicalize the recurrence key
before the UUIDv5; ingest a foreign roll-forward as completion) presuppose it —
they are **build** tasks, not verify-only, because there is no deviation storage
for them to hold against yet.

**The sidecar shrinks to workspace provenance.** Removing materialization kills the
two sidecar fields that *only* ever served it: `ActionMeta.external_schedule_id`
(no materialized generated lines remain to re-link — a projected occurrence carries
its plan linkage inherently, in memory) and `PlanMeta.last_expanded` (nothing
expands). What is left — `charter.id`, `charter.created`, `ActionMeta.created` — is
generic provenance orthogonal to calendar sync. Whether *that* residue can also
leave the sidecar (UUIDv7 already embeds `created` for v7 ids; charter frontmatter
already carries identity for non-action-only charters) is a separate
workspace/provenance question, not this charter's to decide. This charter owns
only the removal of the two calendar-serving fields.

## Implementation status (2026-07-25)

Anchoring the design above to what is actually built, so it doesn't read as
purely aspirational:

- **Landed and e2e-proven.** The deviation *read model* (`ICSPlan.exdates` /
  `overrides`, parsed by grouping `RECURRENCE-ID` VTODOs + `EXDATE` onto their
  master), `render_occurrences`, and the `From<Workspace> for DomainModel`
  *union* (materialized ∪ projected, materialized wins by id) all exist and are
  tested. `Workspace` carries a `Projection { now, window }`;
  `load_domain_model_with_projection` is the deterministic entry point. A live
  scratch workspace confirms `clearhead read actions` surfaces a recurring
  plan's windowed occurrences with deterministic UUIDv5 ids.
- **Blocked on the frame fix.** Deviation *matching* does not yet fire:
  `expand_occurrences` collapses DTSTART to Local and re-emits it as a floating
  string, dropping the UTC offset, so occurrence keys and `EXDATE` /
  `RECURRENCE-ID` keys land in different frames (DST-drift confirmed on
  US/Pacific: a Jan `08:00Z` master → July occurrences at `07:00Z`). This is the
  canonicalize-the-recurrence-key invariant, and it is now the critical path —
  `EXDATE` skips and override overlays are written and waiting on it.
- **Known debt.** The union is assembled in two places (the `From<Workspace>`
  lowering and the CLI's `collect_all_actions`), both via the single
  `render_occurrences` primitive; consolidating them is part of the
  occurrence-view "no consumer branches" work.
