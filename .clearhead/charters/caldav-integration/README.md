---
id: 019f5841-1012-7fa2-9d9d-57dec5d906c7
objectives: [calendar-view, data-integration]
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

we will use most of the integration points that already exist like:
- templates
- syncing fields via sidecar

still, we are going to need to go another level of strong to get it all working properly and we are going to want to be doing the most cononacle version of this so that we are able to do this right rather than just this event structure we have

## caldav-compatible

the HOW should come down to integrations with the caldav implementations, and not even that, since we largely conform to the vdir format we should be able to get this all setup by just changing the plan path of our workspace but doing it right will take some thought

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
emit `STATUS:NEEDS-ACTION` plus `X-CLEARHEAD-STATUS:blocked` — generic CalDAV
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

**Decided: one-time migration command** for plan files currently on disk as
VEVENT+RRULE, converting them to VTODO+RRULE once `plan_to_event`/
`parse_ics_file` switch. Not a permanent read-both-write-one dual-format path —
convert once, then the old format is gone.

**Open, not yet decided:** whether `is_sequential`/predecessor edges get any
iCalendar representation at all (no native analog — likely stays
ClearHead-only, unexported).

## Design notes (2026-07-14): sync state decoupled from the domain model

The merge base (B) is **"the value as of the last sync between *this
workspace* and *this remote*"** — a property of the sync *pair*, not of the
action. That identity drives the decisions below, superseding the earlier
per-field `_sync` column plan.

**B lives in a sync-owned store, not the sidecar and not `Action`.**
`.clearhead/sync/<pair>.json` (e.g. `caldav.json`): a map of
`action-uuid -> { field -> merge-base value }`, owned and versioned by the
sync layer alone. Rationale beyond keeping the domain model clean:

- **Per-remote.** A `scheduled_at_sync` column on the action bakes in "exactly
  one remote forever." A store keyed by pair name supports syncing to two
  calendars. Same design as vdirsyncer's per-pair status files.
- **Per-machine.** Sidecars travel with git; sync state must not. Two machines
  syncing against the same Radicale server at different times would ship each
  other stale merge-base stamps describing syncs the receiving machine never
  performed — manufactured "merge base drift." The sync store is gitignored.

**Code changes** (small — `reconcile(a, b, c)` is already pure and doesn't
care where B comes from):
- `plan_sync` takes a `base_map: &HashMap<Uuid, Time>` parameter, symmetric
  with the `ics_dates` map it already takes, instead of reading
  `action.scheduled_at_sync` off the hydrated model.
- `scheduled_at_sync`/`due_date_sync` come **off** `Action` and `ActionMeta`;
  sidecar `merge_action`/`hydrate_actions_map` shrink accordingly.
- `apply_sync` stamps B into the sync store instead of staging sidecar writes.
- One-time seed migration: read existing sidecar `_sync` values into the new
  store so existing workspaces aren't forced through spurious conflicts.

**Accepted trade:** sync state is unrecoverable from the repo alone. A fresh
clone has an empty sync store and gets first-sync semantics — which is
*correct* (a fresh clone genuinely hasn't synced): agreeing sides converge,
disagreeing sides surface as conflicts for a human.

**Two moves, not one:**
1. **Now:** the decoupling refactor inside clearhead-core (`workspace/calendar`
   keeps the code; `domain` gets cleansed; new sync-store module). Lands
   *before* the action-mirror VTODO swap so the swap's `apply_sync` changes
   stamp B in the right place from the start.
2. **Later, once VTODO bidirectional settles:** lift `workspace/calendar` +
   the sync store into a separate crate (e.g. `clearhead-caldav`) depending on
   clearhead-core as a library. Depending on core is not a violation — the
   *contract* is the workspace format; the library is shared plumbing
   (parsing, formatting, `PendingBatch` durability) not worth reimplementing.
   A fully separate tool driving writes through the CLI was considered and
   rejected: `TakeCalendar` needs atomic batched writes across `.actions`
   files, and subprocess calls would lose or reinvent the durability layer.
