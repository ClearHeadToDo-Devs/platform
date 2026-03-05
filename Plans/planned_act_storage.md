---
status: active
created: 2026-03-04
---
# PlannedAct Storage: JSON-LD Sidecar Files

## Context

The domain model has a clean Plan/PlannedAct split: Plans are information content (what, defined
by a human in `.actions` files), PlannedActs are occurrences (when, tracked by the system).

The current `convert::from_actions` path synthesises a single PlannedAct per Action at read
time, which works for one-off tasks but breaks for recurring ones — you cannot record that
Tuesday's standup was completed without affecting the recurrence template. There is no
persistence layer for PlannedAct state.

This plan introduces `.acts.jsonld` sidecar files as that persistence layer.

---

## Design Decisions (locked)

**File placement**: Sidecar alongside the paired `.actions` file.
- `health.actions` + `health.acts.jsonld` move together, version control together
- LSP loads the companion automatically
- Contrast: objectives live in `objectives/` subfolder (many-to-many with charters, not 1:1 paired)

**Format**: JSON-LD with `@context` mapping to the actions vocabulary IRIs.
- The context IS the schema — no separate JSON Schema needed (that would duplicate the ontology)
- Valid JSON, hand-editable, `serde_json` reads it
- Roundtrips to TTL cleanly for the archive path
- Upgrade to full JSON-LD processor (e.g. oxigraph JSON-LD support) incrementally

**Who uses the file**:
- One-off tasks: act state lives in the `.actions` checkbox — no sidecar needed
- Recurring tasks: sidecar tracks individual instances (completed, rescheduled, cancelled)

**Archive**: completed/old acts sweep from `.acts.jsonld` into `archive.ttl` (loaded into
oxigraph for SPARQL-based historical queries). This mirrors how `archive plans` works for Plans.

---

## Target JSON-LD Format

```json
{
  "@context": {
    "PlannedAct":   "cco:ont00000228",
    "plan":         "actions:prescribedBy",
    "phase":        "actions:hasActPhase",
    "scheduledAt":  "actions:hasScheduledDateTime",
    "completedAt":  "actions:hasCompletedDateTime",
    "duration":     "actions:hasDurationInMinutes",
    "createdAt":    "actions:hasCreatedDateTime"
  },
  "@graph": [
    {
      "@type": "PlannedAct",
      "@id": "urn:uuid:act-id-here",
      "plan": "urn:uuid:plan-id-here",
      "phase": "actions:NotStarted",
      "scheduledAt": "2026-01-27T09:00:00",
      "duration": 15
    },
    {
      "@type": "PlannedAct",
      "@id": "urn:uuid:act-id-2",
      "plan": "urn:uuid:plan-id-here",
      "phase": "actions:Completed",
      "scheduledAt": "2026-01-20T09:00:00",
      "completedAt": "2026-01-20T09:12:00",
      "duration": 15
    }
  ]
}
```

Rescheduling an instance = change `scheduledAt` on that entry.
Cancelling = change `phase` to `"actions:Cancelled"`.

---

## Gaps in Implementation Order

### Gap 1: Verify oxigraph JSON-LD support

**Severity**: Prerequisite for deciding parse strategy.

oxigraph 0.5.3 is already a dependency. Does it parse JSON-LD as an input format via
`Store::load()`? If yes, we get SPARQL over act files for free. If not, we implement a
custom `serde_json` deserializer that treats the JSON-LD as structured JSON (same data, no
semantic processor). Either way the file format stays identical — this is a tooling choice,
not a schema choice.

Check `oxigraph::io::RdfFormat` for a `JsonLd` variant.

### Gap 2: PlannedAct JSON-LD reader/writer

**Severity**: Blocking everything else.

New module: `clearhead-core/src/workspace/acts/` (or `clearhead-core/src/workspace/acts.rs`).

**Writer** — `write_acts(acts: &[PlannedAct], path: &Path) -> Result<(), String>`:
- Serialize `Vec<PlannedAct>` to the JSON-LD format above
- Write to `<stem>.acts.jsonld` alongside the `.actions` file
- IDs as `urn:uuid:<id>`, phase as `actions:<Phase>` named individual string

**Reader** — `read_acts(path: &Path) -> Result<Vec<PlannedAct>, String>`:
- Parse the JSON-LD file back into `Vec<PlannedAct>`
- If file does not exist: return `Ok(vec![])` (not an error — optional companion)
- Validate: every act must have a `plan` reference (plan_id) and a `phase`

**Tests**: roundtrip test — write acts, read them back, assert equal. Include the
rescheduled-instance and completed-instance cases.

### Gap 3: Workspace discovery update

**Severity**: Blocking workspace-level export and LSP integration.

`workspace::load_workspace()` currently discovers `.md` (charters) and `.actions` (plans).
It needs to additionally pair `<stem>.acts.jsonld` with the `.actions` file it belongs to.

