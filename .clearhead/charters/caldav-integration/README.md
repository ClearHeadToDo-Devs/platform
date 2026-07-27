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
- **Frame fix landed (2026-07-25).** Deviation *matching* now fires.
  `expand_occurrences` anchors expansion in UTC (formats DTSTART as
  `…%SZ`) instead of re-emitting a zoneless Local wall-clock string, so
  occurrence keys and `EXDATE` / `RECURRENCE-ID` keys share one absolute-instant
  frame and agree. Regression-locked by
  `expand::tests::exdate_across_dst_boundary_skips_the_occurrence` (a winter
  `08:00Z` master with a post-DST-boundary EXDATE — proven to fail on the old
  code and pass now under `TZ=America/Los_Angeles`). This is Option A of the
  frame decision: fully lossless for every DTSTART form ClearHead authors
  (always UTC) and for UTC/floating foreign masters. **Deferred:** a foreign
  *TZID-anchored* series across a DST boundary is the one shape UTC expansion
  does not preserve — it needs the original frame carried on `Plan`
  (value-type/TZID), logged as the next interop rung, not this fix.
- **Deviation write model landed (2026-07-25).** The occurrence handle
  (`plan_id` + `external_occurrence_key`) is now stamped on every rendered
  occurrence. `write_occurrence_deviation` (`ics.rs`) writes the deviation into
  the master — `Skip`→dedup `EXDATE`, `Complete`→completed `RECURRENCE-ID`
  override, `Reschedule`→override with new times — preserving all other
  components/properties, atomically; `apply_occurrence_op` (`plans.rs`) resolves
  `plan_id`→master file. The CLI routes `complete`/`cancel` to this write path
  when the query isn't a materialized line (materialized always wins);
  `cancel`→`Skip`, `complete`→`Complete`, no new verb surface. Proven end to end
  through the real binary (complete → `RECURRENCE-ID` override → re-render `[x]`;
  cancel → `EXDATE` → slot drops, window pulls the next). **Remaining:**
  `reschedule` (needs datetime args).
- **Sync-leak sealed (2026-07-25).** `sync_calendar` now loads a window-0
  (`Projection::without_occurrences`) model, so projected occurrences are
  structurally absent from `plan_sync` — they reconcile via deviations on the
  master, not the standalone-VTODO channel. Occurrences aren't excluded by a
  fragile per-action flag; the loader boundary is exact. Regression-locked in
  `workspace_store.rs`.
- **Occurrence-ops complete (2026-07-25).** `reschedule` now joins `complete`/`skip`:
  `update <occurrence> --scheduled-at` on a projected occurrence writes a
  `RECURRENCE-ID` override with the new time (hash the immutable slot, move the
  value) via `apply_occurrence_op`. Per the seam, a projected occurrence supports
  *only* operations — any other field edit on one is rejected with a pointer to
  edit the plan or a materialized action instead.
- **Calendar-only sidecar fields stripped (2026-07-25).** With materialization
  retired, the two fields that only ever served it are gone: `ActionMeta.external_
  schedule_id` (a projected occurrence carries plan linkage inherently in memory
  via `plan_id` + `external_occurrence_key`) and `PlanMeta.last_expanded` (nothing
  expands — `PlanMeta` and the sidecar `plans` map removed entirely). The now-dead
  `plan_sync` skip-guard and the doctor `dangling-plan-link` check went with them.
  Retained: `charter.id/created`, `ActionMeta.created` — generic provenance, not
  calendar sync. Snapshots/fixtures regenerated (only the removed-field lines).
- **Foreign roll-forward ingest landed (2026-07-25).** A camp-B client (Apple
  Reminders, etc.) completes a recurring occurrence by *advancing the master
  `DTSTART`* with no override. `sync_master_rollforwards` (`reconcile.rs`) detects
  this — the new `DTSTART` lands on a later point of the recurrence grid anchored
  at the origin we hold in `PlansSyncStore` under `MASTER_DTSTART_FIELD` — and
  translates it to canonical form via `write_master_rollforward` (`ics.rs`): reset
  the anchor to the origin and record each passed slot as a completed
  `RECURRENCE-ID` override. **Spec-first, per the decision:** overrides only bind
  on the recurrence grid, so the anchor is held fixed at the origin forever;
  completion history lives in slot-keyed **idempotent** overrides, so a client
  that ignores overrides and re-advances churns only the anchor *value*, never the
  history (the acknowledged, benign ping-pong residual). Handles N-period advances
  across a sync gap (records every passed occurrence, not just the last) and
  distinguishes an off-grid `DTSTART` as a genuine reschedule (accept, don't
  record). Wired into `sync calendar`. **Bug fixed en route:** `parse_vtodo_actions`
  now skips `RECURRENCE-ID` components, which were being misread as spurious new
  standalone actions by the standalone sync.
