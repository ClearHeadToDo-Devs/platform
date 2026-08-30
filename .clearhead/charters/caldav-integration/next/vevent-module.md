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

- `.actions` is the durable local record for executable work, hierarchy, dependencies, and ClearHead-only workflow semantics.
- Every configured calendar component owns scheduling: DTSTART, duration/end or due, recurrence, exclusions, and occurrence rescheduling.
- An Action without a scheduled date has no Plan resource; it is intentionally unplanned.
- Adding a schedule to an Action creates a one-off Plan. Removing the schedule removes that Plan without deleting or cancelling the Action.
- Calendar-created Plan resources create scheduled Actions in their owning charter. VEVENT adoption seeds a not-started Action; VTODO adoption also imports the interoperable task fields described below.
- Calendar-side rescheduling updates the corresponding Action instance. Action-side rescheduling updates the Plan master or occurrence override.
- Recurring instances are addressed by Plan UID plus canonical recurrence key; one-off Plans realize exactly one Action.
- The Action sidecar carries the durable Plan link (`plan_uid` plus an optional recurrence key). ClearHead-authored one-off Plans still use the Action UUID as component UID and filename; calendar-authored Plans retain their foreign UID while the Action receives an independent native UUID.
- A VTODO resource is an editable synchronization peer, not merely a schedule-shaped copy. Shared fields reconcile bidirectionally through independent three-way merge bases; conflicts are surfaced rather than resolved by an implicit global authority winner.
- ClearHead-only fields remain local unless a deliberate standards-backed or `X-CLEARHEAD-*` mapping exists.

## Integration profiles

The configured component selects an integration profile, not merely a wire encoding:

- **VEVENT — calendar scheduling profile (default).** Ordinary calendar clients manage start, end/duration, recurrence, exclusions, and occurrence moves. SUMMARY and DESCRIPTION remain useful display projections, but VEVENT does not acquire Action lifecycle semantics.
- **VTODO — full task-client profile.** Preserve all existing bidirectional integration points: DTSTART/scheduled time, DUE, STATUS and COMPLETED, SUMMARY/title, DESCRIPTION, PRIORITY, CATEGORIES/contexts, and supported standards-backed relationships. Preserve alarms, unknown properties, and vendor extensions. `Blocked` continues to degrade through standard `STATUS:NEEDS-ACTION` plus `X-CLEARHEAD-STATUS:blocked` so generic clients and ClearHead both retain useful meaning.

RRULE determines whether either profile's Plan is recurring; it does not determine whether the component is a Plan or an Action. The profiles share Plan identity, scheduling, recurrence, sidecar linkage, and migration machinery, but intentionally expose different client capabilities. Readers must support a deliberate compatibility/migration path, while new resources use the configured profile.

The vdir remains the complete integration boundary. CalDAV, vdirsyncer, filesystem synchronization, or no transport may sit behind it.

## Integration choice

The profiles are not required to expose identical client behavior. VEVENT delegates scheduling to ordinary calendar clients. VTODO retains the richer mobile/task workflow already proven through the existing integration, including changing Action fields from the task client and projecting ClearHead edits back to it. If VTODO were reduced to schedule-only behavior, it would be a worse calendar event and should be removed rather than retained as a nominal codec.

The choice is therefore explicit: ordinary calendar scheduling or full task synchronization. Neither choice gives up `.actions` as ClearHead's durable native work interface.

## Implementation direction

Preserve the existing Plan domain model, recurrence engine, deterministic occurrence identity, charter collection ownership, projection store, locking, atomic cross-mount writes, and the VTODO field-reconciliation behavior. Refactor both profiles around durable Action–Plan links so arbitrary calendar UIDs never become Action identity. Reshape synchronization so dated Actions and Plan resources form the bidirectional scheduling relationship while unscheduled Actions remain local-only; branch field reconciliation by the selected/observed profile rather than deleting VTODO's richer integration.
