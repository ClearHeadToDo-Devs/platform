---
type: Runbook
title: Overnight worker — crate merge and charter identity
description: An unattended, branch-isolated task list for the crate merge and the charter identity split, with a review step and a morning brief. Successor to the first overnight runbook. Drafted 2026-09-18.
status: draft
generated: { by: agent/claude, at: 2026-09-18T20:00:00Z }
sources:
  - id: plan
    resource: crate-merge-and-charter-identity.md
    title: the invariants I1-I12, ordered steps and stop conditions this runbook executes
  - id: previous
    resource: overnight-worker-clearhead-core.md
    title: the first overnight runbook; its ground rules still apply except where this one changes them
---

# Overnight worker — crate merge and charter identity

Your job is disciplined execution of [the plan](crate-merge-and-charter-identity.md),
not design. Its invariants **I1–I12 are your acceptance criteria**; its
"Stop conditions" apply. Read the plan first, then the ground rules of the
[previous runbook](overnight-worker-clearhead-core.md); everything there still
holds except as changed below.

## What changed since the first run

The first run finished 5 of 7 tasks in 34 minutes, then idled for lack of decided
work, and shipped one real gap that every gate passed. So:

1. **Keep going.** When a task is done and reviewed, take the next unblocked one in
   order. Stop only for a `NEEDS DECISION` line or a gate that will not pass.
2. **Isolate on branches.** Nothing goes to `main`, in any repo.
3. **Review every task** with a fresh agent — a different model when one is
   available — before bumping the submodule pointer. A finding blocks the bump.
4. **Leave a morning brief** so the human can evaluate the work without redoing it.

## Setup (do this before any task)

The human normally performs steps 1 to 3 and launches you inside the result. Verify
with `git branch --show-current` (must be `night/<date>`, not `main`) and
`pwd` (under `~/worktrees/platform/`), and do whichever step is missing.

1. From `platform`, run `scripts/worktree-new night/<date>`. Work only in the
   worktree it creates under `~/worktrees/platform/`.
2. In that worktree, branch the submodule you will change:
   `git -C clearhead-core switch -c night/<date>`. `worktree-new` branches only
   the superproject.
3. Run `./scripts/install-hooks.sh`. `core.hooksPath` is per-clone, and a fresh
   worktree's submodules do not have the pre-push hook until it runs.
4. **Confirm the gate scripts are present**: `clearhead-core/scripts/gate.sh` and
   `scripts/pure-core-source-gate.sh` must exist. If not, stop: the human has not
   yet merged the `gate-scripts` branch.
5. **Check the installed `clearhead` is current** (rebuilt 2026-09-18): `clearhead
   doctor` must report the 8 warnings below. If it says the workspace is clean,
   the install is stale and lying; rebuild it. To verify your *own* changes to the
   CLI, use the debug build of your branch (`cargo build -p clearhead_cli`,
   `target/debug/clearhead`), not the installed one.
6. **Expect 8 `charter-document-without-id` warnings** from `doctor`
   (`agent-surface` and seven `someday/` charters). They are known and are not a
   failure. Any *other* warning or a violation is.

## Rules that differ from the first run

- **Push policy.** Commit to the night branches. After a task passes the gate and
  its review you may push the night branch (never `main`, never `--force`) so the
  work survives. Do not merge, and do not bump any `main` pointer.
- **One gate command:** `sh scripts/gate.sh` from `clearhead-core`. Never re-type
  the steps. It must pass before every commit that you keep.
- **Do not touch `specifications`, `clearhead.nvim` or the grammar.** The spec is
  deliberately unchanged (plan step 0); document behavior in the CLI docs.
- **Review step — it gates the submodule bump.** Before bumping `platform`'s
  submodule pointer, a *fresh agent* reviews `git diff main...HEAD` for the task
  against the plan's invariants I1–I12 and reports findings; it must not fix
  them. Prefer a **different model**; a same-model reviewer shares your blind
  spots, so a fresh same-model context is a cheaper fallback, never a
  substitute. **A finding blocks the bump**: fix it, re-run the gate, and
  re-review, or write `NEEDS DECISION` if it is a design question. Only a clean
  review is followed by the submodule bump. The invariant tests (I4–I6, I12) are
  the mechanical floor, not the review.
- **Provenance.** Nothing in git records who wrote a commit (last night's are
  authored as the human). End every commit message with a trailer line
  `Agent: <model>/night-<date>` so the run can be found with
  `git log --grep '^Agent:'`. The branch and worktree already scope the rest.
