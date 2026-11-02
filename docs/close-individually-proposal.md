---
type: Proposal
title: Close One Action by Default, Separate from Archiving
description: Revised plan for =close-individually after Darrion's 2026-11-02 answers, checked against the code as of Core 5e18864. Closing and reopening change state in place; archive and unarchive are the only things that move lines, and they move whole root trees.
status: accepted
date: 2026-11-02
sources:
  - DECISIONS.md
  - ../specifications/process.md
  - ../specifications/workspace.md
  - ../specifications/linting.md
  - ../clearhead-core/docs/DECISIONS.md
---

# Close one action by default, separate from archiving

Approved by Darrion on 2026-11-02 ("lets get that done"), and amended the same day for their answer on the cascade. The goals are [Decision 58](DECISIONS.md#decision-58-closure-is-a-state-transition-archive-is-storage) and [Decision 59](DECISIONS.md#decision-59-archive-and-unarchive-move-whole-root-trees). What is still open is in [Open](#open).

## The verbs

| Command | State | Lines move? | Refuses when |
| --- | --- | --- | --- |
| `complete` / `cancel` | The target only | No | Target closed (`AlreadyClosed`) |
| `... --cascade` | Target and every open member to the verb's state; closed members keep state and date | No | Never: if the outcome already holds, it succeeds and changes nothing |
| `reopen` | The target only, in the active file | No | Target open, or archived (names `unarchive` and the root) |
| `reopen --cascade` | Target and every closed member to not started, dates cleared; open members keep their state | No | Archived (names `unarchive` and the root). Nothing closed succeeds and changes nothing |
| `archive action <id>` | None | The tree, to the completed file | Not a root, or anything in its tree is open |
| `archive actions [scope]` | None | Every eligible tree | Never; ineligible trees stay |
| `unarchive action <id>` | None | The tree, to the active file | Not a root (names the root), or already active |
| `unarchive action <id> --reopen` | The root only; children stay closed with their dates | The tree, to the active file | As above |
| `unarchive action <id> --reopen --cascade` | The root and closed members; dates cleared | The tree, to the active file | As above |

Nothing archives on a CLI close. `nvim_archive_on_save` is unchanged: on in Darrion's config, off by default.

## What exists today

Tested on a Core 5e18864 build in scratch workspaces, unless marked "read".

| Case | Today | After the change |
| --- | --- | --- |
| `complete` a child | Moves it to the completed file and drops its parent link | Stays in place, keeps its link |
| `complete` a parent with an open child | Closes and moves the whole subtree | Closes the parent only; the result names the open child |
| `reopen` a closed line still in the active file | `not-found` | Reopens in place |
| `reopen` an archived child whose parent is also archived | Crashes in formatting (`>[ ] A` at top level); writes nothing. **Live bug** | Refuses and names the root |
| `reopen` an archived parent | Every child returns open; a child cancelled alone loses its state and date | Refuses and names `unarchive` |
| `archive` a closed branch under an open root | Nothing moves | Same |
| `archive` a closed root with an open child | Nothing moves | Same |
| `orient` recent completions | Reads completed files only, so closed lines in the active file don't appear | Must read both |
| `archive`, sidecar | The entry stays in `.home.json`; no completed sidecar is written | Moves with the line, both ways |
| `archive actions <action-id>` | The scope resolves to the action's whole file (read; my scratch run errored before reaching it) | Unchanged; `archive action <id>` is the single form |

### Plain unarchive and archive on save: the sweep-back is real

Tested through real `archive_saved` in headless Neovim with `nvim_archive_on_save` on, using a closed tree placed in the active file as `unarchive` would leave it.

| What happens next | Result |
| --- | --- |
| Save with the root still closed, even for an edit elsewhere in the file | The tree goes straight back to the completed file |
| Reopen the root in the buffer, then save | Stays: the hook runs after the write, and the root is open |
| Reopen one child, leaving the root closed (CLI sweep, not Neovim) | Stays, with W002 |

The sweep loses nothing: states, dates and tree links all survive the round trip. CLI commands don't save, so `unarchive` then `reopen` is safe unless a save falls between them. `unarchive --reopen` never meets this.

**Consequence, not a problem to engineer around:** with archive on save on, plain `unarchive` holds only until the next save of that file. "The root unarchive is a move" and "the archive on save stays on" both stand, and this follows from them. The docs state it; the sweep gets no exception, because a marker saying "don't sweep this" is new state to serve a case the two-step and the flag already cover.

### Other findings

**Successor readiness: settled.** A successor is ready when its predecessor is closed in the active file, as when it is in the completed file (`orient`; a still-open predecessor holds it back). The work pins this with a test.

**Closed lines and charter archive.** `archive charter` accepts closed lines in the active file and moves them to `archive/<id>.actions`, not `<id>.completed.actions`. `read_archived_action_facts` reads only the latter (read), though nothing calls it today. This already happens for lines closed in Neovim with the sweep off, and it becomes the common case for agent closes, so `archive charter` sweeps eligible trees first.

**W003 is now ordinary.** An open parent whose children are all closed draws W003, "Should this parent be closed too?". Reopening only the root after an unarchive draws it, and so does closing the last child singly. W002 doesn't fire on either: it is the opposite shape. Darrion's "that should still be a warning by default" describes W003, and both rules stay warnings.

**Lint settings.** `linting.md` says rules can be disabled, and neither Core nor the CLI has code for it. That capability is general, not part of this work: `=lint-rule-disable`.

**Recurring occurrences depend on close moving the line (read, not tested end to end).** After a close, `resolve_materialized_occurrence` looks for the line in the completed file only, to record its Plan UID and recurrence key, and then removes the live link. If the line stays in the active file, that lookup finds nothing, and the link is removed with no record kept. Nothing reports it, and `process.md` "On Closure" requires that record. The fix: record the link in the sidecar of the file holding the line, and have `archive` and `unarchive` move the entry with the line.

**`transact` never resolves occurrences (read).** `cli/transact.rs` doesn't call that function, so closing an occurrence by transaction writes no deviation and stamps no next token, and `complete` resolves only the root of a subtree. A cascade built on transactions would inherit the gap, so resolving goes in the single close that everything shares.

**Reopen doesn't undo an occurrence's deviation (read).** That is true today and stays so; it isn't part of this work.

## The design

**Close.** `complete` and `cancel` set one action's state and `completed_at` in place and write only the active file. The result drops `children` and gains `open_children`, the ids left open beneath it, so a forgotten child is visible without any rule forbidding the shape.

**Reopen.** State `NotStarted`, date cleared, active file only. Anything archived is refused, with the root and `unarchive` named. This also removes the crash.

**Cascade.** Core expands `--cascade` into an ordered list of single operations and commits them as one transaction, as Darrion described. The expansion holds the target unless it is already in the verb's state, plus every open member, walking through closed ones. So `complete --cascade` on a `[_]` target makes it `[x]` with a new date, on an `[x]` target leaves its date alone, and `cancel --cascade` mirrors this. An empty list is a success that changes nothing. `reopen --cascade` holds the target if closed, plus every closed member. The single verbs keep Core Decision 2's rejection of a closed target; only the cascade may force one, which is its own operation in the expansion, not a loosening of that guard. Forcing a closed target closed does not resolve an occurrence a second time: resolving belongs to the move from open to closed. `close_subtree` and `reopen_subtree` go once nothing calls them; `collect_subtree_ids` stays, for cascade and `delete`.

**Transact.** It gains `reopen-action`. `complete-action` and `cancel-action` become single operations; callers already name each action, and the [published schema](../specifications/schemas/transaction_request.schema.json) stops promising a cascade and a file move.

**Archive.** `plan_action_archive` already chooses a closed root with a fully closed tree, and keeps the links inside it. It gains a selection: one root, or every eligible root. It moves sidecar entries too.

**Unarchive.** The mirror of archive, active file written first as `reopen` does today, sidecar entries included. A line left detached by the old close is a root in the completed file, so it unarchives as a root; its old parent is not recorded anywhere. Actions inside an archived charter (`archive/`) aren't reached: that would be unarchiving a charter, which nobody has asked for.

**Occurrences.** Resolving moves into the shared single close, so verbs, transactions and cascades all write the deviation and advance the token.

### Readings of Darrion's words

Stated so they can be corrected:

- **A cascade forces its target (Darrion, 2026-11-02, charter log; this replaces the earlier reading that a closed target keeps its state and date).** "if we say cascade the implication is 'this and all children should be closed GO' the only piece that we skip is stuff that is already closed so it doesnt lose the closure date and cancelled is a different thing so if im closing it im CLOSING it do what i mean and stop trying to be smart". Members already closed, cancelled ones included, keep their state and date. How-level, on the facilitator's reading: a target already `[x]` keeps its date, a target that was `[_]` becomes `[x]` with a new date, `cancel --cascade` mirrors this, and `reopen --cascade` follows the same spirit.
- **Single-action archive takes a root only.** Darrion stated the root rule for unarchive; for archive it is an inference, asked on `=archive-child`, and built as written meanwhile: it refuses and names the root, which can be relaxed later. A child can't keep its link in the completed file: a `>` line with no parent there is a syntax error that makes the whole file unreadable. So it would have to detach, and could then return only as a new root, the "do we make it a new root?" Darrion wanted to avoid.

### How-level calls

- **Bulk archive is the single archive applied to each eligible root,** through the same planner, one commit per file as today. Behaviour is unchanged, except that the single form refuses with a reason where bulk skips. `transact` gets no archive operation: nothing needs one yet, and it can be added later without breaking anything.
- `reopen --cascade` on an open target with closed members reopens them and leaves the target's state alone.
- A closed child under an open parent stays in the active file until its root's tree closes. A long-lived parent collects closed lines.
- `update` keeps refusing closed actions and terminal states, since `complete` remains the one door that stamps the date. Only the stated reason changes, because "a shape close can never produce" stops being true.
- Neovim's `set_state_tree` overwrites a `[_]` child with `[x]`, against Core Decision 2. It gets fixed in this work.
- W002 stays a warning, reworded from "cannot be marked as closed" to report the contradiction. W003 is unchanged.

## Open

**Single-action archive on a child:** `=archive-child`, not blocking this work.

**Settled, `unarchive --reopen`:** "--reopen and --cascade need to be two separate flags, one cascades down to the whole tree, while the other reopens the single action. combined, they will open AND move the whole tree. composobility". So `--reopen` is `unarchive` plus `reopen`, with W003 firing over the closed children, and adding `--cascade` is `unarchive` plus `reopen --cascade`. The tree always moves whole, so `--cascade` without `--reopen` changes nothing and is refused as a usage error.

**Left open by Darrion:** whether reopen becomes "more granual in another format".

## What changes

In order, per [Decision 54](DECISIONS.md#decision-54-implementations-rely-only-on-published-pinned-releases):

1. **specifications, released first:** `workspace.md` Archival item 2 (closing no longer moves a line; archive and unarchive do, by root tree); W002's wording, and its third example, `[x] Parent` over `[_] child`, which has no open child and which the linter doesn't flag; the transaction schema, its examples and `explanations/data_workflows.md`.
2. **clearhead-core, one landing:** single close and reopen, the transaction fold and `reopen-action`, cascade expansion, `archive action`, `unarchive action`, the sweep in `archive charter`, the occurrence record and resolving, sidecars both ways, `orient`, the CLI help, man page and README. Close and reopen land together, because in-place close without in-place reopen leaves closed lines that nothing can reopen. An entry in Core's `docs/DECISIONS.md` amends Core Decision 2 for `--cascade`.
3. **clearhead.nvim:** the `set_state_tree` fix, `:Clearhead unarchive`, and the docs, including the sweep-back above, against the new release. Pins move the same session.
4. **The clearhead skill:** the close verbs, `--cascade`, `unarchive`, and when to archive.

**Who is affected.** I searched `assistant/scripts`, `agent-sandbox` and `meta-analysis/workflows` and found no caller of these verbs and no reader of `.completed.actions`. `docs/overnight-runbook.md` tells workers to run `clearhead complete action <id>` when done; that command keeps working, but a parent's children now stay open. Size is unmeasured, so I give no estimate.

**Tests that must exist before landing:** closing a parent and its children singly then archiving gives the same tree as a cascade; `complete --cascade` makes a `[_]` target `[x]` with a new date, keeps an `[x]` target's date, closes its open members and leaves closed members' states and dates alone (and `cancel --cascade` mirrors all of it); a cascade with nothing to do succeeds and writes nothing, for close and for reopen; the single verbs still refuse a closed target; archive then unarchive is lossless, including mixed states, dates and sidecars; archive and unarchive refuse a non-root and name its root; `archive charter` leaves closed lines in the completed file; an occurrence closed in place keeps its Plan link through archive; a successor is ready with a closed predecessor in the active file; and `reopen` on the crash case refuses cleanly.