- **Expand materialization retired (2026-07-25).** The demolition the projection
  model implied. Deleted: the `clearhead expand` verb + `expand_actions` (and its
  template-instantiation glue), `expand_plans_into_actions` + `ExpandResult` +
  `ExpansionConfig` + slot accounting, `upcoming_actions_path` and the whole
  `.upcoming.actions` concept (archival + docs), `expansion_primary_instances`
  config, `Plan.primary_instances`, and the `upcoming:` DESCRIPTION directive.
  `expansion_total_instances` survives as the projection *window*; the shared
  `templates` module survives (used by `charter`/`template`/`plan`). `discover_
  action_files` now also skips `.upcoming.actions` so any lingering legacy file
  can't shadow projections. Occurrences are projected on read, never filed —
  `read` needs no prior `expand`. Snapshot regenerated (one field removed).
- **Union consolidated (2026-07-25).** The materialized ∪ projected rule now
  lives in exactly one function, `extend_with_projected_occurrences` (`expand.rs`),
  called by the `From<Workspace>` lowering *and* both CLI read collectors. This
  closed a real bug: `collect_workspace_actions` (multi-workspace listings) never
  rendered occurrences at all, so they silently vanished there; it now unions via
  the shared rule like every other path. Unit-locked (`extend_unions_occurrences_
  and_materialized_wins`) and e2e-confirmed that the TTY tree and non-TTY flat
  paths agree.

## Design notes (2026-07-26): templated recurrence is cron, not calendar

Resolves the last open client-surface question — what a *multi-step* recurring
plan (the weekly review: regular **and** stateful) does — and reverses a
near-decision to delete templated recurrence outright. It survives, but on a
different mechanism than atomic recurrence.

**The complexity was the straddle.** Every hard question — when to spawn, how to
dedup, drift, "what does the agenda point at," reconcile-a-subtree-into-a-
deviation — came from making one occurrence *both* a projection (rendered on the
fly, stateless) and materialized (a real subtree with per-instance state).
Nothing about recurrence forces that straddle; removing it dissolves the
complexity.

**Two disjoint lanes, selected by whether an occurrence accumulates state.**
- **Stateless occurrence → project.** A bare recurring plan (no template) is
  fully described by `master + slot`; its only state is done/skip/move. It
  renders on the fly, deviation-backed. Unchanged from the atomic model above.
- **Stateful occurrence → stamp.** A templated recurring plan (`template:`
  directive) spawns a checklist you *work over its life*. That per-instance
  state has no home in a projection, so the occurrence is made real from birth
  and never projected.

The `template:` directive is the one-bit switch. A plan is in exactly one lane;
it never straddles.

**Stamping is cron, not calendar.** A calendar *projects* future occurrences as
live, reconcilable objects — that is the expensive part. Cron fires, produces an
artifact, records "last run," and forgets. A templated plan is a cron job for
actions: on its schedule it instantiates the template into `.actions` as a real
subtree, **dead on arrival** — it tracks nothing thereafter. No window to
maintain, no cap, no vacate-on-complete, no reconcile. (That live-window
maintenance is exactly what made the retired `expand` complex; stamping has none
of it.)

**The template replaces the occurrence wholesale.** A template is a *proper
action file*, and action-file hierarchy has no parentless children — children
require a root. So stamping does **not** synthesize a parent from the VTODO
`SUMMARY` and graft template children beneath it. The occurrence slot is
*replaced by* the instantiated template tree, whose own root carries the
deterministic occurrence UUIDv5 (`hash(plan UID, slot)`); descendants remap to
fresh ids under it. Consequently a templated master's `SUMMARY` is only the
**generator's** label (what a calendar client shows for the schedule); the
stamped instance's title, structure, and identity all come from the template.

**Reuses existing machinery; adds one bounded function.**
- Stamp = `instantiate_template` (already remaps ids, preserves hierarchy),
  passed the occurrence UUIDv5 as the *root* id instead of a random `now_v7`,
  with no parent override (it is a root).
- Idempotency = the deterministic root id + the existing "materialized wins by
  id" union: re-stamping a slot whose action already exists is a no-op. The
  workspace *is* the watermark — no stored slot-accounting resurrected.
- Skip = `EXDATE` on the master (shared with atomic recurrence); the stamp loop
  skips EXDATE'd slots.