- **Batch and read narrowly.** Issue independent tool calls in one turn. Do not
  read whole files over about 200 lines: use `rg -n` and ranged reads. (The
  language-server helper is not built yet, so there is no other way.)
- **Checkpoint per task** in agent-workspace, with a cited belief, not once at
  the end.
- **Stop on a `NEEDS DECISION`**: write the question as the *first line* of the
  action's description, then move to the next unblocked task.

## Pre-decided calls (all confirmed by the human, 2026-09-18)

- The merged crate keeps the name `clearhead_cli` and the binary `clearhead`.
- Module layout inside it (confirmed by the human 2026-09-18): three frontends,
  `cli`, `lsp` and `mcp`, and a shared `query` module (the sparql engine and
  dataset). `mcp` is created in the later mcp-scaffold task, not tonight. The
  former `clearhead-workspace-fs` becomes `filesystem` (the native filesystem
  adapter, a runtime module beside `query`; the human's name, chosen over
  `delivery`, and not `durability`, which is already a submodule inside it).
  Frontends depend on `query` and `filesystem`, never on each other (I8).
- `clearhead-lsp` stays a second `[[bin]]` target of the merged crate.
- I1 is a **ratchet, not a goal for tonight**: remove only the two charter sites
  from `scripts/pure-core-allowlist.txt`. The other seven have their own action.

## Task list, in order

Read each action with `clearhead show action <id>` first; the action, not this
list, is the source of truth.

1. **`01a0b5b0-17b8-77e8-82e9-971c194e64f9`** identity types: `parse_charter`
   returns an optional-id document; the shell supplies the domain id (I2, I3).
   Remove `workspace/charter.rs` and `workspace/store/load.rs` from the
   allowlist in the same commit.
2. **`01a0b5a4-ec3f-76ad-a63a-ca655a83364c`** the crate merge, as the plan's three
   commits (2a, 2b, 2c). It is large: review between the three commits. If a
   commit cannot pass the gate after two honest attempts, stop the task with a
   `NEEDS DECISION` line and skip to tasks 4, 5 and 6, which depend only on task
   1. Leave task 3 until the merge lands, to avoid editing code that is about
   to move.
3. **`01a0b5b0-17c4-73d7-8fa1-e9e4aebda796`** update, close and jot edit document
   text with the revision from the same read (I5, I6). Add the tests the plan
   names, including a change landing *between* the read and the write.
4. **`01a0b5b0-17d2-717c-938d-74ae3d848ce1`** `normalize` stamps ids; lint text;
   CLI docs in the same commit.
5. **`01a0b5fa-6ab7-7100-a71d-4e1388c2b30f`** archive refuses an id-less charter (I12).
6. **`01a0b5b0-17eb-7573-9921-dd40c4212d25`** the review nits.

Out of bounds tonight: `mcp-scaffold` and the LSP fold-in (they follow the merge
and want a human), the spec, and any `plan_path` question.

## The morning brief

Finish by appending to the `pure-core-split` charter `## Log`, with
`clearhead jot`, one entry containing, **per commit**: the hash, the task, the
invariants it touches, the **one file and line range to read first**, and a risk
rating (low, medium, high) with a reason. Add the reviewer's findings and how each
was resolved. Then run `sh scripts/gate.sh`, `doctor` (with the fresh binary), and
`git log --oneline main..HEAD` in each branched repo, and put the results at the
top of the entry. The human should be able to review the night in ten minutes from
this entry alone.

## Launch checklist (for the human, before starting the run)

- [x] Merge or push the `gate-scripts` branch in `clearhead-core` (the worker cannot
      use `gate.sh` otherwise). The commit is `bbfd87e`.
- [x] After merging `gate-scripts`, close the purity-gate action `01a0b5d0-da21-72bf-b418-0d2645335267`
      (and the older "run the gate script" action in `support`). Task 1 lists it as a
      predecessor, so while it is open the queue hides task 1.
- [x] `clearhead-lsp` stays a second binary for now (confirmed).
- [x] The crate name stays `clearhead_cli` (confirmed).
- [x] Push policy: the worker may push its own night branch, never `main` (confirmed).
- [ ] Optionally stamp the 8 id-less charters first with `normalize`, once child 3
      of the identity action has landed. Until then the warnings are expected.
