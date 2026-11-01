---
type: Proposal
title: Close One Action by Default, Separate from Archiving
description: Design draft for =close-individually, checked against the code as of Core 5e18864. Closing changes one action's state in place; archiving is the only thing that moves files.
status: proposed
date: 2026-11-01
sources:
  - DECISIONS.md
  - ../specifications/process.md
  - ../specifications/workspace.md
  - ../specifications/linting.md
  - ../clearhead-core/docs/DECISIONS.md
---

# Close one action by default, separate from archiving

Draft for Darrion's review; no worker has started. The goals are [Decision 58](DECISIONS.md#decision-58-closure-is-a-state-transition-archive-is-storage). This covers how to reach them and what they cost. Open questions are on the action `=close-individually`, with their options in [Questions](#questions) below.

## The target is mostly here already

Three parts of the system already work this way. The CLI verbs are the exception.

- **Specification.** `process.md` "On Closure" and "On Child Actions" already say this; `workspace.md` Archival item 2 does not (see [What changes](#what-changes)).
- **Neovim.** `<localleader>x` closes one line in place and `<localleader>X` closes the tree, and archiving is a separate step.
- **The archive planner.** `plan_action_archive` moves only a closed root whose whole tree is closed, and it keeps the links inside the tree. No change is needed to its choice of what moves.

## What exists today

Tested on a Core 5e18864 build in scratch workspaces, unless marked "read".

| Case | Today | After the change |
| --- | --- | --- |
| `complete` a child | Moves it to the completed file and drops its parent link | Stays in place, keeps its link |
| `complete` a parent with an open child | Closes and moves the whole subtree | Closes the parent only; the result names the open child |
| `reopen` a closed line still in the active file | `not-found` | Reopens in place |
| `reopen` an archived child whose parent is also archived | Crashes in formatting (`>[ ] A` at top level); writes nothing. **Live bug** | Question B |
| `reopen` an archived parent | Every child returns open; a child cancelled alone loses its state and date | Only the target changes |
| `archive` an open parent with a closed child | Nothing moves | Same |
| `archive` a closed parent with an open child | Nothing moves | Same |
| `orient` recent completions | Reads completed files only, so closed lines in the active file don't appear | Must read both |
| `archive`, sidecar | The entry stays in `.home.json`; no completed sidecar is written | Must move (below) |

### Archive on save: how far it reaches

`nvim_archive_on_save` is Neovim only and off by default, though on in Darrion's config. After a save of an active `.actions` file it runs `clearhead archive actions --file <file>` for that file alone (read; the code and `doc/clearhead.txt` agree).

- **CLI:** nothing sweeps. Today that doesn't matter because close moves the line. After this change, a line closed only through the CLI stays in the active file until someone runs `clearhead archive actions`. That covers every agent close. Question A.
- **Neovim quickfix `complete`/`cancel`:** these call the CLI and don't save, so they don't sweep either (read).
- **LSP:** never archives, by documented design. **VS Code:** the submodule checkout holds only a `LICENSE`, so there is no client code to change here.

### Coupling the action did not name

**Recurring occurrences depend on close moving the line (read, not tested end to end).** After a close, `resolve_materialized_occurrence` looks for the line in the completed file only, to record its Plan UID and recurrence key, and then removes the live link. If the line stays in the active file, that lookup finds nothing, and the link is removed with no record kept. Nothing reports it, and `process.md` "On Closure" requires that record. Plain `archive` doesn't carry sidecar entries either, so the fix has two parts: record the link in the sidecar of the file holding the line, and have `archive` move the entry with the line.

**`transact` never resolves occurrences (read).** `cli/transact.rs` doesn't call that function, so closing an occurrence by transaction writes no deviation and stamps no next token, and `complete` resolves only the root of a subtree. A cascade built on transactions would inherit the gap, so resolving has to be part of the single close that everything shares.

**Not verified:** whether a successor is ready when its predecessor is closed but still in the active file. My scratch runs were inconclusive, so the work has to pin this with a test.

## The design

**Close.** `complete` and `cancel` set one action's state and `completed_at` in place and write only the active file. A closed target is still `AlreadyClosed`. The result drops `children` and gains `open_children`, the ids left open beneath it, so a forgotten child is visible without any rule forbidding the shape.

**Reopen.** `reopen` looks in the active file first and reopens the line in place: state `NotStarted`, date cleared. An archived target follows Question B.

**Cascade.** `--cascade` on all three verbs expands in Core into an ordered list of single operations and commits them as one transaction, as Darrion described. `complete` and `cancel` skip closed members and walk through them to reach open ones, as [Core Decision 2](../clearhead-core/docs/DECISIONS.md) requires. `reopen --cascade` reopens every closed member and clears their dates; that is the explicit way to undo independent closures, and git keeps the old lines. `close_subtree` and `reopen_subtree` go once nothing calls them; `collect_subtree_ids` stays, for cascade and `delete`.

**Transact.** It gains `reopen-action`. `complete-action` and `cancel-action` become single operations; callers already name each action, and the [published schema](../specifications/schemas/transaction_request.schema.json) stops promising a cascade and a file move.

**Archive.** Its choice of what moves is unchanged, and it now moves sidecar entries too.

**Occurrences.** Resolving moves into the shared single close, so verbs, transactions and cascades all write the deviation and advance the token.

### How-level calls

- A closed child under an open parent stays in the active file, so the tree and its links stay whole; the cost is that a long-lived parent collects closed lines until it closes.
- `update` keeps refusing closed actions and terminal states, since `complete` remains the one door that stamps the date. Only the stated reason changes, because "a shape close can never produce" stops being true.
- Neovim's `set_state_tree` overwrites a `[_]` child with `[x]`, against Core Decision 2. It gets fixed in this work.
- Lines already detached in existing completed files stay detached, because their old parent is not recorded anywhere that can be read back.

## Questions

Recommendations are held until Darrion answers.

**A. What archives a line closed through the CLI?**
1. Nothing automatic: `clearhead archive actions`, run by hand or by a workflow.
2. An opt-in CLI setting that sweeps after a closing verb, the CLI's counterpart to `nvim_archive_on_save`. Close itself still never archives.

Either way, this repository's closed lines stay in `next.actions` until something sweeps them.

**B. What does `reopen` do to an archived action?** Children link to parents inside the tree, so either way the whole tree returns to the active file.
1. `reopen` brings the tree back and changes only the target's state.
2. `reopen` refuses, and a new `unarchive` verb brings the tree back first. [Decision 14](DECISIONS.md#decision-14-archiving-actions) promised unarchiving; no such command exists.

**C. What does "optional lint" mean for W002?** `linting.md` already says rules can be disabled, but I found no setting for it in the CLI's config code.
1. W002 stays a warning by default, reworded from "cannot be marked as closed" to report the contradiction.
2. W002 becomes off by default, which needs that setting built.
3. W002 stays on by default and the setting is built anyway.

**D. `complete --cascade` on a parent already closed, with open children.** That shape is now ordinary, and this is the natural way to reconcile it. Core Decision 2 says a closed target is rejected.
1. Keep rejecting: name each open child instead.
2. Close the open members, and reject only when none are open. This amends Core Decision 2.

**Left open by Darrion:** whether reopen becomes "more granular in another format".

## What changes

In order, per [Decision 54](DECISIONS.md#decision-54-implementations-rely-only-on-published-pinned-releases):

1. **specifications, released first:** `workspace.md` Archival item 2 (closing no longer moves a line); W002's wording, and its third example, `[x] Parent` over `[_] child`, which has no open child and which the linter doesn't flag; the transaction schema, its examples and `explanations/data_workflows.md`.
2. **clearhead-core, one landing:** single close and reopen, the transaction fold and `reopen-action`, cascade expansion, the occurrence record and resolving, sidecars in `archive`, `orient`, the CLI help, man page and README. Close and reopen land together, because in-place close without in-place reopen leaves closed lines that nothing can reopen. An entry in Core's `docs/DECISIONS.md` records the result, including Question D.
3. **clearhead.nvim:** the `set_state_tree` fix and the docs, against the new release. Pins move the same session.
4. **The clearhead skill:** the close verbs, `--cascade`, and when to archive.

**Who is affected.** I searched `assistant/scripts`, `agent-sandbox` and `meta-analysis/workflows` and found no caller of these verbs and no reader of `.completed.actions`. `docs/overnight-runbook.md` tells workers to run `clearhead complete action <id>` when done; that command keeps working, but a parent's children now stay open. Size is unmeasured, so I give no estimate.

**Tests that must exist before landing:** closing a parent and its children singly then archiving gives the same tree as a cascade; reopening the parent then brings all of it back; an occurrence closed in place keeps its Plan link through archive; a successor's readiness with a closed predecessor in the active file; and the crash case in the table.
