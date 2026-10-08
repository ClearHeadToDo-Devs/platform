---
type: Runbook
title: VEVENT-only calendar sync — implementation analysis
description: What Decision 55 costs to implement, in what order, and what the code showed about recurring occurrences along the way. Prepared 2026-10-07, before any code changes.
status: draft
generated: { by: agent/claude, at: 2026-10-07T00:00:00Z }
sources:
  - id: decisions
    resource: ../DECISIONS.md
    title: Decision 55 (the why), Decisions 51 and 54
  - id: actions
    resource: ../../.clearhead/charters/next.actions
    title: commit-d55, x-prop-survival, template-binding-home
  - id: spec
    resource: ../../specifications/ics_schedule_spec.md
    title: Plan codecs, field authority, reconciliation
---

# VEVENT-only calendar sync

The *why* is [Decision 55](../DECISIONS.md). This is the *how much* and *in what order*, measured against clearhead-core at 81d6620.

## The payoff is smaller than the session claimed

In the session I estimated VEVENT-only would remove "a third to a half" of the calendar complexity. The code says otherwise:

| Measure | Value |
| --- | --- |
| Calendar layer, non-test code (`ics.rs`, `reconcile.rs`, CLI `filesystem/calendar.rs`) | ~4,800 lines |
| Clearly VTODO-only functions (`patch_todo`, `apply_state_outcome`, `upsert_todo_override`, `override_from_todo`, `vtodo_state*`, `set_todo_end`, `parse_categories`, `plan_to_vtodo`, `event_as_todo`, `action_state_to_todo_status`) | ~240 lines |
| Plus VTODO branches in shared code and the state/priority/contexts merge plumbing | roughly another 200–350 |
| **Likely net removal** | **~10% of the code** |

The real gain is in *dimensions*, not lines: the profile axis goes from two to one, and synchronized fields go from 7 to 4 (start, end, name, description). Keeping name and description two-way (the experiment) is what holds it at 4 rather than 2. Worth knowing when the experiment is judged: dropping it later removes two more merged fields.

## Migration is nearly free here

This machine's workspaces hold **3 VEVENT, 0 VTODO** Plans and **one** `template:` directive (`~/.local/share/clearhead/plans/`). No workspace config sets `plan_component`. The NUC's collections are unknown until `resume-calendar-sync`; check them before deciding the one-release conversion is worth building at all. If they hold no VTODOs either, the conversion can be a `doctor` finding and nothing more.

## The test suite mostly tests the profile being removed

This is the main risk. `sync_calendar()`, the convenience entry point, hard-codes `PlanComponentKind::VTodo` (`filesystem/calendar.rs:152`), although the product default is VEVENT. As a result:

- of the sync call sites in `filesystem/calendar.rs`'s tests, 23 run under VTODO (12 through `sync_calendar`, 11 explicitly) and 12 under VEVENT, besides a few parameterized over both;
- all three recurrence-close integration tests (`tests/fs_recurrence_close.rs`) run under VTODO.

So the live-token close path, the heart of recurrence, has no VEVENT integration test today. Deleting VTODO first would delete that coverage.

## Order

Decision 54 fixes the outer order (specification release, then Core). Inside Core:

1. **Convert tests before deleting anything.** Point `sync_calendar()` at VEVENT (or remove it and pass the component), port the three recurrence-close tests and the VTODO sync tests that cover shared behavior. Gate green under VEVENT alone. This is the bulk of the work, and it is safe to do now.
2. **Delete the profile.** The VTODO-only functions above, the `component_kind == VTodo` branches, `PlanComponentKind::VTodo`, the state/priority/contexts arms of `SyncEntry`. Keep `action_to_vtodo` and `actions_to_icalendar` for `clearhead export plans`.
3. **Retire `plan_component`.** Warn when it is set; conversion or a `doctor` finding, depending on what the NUC holds.
4. **Then the name/description experiment.** `patch_event` writes only the block today; it would also write `SUMMARY`/`DESCRIPTION`, and `stage_prepared_plan_token` would stamp title and description bases for every Plan, not only VTODO ones.

Step 4 should wait for `template-binding-home`. If the binding moves to `X-CLEARHEAD-TEMPLATE`, `DESCRIPTION` carries no directives and Decision 55's directive guard never has to be built. Building the guard first means building it to delete it.

Specification files to change in that release: `ics_schedule_spec.md` (codec table, VTODO profile, field-authority table, the VTODO half of the end-time rule), `process.md` (lines 193–235, 289), `configuration.md` (`plan_component`), `workspace.md` (137, 199, 297), `ontology.md:314`, `README.md:122` (the spec index still calls it the "VTODO Projection Specification"), and `examples/README.md` (export section; stays accurate if export keeps VTODO).

## What the code showed about recurrence

These came up while reading, and none of them are Decision 55's business. They are the open questions from the session, now with evidence.

- **Template edits apply from the next occurrence.** `stage_prepared_plan_token` instantiates the template when it stamps, so an occurrence is a snapshot. This matches what you described.
- **Missed occurrences vanish without a trace.** One live token per Plan; while it is open nothing new is stamped, and when it resolves the next slot is the first one `>= now` (`next_active_slot`, `expand.rs:152`). Three missed weekly reviews leave no record that they were missed. The old observability spec had an `instance_skipped` event; nothing emits it now. For a system that values transparency, this is the gap I would raise first.
- **Open steps when an occurrence closes: not verified.** I found no handling of an occurrence's unfinished children in `prepare_materialized_occurrence_resolution`, and no test for it. Either it is handled elsewhere or open steps are orphaned under a closed root. Worth one test before relying on templated plans.
- **Stale docs.** `observability.md` still describes `.recurring.actions` files and template/instance events from before Decision 21; `argparser.rs:62` says the template binds "through recurring VTODO DESCRIPTION".