- Freeze-on-edit (editing the template never mutates an in-progress instance),
  per-instance child state, and ics flattening are all free — a stamped instance
  is just an ordinary action.

The only net-new code is an idempotent generator: *for each templated plan, for
each due, non-EXDATE'd slot with no existing action, stamp the template.*

**Stamping is a write, so it lives on the write path** (`sync calendar` / a
`tick` verb), never on the pure `From<Workspace>` load/projection. Reads stay
pure and see whatever has been stamped — the same read/write discipline sync
already holds.

**Worked example — the weekly review.** Plan: `VTODO + RRULE(WEEKLY;BYDAY=SU) +
template: weekly-review`. Sunday: the generator finds the due slot has no action
with `id = hash(uid, slot)` → stamps the template subtree, root id = that
occurrence UUID. All week it is an ordinary materialized subtree — tick children
as text. Complete it → normal `[x]`, archives normally. Next Sunday is a new slot
id → a fresh empty checklist stamps; last week's completed one rests in the
archive. Vacation week → `EXDATE` that slot. No window, no reconcile, no straddle
at any point.

**Deferred policy edges** (knobs, not architecture): a catch-up run after a long
gap sees several due slots — cap how many it will stamp so it can't flood. Slot
computation uses the UTC anchor established by the 2026-07-25 frame fix.

## Design notes (2026-07-26, cont.): plans are facts; completions round-trip; deletion is allowed

A design conversation over the templated lane surfaced the ontology underneath all
of this and settled what the "cron, not calendar" note above left open or drew too
starkly.

**The ontology: continuant vs. occurrent.** Actions and charters are *continuants* —
stateful entities that persist by *changing* (NotStarted→…→Completed→archived/
deleted); their truth is their current state. Occurrences and their completions are
*occurrents* — temporal facts: they happened, and the record is fixed once made.
Deleting a completed occurrence deletes *meaning*; the history of completions is a
core interface, not scrapbooking. Exact boundary: the plan **master/rule** (the
RRULE) is itself a mutable continuant — you retire it, change its cadence — while the
layer below it (the occurrences and completions it throws off) is factual. The
deviation grid is an **append-only event log hanging off a mutable rule.**

**Templated completion is calendar-*managed*, and round-trips (amends the note
above).** The prior section's "dead on arrival — complete it → normal `[x]`, nothing
goes back" is too dead. Full interior fidelity genuinely can't round-trip — a
five-child checklist is not one VTODO `STATUS` — but the *rollup bit* can and should.
The stamped root's id already *is* the occurrence key (`hash(plan UID, slot)`), so
completing the root writes a completed `RECURRENCE-ID` override on the master through
the same `write_occurrence_deviation` path the atomic lane uses. The rich interior
stays local in `.actions`; "this slot is done" reaches the calendar. Stamped
instances do **not** also flatten to standalone VTODOs — that would hand a foreign
client the master's RRULE occurrence *and* the stamped todos on one slot (double
vision). The vdir stays one master + its overrides, exactly like the atomic lane.

**Graft, not wholesale replace.** The occurrence root is synthesized from the master
VTODO the same way an atomic occurrence's action is — `SUMMARY`→title,
`CATEGORIES`→contexts, `PRIORITY`→priority, id = occurrence UUIDv5 — and the template
supplies only the *step forest*, grafted beneath it via the (dead-since-`expand`)
`parent_override` in `instantiate_template`. So `SUMMARY` means one thing across both
lanes (an earlier draft made it a "generator label" for templated plans only — a
wart), and there is **no parentless-children invariant to relax**: a step-only
template is already a legal forest of roots, not rootless children. Atomic occurrence
= synthesized root, no template; templated occurrence = the same root + grafted
steps. `template:` is the one-bit switch.

**The occurrence→plan linkage is sync machinery → the sync store.** Writing the
completion deviation needs the immutable slot key, unrecoverable from the hash id
(non-invertible) or from `scheduled_at` (mutable once rescheduled). So it is stamped
explicitly — `(plan_id, slot)` into `PlansSyncStore` at stamp time, alongside
`MASTER_DTSTART_FIELD`/`UID_FIELD` (the store already holds non-merge-base sync
machinery) — and consumed/cleared when the deviation lands. **Not** a DESCRIPTION
directive (`description` is a bidirectionally-synced field, and the directive would
persist permanently into the archive) and **not** new `.actions` DSL. It is an
ephemeral live-path *cache*, reconstructible, so gitignoring it loses nothing
durable. The occurrence-id hash stays a *join key*, never a node in the ontology.

