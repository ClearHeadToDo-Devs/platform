---
alias: caldav-integration
state: Active
description: Two applications (ClearHead and a CalDAV server) sharing one plan directory and syncing through the files themselves — no integration layer, coordination through data
---

# CalDAV Integration

Implements [decision 31](../../../DECISIONS.md). Builds on [[write-durability]],
which gives us the atomic single-file write and the staged A+B commit seam this
charter relies on.

## The shape

A new config key, `plan_path`, names one directory where all plans (`.ics`
files) live. A CalDAV server — radicale, in practice — points at that same
directory. Now two programs share a directory and neither needs to know the
other exists:

- The **server owns the calendar**: display, editing UI, the CalDAV protocol,
  and the `.ics` files once they exist. We do not eat that complexity.
- **ClearHead owns the actions**: it writes a plan's `.ics` when the underlying
  action changes, and reads `.ics` back to propagate calendar-side edits into
  actions.

The coordination mechanism is **the shared data, not a shared protocol**. We do
not model the server's internals or its failure modes — that way lies an
unbounded integration layer. We agree on one contract: the vdir `.ics` files on
disk. Two consequences:

- **Read `.ics` only.** A CalDAV server keeps its own sidecar state next to the
  files (radicale writes its own `.json`). That is the server's implementation
  detail, tied to *its* identity model, and we must never read it in — only the
  `.ics` is the shared contract.
- **Once a plan's `.ics` exists, the server owns the file.** We overwrite it
  only when our action actually changed, and we never delete a file that is
  present. Idempotent regeneration only removes `.ics` files that are *absent*
  from the model — never ones already on disk. This is what makes the sharing
  bidirectional with no integration layer.

## Syncing state (the three-way table)

Edits can originate on either side, and we want to honor both without knowing
*when* anything changed. We get that with a stored merge base. Two new
action-level properties hold a copy of the action's dates at last sync:

- `scheduled_at_sync` — copy of `scheduled_at`
- `due_at_sync` — copy of `due_at`

That gives three observable values per date:

- **A** — the action's current date
- **B** — the sync-copy (the merge base)
- **C** — the date in the `.ics`

Comparing each against B tells us who moved, with no timestamps:

| A vs B  | B | C vs B  | result          |
|---------|---|---------|-----------------|
| same    | — | same    | no-op           |
| changed | — | same    | write C and B   |
| same    | — | changed | write A and B   |
| changed | — | changed | conflict-merge  |
| removed | — | same    | remove C and B  |
| same    | — | removed | remove A and B  |
| removed | — | changed | conflict-merge  |
| changed | — | removed | conflict-merge  |

When reconcile lands a result, the action (A) and its sync-copy (B) must move
**together** — that is exactly the A+B commit the write-durability seam exists
for. If only one landed, B would lie about the merge base on the next run.

**B drifting is a bug, not an edit.** B is *our* copy; it should only ever move
when reconcile moves it. If a run finds B changed or removed on its own,
something corrupted the merge base — log it loudly and surface guidance rather
than treating it as a normal change.

## Conflict-merge

The four conflict rows mean both sides moved and we cannot pick safely. The
tools surface the conflict and let the user decide — never silently choose:

- **both changed:** which source wins.
- **one removed, one changed:** whether the removal or the edit is the intent.

## Scope boundary

This charter does not build a calendar UI, speak CalDAV, or manage recurrence
display — the server owns all of that. It builds the shared directory, the
read-only `.ics` discipline, the merge-base properties, and the reconcile table.
