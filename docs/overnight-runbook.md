---
type: Runbook
title: Overnight runbook
description: The standing procedure for an unattended overnight agent in the platform monorepo. Work comes from the unscheduled queue; this file holds the rules every run follows, so dated task lists no longer carry their own copies.
status: stable
generated: { by: agent/claude, at: 2026-09-24T04:00:00Z }
sources:
  - id: first-run
    resource: overnight-worker-clearhead-core.md
    title: the 2026-09-18 task list whose ground rules seeded this runbook
  - id: second-run
    resource: overnight-worker-crate-merge-and-identity.md
    title: the 2026-09-18 successor that added branch isolation, the review gate and the morning brief
---

# Overnight runbook

Your job is disciplined execution of decided work, not design. The work is the
unscheduled queue (`clearhead query index unscheduled`), taken in order. Read each
action with `clearhead show action <id>` first: the action, not any list, is the
source of truth, and its description holds the calls already decided for it.

## Setup

The human normally prepares the worktree and launches you inside it. Verify with
`git branch --show-current` (must be `night/<date>`, never `main`) and `pwd`
(under `~/worktrees/platform/`), and do whichever step is missing.

1. From `platform`, run `scripts/worktree-new night/<date>`. Work only in that
   worktree.
2. Branch each submodule before changing it: `git -C <repo> switch -c
   night/<date>`. `worktree-new` branches only the superproject.
3. Run `./scripts/install-hooks.sh`; a fresh worktree's submodules have no
   pre-push hook until it runs.
4. Build the CLI from your branch and use `target/debug/clearhead` for every
   ClearHead command. The installed binary may predate your branch, and an old
   formatter can rewrite unrelated entries.
5. Run `doctor` and note its known warnings. Any *new* warning or violation
   after your change is a failure.

## Working rules

- **Keep going.** When a task is done and reviewed, take the next unblocked one.
  Stop only for a `NEEDS DECISION` or a gate that will not pass. The launcher runs
  you in a harness loop, but do not end a turn on a promise ("next I'll…"): do
  the thing, or say you are stopping and why.
- **Branches only.** Nothing goes to `main` in any repo. Push your night branches
  (never `--force`) once a task passes its gate and review, so the work survives.
- **One gate:** `sh scripts/gate.sh` in `clearhead-core`, before every commit you
  keep. Check the gate's own exit code; a pipe such as `| tail` hides a failure.
  One retry for a failure that looks flaky (passes alone, fails under the full
  suite); otherwise stop and report. Never `--no-verify`.
- **Mutate ClearHead through its CLI** (`update`, `complete`, `add`, `jot`), not
  by hand-editing `.actions` or charter files.
- **Prefer a vetted dependency over custom code.** Before writing a parser, a
  validator or a format handler, look for a crate that does it. That none is a
  dependency *yet* is not a reason to avoid one: adding a pure-Rust library is a
  normal step (for `clearhead-core`, confirm it with
  `scripts/wasm-dependency-gate.sh`). Name every new dependency in the morning
  brief. When a review finding would be fixed by one more special case in
  hand-written parsing, switch to the library instead.
- **Fix design concerns or escalate them; never explain them away.** A concern
  about the design (a second read of data you already loaded, a workaround,
  duplicated logic) is resolved by a fix or by a `NEEDS DECISION`, never by a
  comment explaining why the workaround is acceptable.
- **Stop on a judgment call** that the action does not already decide: make
  `NEEDS DECISION: <question>` the *first line* of the action's description,
  followed by the analysis and options, then move to the next task.
- **File out-of-bounds findings as actions** in the owning charter, with the
  evidence. A finding must not live only in chat or agent-local memory.
- **Navigate with the shared language server; batch and read narrowly.** Use the
  shared read-only Neovim (`scripts/agent-nvim/server`) and its compact views for
  outline, references and definitions, and `rg` only for text. Issue independent
  tool calls in one turn. Do not read whole files over about 200 lines.
- **Provenance:** end every commit message with `Agent: <model>/night-<date>`.

## Review gate

Review is its own run, never part of the work: after a work run and before it
lands, a fresh agent reviews the run's diff (`refs/agent/base..agent/<id>`) and
reports findings without fixing them; in the sandbox its checkout is read-only.
A worker does not review itself. A finding blocks landing: a follow-up work run
fixes it and is reviewed again, or it becomes a `NEEDS DECISION`.

- **Use a reviewer from a different vendor**, not only a different model. Two
  models from one provider share blind spots: on 2026-09-22 a GPT worker and a
  GPT reviewer went through four or five rounds per task and never questioned
  the hand-written parsing.
- **The reviewer answers two questions.** Is it correct against the action and
  the invariants? And is there a simpler design, or an existing tool or crate,
  that would remove this code? An approach finding blocks like any other.
- Tests are the mechanical floor, not the review.

## Reporting

Each artifact has one job; do not restate one analysis four times.

- The **action description** is the full analysis: what was found, decided and
  changed, with commits.
- The **charter log line** (`jot`) is one line naming the decision and commit.
- The **per-task checkpoint** in agent-workspace is `{task id, commit, status}`.

## The morning brief

Finish by appending one `jot` entry to the charter the night mostly served. Put
the gate, `doctor` and `git log --oneline main..HEAD` results for each branched
repo at the top, then, **per commit**: the hash, the task, the one file and line
range to read first, and a risk rating with its reason. List every new
dependency and every reviewer finding with its resolution. The human should be
able to review the night in ten minutes from this entry alone.

## Launch checklist (for the human)

- [ ] Start the run inside the harness's loop, so the run continues after a
      turn ends while decision-free work remains in the unscheduled queue.
- [ ] Configure the review subagent with a model from a different vendor than
      the worker.
- [ ] Make sure the queue's top items are decided: anything that needs a call
      from you will come back as `NEEDS DECISION`.
