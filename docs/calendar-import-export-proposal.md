⏸ Decision — With calendars outside the workspace, which edits should return: **A, the full Decision 57 contract; B, dates/times (including series and individual occurrences) plus new one-off events; or C, dates/times and new events for one-offs only?** B and C would explicitly withdraw calendar-side deletion, recurrence-rule editing and kind conversion. Recommendation withheld until Darrion answers.

# Calendars outside the workspace

Analysis only, 2026-10-26. No implementation or specification change is authorized by this proposal.

## What is already settled

ClearHead **does not do network calendar sync**. [The cookbook](../clearhead-core/crates/clearhead-cli/docs/cookbook/radicale-vdirsyncer.md) already delegates that to vdirsyncer. Import/export would replace the *Action ↔ calendar reconciliation interface*, not a CalDAV implementation.

[Decision 57](DECISIONS.md#decision-57-habits-live-in-their-own-actions-file) makes text authoritative, but promises editable projections: series time/rule edits, occurrence overrides, kind-change proposals, retained native identities, confirmed UID relinking, held replacements and doctor repair. [Decision 55](DECISIONS.md#decision-55-the-calendar-shows-set-aside-time-vtodo-sync-is-retired) additionally promises two-way names/descriptions as an experiment. These are not all implemented: the pinned specification v0.3.0 and Core `9597131` still have VTODO integration, calendar-owned recurring Plans and one-live-occurrence stamping. VEVENT currently merges only scheduling fields. Removing unimplemented promises is **avoided work, not deleted code**.

Moving the vdir also amends [Decision 31](DECISIONS.md#decision-31-plans-vdir-synchronization-boundary), which deliberately fixed it at `<data_root>/plans/`. Its configurable predecessor was removed because sharing one root across workspaces caused mutual quarantine (specification commit `dbd9966`, 2026-09-24). Do not recreate that failure.

## Common boundary for all three choices

- One **external vdir dedicated to one workspace**, with the existing exact charter-to-collection ownership. A machine-local binding names its path; never share the same root between workspaces. No account, URL or transport configuration enters Core.
- The workspace contains Actions, Habits and durable semantic sidecars. Routine reads and Habit occurrence generation must work without the vdir. This requires Decision 57's text-Habit migration first; moving today's calendar files alone would move authoritative recurrence *out* of the workspace.
- Export updates that external vdir; import reads the **same** vdir. Do not add a second inbox/outbox mirror. Existing UIDs, transport-selected filenames, alarms and unknown properties survive surgical updates. The external copy is not wholly disposable: alarms/vendor data not represented natively still need backing up.
- A serialized cycle is `vdirsyncer → import → export → vdirsyncer`. Import previews changes and holds conflicts. Export must refuse to overwrite unimported changes or held resources, including after a failed import. Separate commands do not remove the need for revision checks, merge bases or durable delivery. ClearHead's lock cannot lock vdirsyncer; the surrounding cycle must not overlap itself, and external file changes must invalidate stale evidence.
- Keep native UUID ↔ UID links in committed sidecars and merge bases in machine-local state. Keep the existing small three-way comparison: without a base, an import cannot distinguish a phone move from an older calendar copy after a text edit. State loss must surface disagreements, not choose a winner.

These are proposed constraints, not a new configuration contract already decided.

## Options and exactly what disappears from the user's calendar

| Choice | Imports | What the user loses versus Decisions 55/57 |
| --- | --- | --- |
| **A — full editable projection, external location** | Names, descriptions, block times, new one-offs/Habits, recurrence and exceptions; confirmed kind conversions and UID links. | No promised editing capability. Only the workspace-local vdir path changes; calendar tooling must be repointed. All Decision 57 safeguards remain to be built. |
| **B — bounded scheduling** | Linked one-off start/end; linked Habit series start/end with its rule unchanged; individual occurrence start/end using the original slot; new genuinely unrelated one-off events (title/description seed the Action). | No phone rename/description updates after adoption; no calendar-side unschedule, cancellation, recurrence-rule/RDATE/EXDATE changes, new recurring Habits, series splits or one-off ↔ recurring conversions. Do these in ClearHead text. Occurrence moves made before materialization still need a sidecar override. |
| **C — one-off return path** | Linked one-off start/end and new genuinely unrelated one-off events, as B. | Everything B loses, **plus all calendar-side edits to Habits and their occurrences**, even a single dragged occurrence. Habits still display as recurring events; edit their series/occurrences in ClearHead. |

For B/C, deleting a calendar event does not unschedule or cancel its Action; report it and restore the projection on export. Unsupported edits must be reported and held, not silently imported or overwritten; the user restores the calendar version or makes the intended change in ClearHead, then resolves the hold. A suspected UID replacement holds the relationship before export can restore an old copy or import a duplicate. Unrelated new one-offs get independent native UUIDs and retain their foreign UIDs.

**Narrowing edits does not license dropping Decision 57 identity safety.** DAVx5 replaced UIDs on “does not repeat” and “this and following”; the [2026-10-16 charter findings](../.clearhead/charters/README.md) document both. B/C still need replacement detection, explicit linking, ambiguous/unmatched holds and doctor visibility. Linking alone must not accept a prohibited kind/rule change. No new automatic similarity matcher or native-ID merge is proposed. Unsupported calendar conversions would require a native text edit or calendar reversion instead of A's accept/revert/defer conversion workflow.

## Measured cost — relocation is not deletion

Recounted from the committed Core pin, not estimated from the desired design. Physical Rust lines include comments/blanks. “Pre-test” ends immediately before the file's `#[cfg(test)]` module; it is not executable SLOC.

| File (under `clearhead-core/crates/`) | Whole file | Pre-test | Test section |
| --- | ---: | ---: | ---: |
| `clearhead-core/src/workspace/calendar/reconcile.rs` | 3,384 | 2,285 | 1,099 |
| `clearhead-core/src/workspace/calendar/ics.rs` | 2,207 | 1,322 | 885 |
| `clearhead-cli/src/filesystem/calendar.rs` | 2,163 | 1,210 | 953 |
| **Total** | **7,754** | **4,817** | **2,937** |

Counting `git -C clearhead-core ls-files '*.rs'` with Python `splitlines()`, the repository has **56,372 tracked Rust lines**, so the reported “about 14%” is **13.8%**, including tests. The two crates' `src/` trees alone have 43,621 lines; use the same denominator when comparing later. An additional `sync_store.rs` has 137 pre-test lines (176 total), retained by every editable option.

The following is a **deletion-eligibility audit**, not a compiled patch or a forecast of net savings. Counts are complete function bodies, signature through closing brace, excluding preceding documentation; replacement scopes are not exclusively inbound code. All other savings require splitting shared functions; no guessed percentage is attached to them.

| Choice | Measured removal/replacement scope from narrowing imports | Machinery still needed |
| --- | --- | --- |
| **A** | **0** from relocation alone. | Both scheduling planners, merge/report/apply, surgical ICS writes, native delivery and state. Decision 57 conversion/link/hold work is additional and currently unmeasured. |
| **B** | **0 identified** in the audited three files. Calendar-deletion handling shares its unlink path with Action-side unscheduling. Names/rules/kind conversion restrictions mostly avoid promises not yet implemented for VEVENT. | Both scheduling planners; occurrence parsing/rendering; sidecar overrides; conflict/state/delivery machinery. Unsupported-edit reporting adds work. |
| **C** | **123-line replacement scope**: `reconcile.rs:477–599`, `plan_recurring_occurrence_sync`. It plans both directions: remove its inbound role but replace its outbound role with export planning. **Not 123 net deletable lines**, and includes VTODO branches separately due for retirement. | The 126-line one-off planner (`344–469`); occurrence codecs still needed for outbound native moves; identity/hold/delivery machinery. Other mixed paths need rewriting, not wholesale deletion. |

Why the large files cannot simply go:

- The generic merge is only **30 lines** (`reconcile.rs:59–88`). `apply_report` is **145** (`688–832`) and `prepare_sync` **453** (`941–1393`): mixed import, projection, sidecar, lifecycle and batch preparation. B/C retain these responsibilities, though their interfaces should separate import from export.
- **353 lines** in that same file implement occurrence closure/stamping (`1396–1618`, `1698–1735`, `1737–1828`). Decision 57 requires replacing the live-token policy with text-Habit catch-up **regardless of calendar editing**. Those are not savings earned by B/C.
- The adapter's **307-line** `prepare_calendar_sync` (`191–497`) mixes orchestration, adoption, deletion, codec migration and projection. Its deletion/unschedule loop (`315–344`, 30 lines) cannot all be removed: native unscheduling must still remove the exported event.
- Parsing, time frames/DST, duplicate-UID validation and surgical writes survive all choices. Dropping import entirely would retire the two two-way planners plus generic merge (**279 lines of replacement scope**), but outbound planning still needs a replacement. It loses **all** phone edits and capture, not recurrence generation or export codecs.

Thus this audit finds **no large current-code reduction from B**, and only a small two-way planning scope to replace for C. B avoids building rule/kind-conversion semantics; it does **not** avoid two-way identity and conflict handling. The earlier [VEVENT-only analysis](history/vevent-only-calendar.md) already distinguished profile removal from export and warned against deleting shared coverage. VTODO retirement is separately authorized by Decision 55; do not count it again as an import/export saving. No net deletion claim or implementation-time estimate is justified without a reviewed implementation diff.

## After Darrion chooses

Record the amendment to Decisions 31/55/57, then release the coherent specification/schema/fixture changes before Core adopts them (Decision 54). Coordinate with `spec-habits`/`core-habit`, not a parallel competing calendar design. Required proofs: no-vdir native Habit operation; native identity through UID replacement; held events never duplicated or overwritten; safe replay/state loss; concurrent text/phone edits; DST/all-day/floating slot stability; unknown-property preservation; and every supported/unsupported edit in the chosen table.

**Recommendation deliberately withheld.** The choice is how much calendar authority is worth retaining, not whether vdirsyncer should own transport—it already does.