Discovery rule: for every `.actions` file discovered, check for a sibling `<stem>.acts.jsonld`.
If found, load it and attach acts to their Plans via `plan_id` matching.

The merge logic:
- `convert::from_actions` creates one synthetic PlannedAct per Action (the "template" act)
- If a `.acts.jsonld` exists, REPLACE the synthetic acts on each Plan with the loaded ones
- Plans with no matching acts in the file keep their synthetic act (graceful fallback)

This gives us: `.acts.jsonld` wins when present, synthesised act as default when absent.

### Gap 4: Export reads companion acts file

**Severity**: Blocking correct calendar output for recurring plans.

Currently `export plans health.actions` ignores `health.acts.jsonld`. Completed or rescheduled
instances are invisible in the calendar output.

Update `commands/plan::export_plans`:
1. After loading the `.actions` file and calling `convert::from_actions`, check for a sibling
   `.acts.jsonld` at the same path stem
2. If found, load it and replace synthetic acts with real ones
3. Then call `format_as_icalendar` as before

For stdin input there is no sibling file — synthetic acts only, which is correct behaviour.

### Gap 5: Act expansion command

**Severity**: Required to populate `.acts.jsonld` in the first place.

`DomainModel::expand_recurring_plans(days)` already generates PlannedActs from recurrence rules.
Nothing calls it and writes the result to disk.

New command: `clearhead expand acts [<file>] [--days N]`

Behaviour:
1. Load `.actions` file → DomainModel
2. Load sibling `.acts.jsonld` if present (existing instances)
3. Call `expand_recurring_plans(days)` — adds future acts, skips IDs already in the file
4. Write merged acts back to `.acts.jsonld`

`--days` defaults to a reasonable window (30? 90?). This is the command that bootstraps the
file for a newly recurring plan and extends it as time passes.

### Gap 6: Act state management commands

**Severity**: Needed for the manual editing workflow.

Editing the JSON-LD by hand is acceptable for power users, but CLI commands make it
accessible and safe.

`clearhead complete act <act-id> [--file health.acts.jsonld]`
- Sets `phase` to `Completed`, adds `completedAt: now()`

`clearhead update act <act-id> --scheduled-at <datetime> [--file health.acts.jsonld]`
- Reschedules a specific instance without affecting the Plan's recurrence template

`clearhead cancel act <act-id> [--file health.acts.jsonld]`
- Sets `phase` to `Cancelled`

The `--file` arg should default to discovering the `.acts.jsonld` from the current directory
or the workspace default, same pattern as other commands.

### Gap 7: `read acts` noun (from calendar_integration.md)

**Severity**: Needed for the target `read acts --format vcalendar` command.

This is Gap 2 in `Plans/calendar_integration.md`. Depends on Gap 3 (workspace discovery)
so that `read acts` can see real PlannedAct state, not just synthesised ones.

See `calendar_integration.md` for detailed breakdown. Do not re-document here.

### Gap 8: Archive acts

**Severity**: Low — operational before this, but needed for clean long-term hygiene.

`clearhead archive acts [<file>]`
- Reads `.acts.jsonld`
- Moves Completed/Cancelled acts older than N days into `archive.ttl`
- Uses existing oxigraph store + `insert_planned_act` path
- Mirrors `archive plans` behaviour

---

## Objectives Discovery (separate but related)

Objectives live in `objectives/` subdirectory as markdown files, paralleling how charters
are `.md` files in the workspace root. This is a workspace discovery update independent of
the act storage work, but should land around the same time for a complete DomainModel.

Not detailed here — scope this as its own plan if it grows complex.

---

## Recommended Order

1. Gap 1 (oxigraph JSON-LD check) — 30 minutes, determines parse strategy
2. Gap 2 (reader/writer) — core of the work, everything else depends on it
3. Gap 4 (export integration) — quickest win, immediately useful
4. Gap 5 (expand command) — required to populate files for recurring plans
5. Gap 3 (workspace discovery) — enables workspace-level commands
6. Gap 6 (state management commands) — completes the edit workflow
7. Gap 7 (read acts noun) — see calendar_integration.md
8. Gap 8 (archive) — last

---

## Files to Change

| File | Change |
|------|--------|
| `clearhead-core/src/workspace/acts.rs` | CREATE: reader/writer for `.acts.jsonld` |
| `clearhead-core/src/workspace/mod.rs` | add `pub mod acts` |
| `clearhead-core/src/workspace/store.rs` | update discovery to load sibling act files |
| `clearhead-cli/src/commands/plan.rs` | update `export_plans`, add `expand_acts` |
| `clearhead-cli/src/argparser.rs` | add `ExpandTarget::Acts`, act management commands |
| `clearhead-cli/src/main.rs` | wire new commands |
| `clearhead-cli/tests/` | add `acts_storage.rs` integration tests |