**Snapshot archived lineage; don't re-derive it.** A completion is an immutable fact
and must be self-contained. So the semantic edge — *this instance realizes plan-M at
temporal position T*, plus a human label — is **snapshotted onto the archived
instance at crystallization** (completion/archival), never reverse-derived from the
current RRULE, which may since have been edited or deleted (the invoice-snapshots-
price-at-sale principle). Layer-sensitive: while an occurrence is *live* its lineage
is derived from the current rule (the sync-store cache stands); the snapshot happens
only at the phase transition. Archival = crystallization of a stateful entity into a
durable fact; `archive/` is the fact-store; graphd projects the coherent history over
both live entities and archived facts.

**Deletion is allowed — there is no immutability invariant.** Three distinct verbs:
`close`/`cancel` are *state transitions* (the fact persists, its status changes);
`delete` is *retraction from history* (erase the thing). The user declares intent via
the verb; the system does not infer human-vs-machine provenance. "Facts are
immutable" is unenforceable across hand-editable plaintext + foreign CalDAV clients
(which roll forward and delete at will) + eventually-consistent sync — declaring it
would be a lie the code leans on. It is safe to allow because graphd degrades
gracefully over a tolerant world (dangling refs, missing nodes, partial reads): a
deleted fact is a hole a projection absorbs, not a corruption. History-preserving
stays the **default by convention** (`close`/`cancel` are the everyday path);
`delete` is the deliberate exception.

## Design notes (2026-07-26, cont. 2): materialize the present, project the future — the file is the live view

The templated lane forced a generator that *stamps a real subtree on the write
path*. That reopened the question the whole client-surface arc had answered the
other way: if we stamp templated occurrences to disk, why *project* atomic ones?
The answer **reverses** the 2026-07-24 decision ("occurrences are rendered, not
filed") and **collapses the two lanes** of the note above into one. The on-disk
`.actions` file being both the truth and the interface is a core feature, not an
ergonomic to trade away; projection-in-the-load-path quietly traded it away.

**Tense is ontological status.** The continuant/occurrent split maps onto time,
and that mapping decides where each occurrence lives:
- **Present** — the current due occurrence is the only *actionable, stateful*
  instance (a live continuant). It **materializes**: a real action on disk,
  identical to a dated action. One per plan, because only one instance is "now."
- **Past** — completed occurrences are *facts*. They crystallize into `archive/`
  on completion (the durable history of the facts note above). Surfaced as
  **analytics**.
- **Future** — not yet a fact, not yet actionable (you cannot do next week's
  standup today). It is *potential*, which is exactly a **projection** over the
  RRULE. It lives in a **calendar view** / the graph, for planning — never as a
  materialized action.

So "why not stamp normal VTODOs too" resolves to: you do — you stamp *the
present*. And "why keep projection" resolves to: for *the future*, where it was
always the right tool. The 2026-07-24 mistake was projecting into the *present*
(the load-time action-list union); that is what broke the founding ergonomic.
Move projection to the tense it belongs to and the seam dissolves.

**The guardrail that makes it safe is retained: never materialize the future.**
That was `expand`'s sin — a window of future file-lines drifting from the RRULE,
policed by slot accounting. We materialize only the present due occurrence (one
per plan) and generate the next *on completion*, reading the RRULE fresh at that
moment. No stale future exists to drift, so none of the retired slot-accounting
returns.

**One lane, not two.** The 2026-07-26 "two disjoint lanes (project atomic / stamp
templated)" collapses: both **stamp the present**. Atomic = a synthesized
childless root; templated = the same root + the grafted template step-forest.
`template:` is the only difference, and it only *adds children*. Projection could
never host the stateful lane (per-instance child state has no home in
`render(master, window)`); materialization hosts both. So the unifiable mechanism
is materialization, and projection is demoted from a core data-model piece to a
query concern.

**Projection is re-homed, and constrained by one hard rule.** It survives for the
future (calendar) and the past (analytics), query-only. The rule: **projection
must never feed an index-shape query** — one whose results resolve to
`file:line:col` to jump to and edit. A projected occurrence has no line; if it
leaks into such a query the qflist fills with entries that can't be navigated to
or saved back — precisely what forced the virtual-line gymnastics. Because the
`.actions` file stays all-materialized, every actionable entry is a real,
jumpable, editable line and the **qflist stays a first-class editing surface.**
Projection is fine behind analytic/planning queries; it is banned from the ones
the editor treats as an index.

