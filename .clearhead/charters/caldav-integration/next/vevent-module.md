---
id: 01a036e3-3e1d-72a0-bc05-d060ac8f73b6
alias: vevent-module
parent: caldav-integration
state: Active
---
# Configurable Plan calendar codecs

ClearHead currently uses VTODO for both recurring Plan masters and standalone Action mirrors. Although technically successful, this makes the calendar boundary carry two concepts and steers users toward unevenly supported TODO-client workflows.

A calendar resource should instead represent a **Plan**: the scheduling relationship attached to an Action. The configured Plan codec may be VEVENT or VTODO, with VEVENT as the default because it is the broadly interoperable calendar representation. The component choice changes the wire representation, not the domain behavior.

## Ownership contract

- `.actions` owns executable work, lifecycle state, hierarchy, dependencies, and other ClearHead workflow semantics.
- The configured calendar component owns scheduling: DTSTART, duration/end, recurrence, exclusions, and occurrence rescheduling.
- An Action without a scheduled date has no Plan resource; it is intentionally unplanned.
- Adding a schedule to an Action creates a one-off Plan. Removing the schedule removes that Plan without deleting or cancelling the Action.
- Calendar-created Plan resources create scheduled, not-started Actions in their owning charter.
- Calendar-side rescheduling updates the corresponding Action instance. Action-side rescheduling updates the Plan master or occurrence override.
- Recurring instances are addressed by Plan UID plus canonical recurrence key; one-off Plans realize exactly one Action.
- The Action sidecar carries the durable Plan link (`plan_uid` plus an optional recurrence key). ClearHead-authored one-off Plans still use the Action UUID as component UID and filename; calendar-authored Plans retain their foreign UID while the Action receives an independent native UUID.
- Action state remains authoritative in `.actions` even when VTODO is selected and could carry STATUS.

## Codec contract

VEVENT and VTODO are alternative encodings of the same Plan semantics. RRULE determines whether a Plan is recurring; it does not determine whether a calendar component is a Plan or an Action. Readers should support a deliberate compatibility/migration path, while new resources use the configured codec.

The vdir remains the complete integration boundary. CalDAV, vdirsyncer, filesystem synchronization, or no transport may sit behind it.

## Integration choice

The formats are not required to expose identical client behavior. VEVENT delegates scheduling to ordinary calendar clients while Actions retain state in the filesystem. VTODO remains available for users who prefer a task-oriented mobile integration. The choice is which external integration surface manages the Plan, not whether ClearHead gives up its native Action model.

## Implementation direction

Preserve the existing Plan domain model, recurrence engine, deterministic occurrence identity, charter collection ownership, projection store, locking, and atomic cross-mount writes. Refactor the calendar layer around a Plan-component codec, then reshape synchronization so dated Actions and Plan resources form the bidirectional scheduling relationship while unscheduled Actions remain local-only.