**The retained cost: the tick.** The present occurrence exists on disk only after
the write-path generator runs — honest cron semantics; a cold `read` will not
conjure it. This is the exact machinery the stamping lane already needs, so it is
built **once** and both former lanes share it. Pure-over-disk reads return (no
projection at load); "is the present occurrence stamped yet" rides
`sync calendar` / a `tick` verb, as the atomic write path already does.

**Code consequence — a surgical unwind, not a rewrite.**
`extend_with_projected_occurrences` leaves the load path;
`load_domain_model_with_projection` stops unioning occurrences into the action
list; query / CLI / LSP see only materialized actions (the seam disappears with
the thing that needed it). The recurrence engine — `expand_occurrences`, the
deviation read/write model, the frame fix — **survives**; its output now feeds
(a) the write-path stamper and (b) the future calendar projection, instead of a
load-time union. The nvim virtual-line/extmark surfacing is obviated for the
present (occurrences are real lines); any future-occurrence rendering is a
read-only calendar concern, not buffer text.

**Advancement is a single token, completion-driven — the RRULE is a cadence, not
a hard schedule.** A recurring plan has at most **one** active occurrence. It
never advances by the clock: an overdue active occurrence just stays overdue (no
stacking of missed cycles). It advances only when *resolved* — completed or
skipped — and eagerly: resolving the active occurrence immediately stamps the next
slot = the first RRULE slot both *after the resolved one* **and** *>= now*. That
last clause is **jump-forward**: complete a long-overdue occurrence and you land
on the next *upcoming* slot, not the next historical one; the intervening missed
slots are *never-weres*, not recorded skips. This is deliberate product values — a
personal tool for choosing what to do next without guilt, not an audit trail that
punishes a skipped week by making you clear a backlog. History stays honest: an
occurrence that was stamped and then skipped leaves an `EXDATE` fact; a period the
token never reached simply never existed as an occurrence. Expect, don't fix, one
consequence: the materialized file (the one active token, possibly overdue) and
the projected calendar (the RRULE's true future dates) diverge — they answer "what
do I do now" vs "when does this fire."

## Implementation status (2026-07-26): the single-token materialization lane

Building the shift the notes above decided. Landed and **e2e-proven via the real
binary** (`sync calendar` stamps a token; `complete action` writes the deviation
to the master and advances). Still additive — the load-time projection union
remains until the unwind, so a read currently shows the token *and* the projected
window (the transitional double-vision the unwind removes).

- **Slot engine (`expand.rs`).** `next_active_slot(plan, floor, now)` computes the
  single token's slot: `floor = None` → first occurrence `>= now` (initial /
  upcoming); `floor = Some(resolved)` → first `> resolved` **and** `>= now`
  (jump-forward, so an on-time or late resolve advances instead of replaying missed
  slots). `render_occurrence` was extracted as the one occurrence field-mapping, so
  the projection and the stamper agree.
- **Store linkage (`sync_store.rs`).** `OCCURRENCE_PLAN_FIELD` /
  `OCCURRENCE_SLOT_FIELD` keyed by the occurrence id, with `stamp_occurrence_link`
  / `occurrence_link` / `occurrence_links` / `clear_occurrence_link`. This is the
  durable tie a materialized line keeps to its master — confirmed that
  `plan_id`/`external_occurrence_key` survive *neither* the DSL nor the sidecar, so
  the link must live here.
- **Ensure-active stamper (`reconcile.rs`, inside `apply_sync`).**
  `ensure_active_occurrences` stamps one live token per recurring plan via the
  shared `stage_plan_token`, riding `apply_sync`'s lock + `PendingBatch`.
  Idempotent while a token is live; self-heals a token resolved outside the hook by
  re-stamping on the next sync.
- **Completion hook (`reconcile.rs` + CLI `commands/action.rs`).**
  `resolve_materialized_occurrence` is the calendar round-trip: writes the completed
  `RECURRENCE-ID` (or `EXDATE` for skip) deviation to the master via
  `apply_occurrence_op`, clears the link, and jump-forward-stamps the next token,
  atomic with the store. The CLI's `complete`/`cancel` call it *after* the ordinary
  close, so an occurrence line's completion becomes **close + deviation + advance**
  — the Finding-1 inversion, realized. `commit_actions_and_store` was extracted as
  the shared `.actions`-plus-store atomic tail (used by both `apply_sync` and the
  hook).

**Remaining:** graft the template step-forest for *templated* plans (only atomic
childless-root stamping landed); snapshot plan-lineage onto the archived instance at
completion; and **the unwind** — remove `extend_with_projected_occurrences` from the
load path (ends the double-vision) and re-home projection to future/past query
views. Uncommitted across `clearhead-core` and `clearhead-cli` at session end.
