---
type: Runbook
title: Overnight worker — clearhead-core task list
description: A pre-decided, ordered task list for an unsupervised overnight agent working clearhead-core only. Every judgment call in it was made in advance on 2026-09-18; the worker's job is disciplined execution, not design.
status: draft
generated: { by: agent/claude, at: 2026-09-18T06:00:00Z }
sources:
  - id: agent-surface
    resource: ../.clearhead/charters/agent-surface/next.actions
    title: agent-surface charter actions (tasks 1, 2, 6 come from here)
  - id: support
    resource: ../.clearhead/charters/support.actions
    title: support charter actions (tasks 3, 4 come from here)
---

# Overnight worker — clearhead-core task list

You are continuing tonight's work in `/home/dab/Products/platform`, a multi-repo
ClearHead monorepo (git submodules). Everything in `platform` and
`specifications` is already done and pushed. Your scope tonight is
**mostly `clearhead-core` with the others like `clearhead.nvim` done only if you have time**, working through a pre-decided, ordered list — no
open design calls left in it on purpose. Do not expand scope beyond this list.

## Ground rules (non-negotiable)

- **Repo scope: `clearhead-core` primarily**, plus bumping `platform`'s submodule
- **Use the `clearhead` CLI for all action/charter mutations** — `clearhead
  update action`, `clearhead complete action`, etc. Never hand-edit
  `.actions`/`.md` files directly except where a task explicitly requires
  editing source/spec files.
- **Every action gets its resolution written into its own description before
  you complete it** — what you found, what you decided, what you changed,
  which commit. Specific, cites file paths and commit hashes, no vague
  "fixed it."
- **Full pre-push gate before every push, not just at push time**: run
  `sh scripts/gate.sh` from `clearhead-core`. It is the single definition of the
  gate (fmt, clippy, tests, the no-default-features checks, the oxigraph-leak
  check, the wasm dependency gate and the pure-core source gate); the git hook
  calls the same file. Never re-type the steps by hand.
- **One retry on a flaky-looking failure** (passes in isolation, fails under
  full-workspace parallelism) — otherwise **stop and report**, don't force a
  push through. Never bypass the hook (`--no-verify`).
- **After every `clearhead-core` push**: bump `platform`'s submodule pointer,
  commit, push. Per task, not batched at the end.
- **Independent review gates the submodule bump.** Before bumping
  `platform`'s submodule pointer, a *fresh agent* — a different model when one
  is available, otherwise a fresh context of this model — reviews
  `git diff main...HEAD` for the task against the plan's invariants and reports
  findings; it must not fix them. A same-model reviewer shares your blind
  spots, so it is a weaker signal and never a substitute for a different model.
  **A finding blocks the bump**: fix it, re-run the gate, and re-review, or
  write a `NEEDS DECISION` line if it is a design question. The invariant tests
  (no read verb writes, no write verb stamps an id, a change between read and
  write is a conflict for every charter verb) are the mechanical floor, not the
  review.
- **Update agent-workspace** as you go: `workspace_record_belief` after each
  task citing the changed files, `workspace_checkpoint` after each completed
  task. If the goal shifts mid-run, update the intent.
- **If a task turns out to need a real judgment call that isn't already
  pre-decided in its description** — stop working that task, write exactly
  what's undecided and why into its description, move to the next task.
  Don't guess. This has already happened once (the `plan_path` action below
  is deliberately excluded for exactly this reason) — recognize the pattern
  rather than pushing through it again.
- **Leave the report in the work itself**, not a chat message nobody will
  read: the charter's `## Log` section, the actions' own descriptions, and
  the final checkpoint should tell the whole story without needing anything
  re-explained.

## Explicitly out of bounds

- `01a0a42b-3be7-7691-bcbf-366e1fd87a77` ("Specify or forbid a plan_path
  shared by several workspaces") — **do not touch**. Nobody has confirmed
  whether any real config actually hits this collision, so forbid-vs-support
  isn't safe to decide yet.
- Any question about whether `docs/` (this knowledge bundle) or a charter's
  own `## Log` is the source of truth for a given piece of knowledge — that's
  open for the user, not something to resolve unilaterally if it comes up.

## The task list, in order

Read each action's full current description with `clearhead show action <id>`
before starting — this document is a snapshot, the action is the source of
truth.

1. **`01a05b5d-62be-73c0-8e70-154d78bd57a3`** — Route charter markdown writes
   through `EffectBatch` delivery. `jot`/`close`/`update` skip the
   precondition check every action mutation already gets. Bring them onto the
   same seam.
2. **`01a0b2c2-f791-733e-b323-6b16f3e7d24a`** — Surface `DeliveryError::Conflict`
   as a structured `VerbError::Conflict` (`clearhead-workspace-fs/src/lib.rs:492`
   currently flattens it to a string).
3. **`01a0a266-01cf-73e3-acf2-a669be313387`** — Let `add action` create a
   missing charter actions file instead of erroring.
4. **`01a0a447-8bcd-77b1-bda1-ef3201183590`** — Stop deriving charter ids from
   titles in `parse_charter`; report the gap for `doctor` instead.
5. **`01a0a42b-3bd4-71c1-b922-39b88e9c310b`** — Write vdir `displayname`
   metadata from a charter's alias (design already decided; implementation
   only).
6. **`01a0a266-01c4-75e3-a35c-ed455d2e2f5f`** — Generate the charter map from
   charter metadata instead of the hand-maintained table of contents.
7. **`01a0a25d-86be-7d20-bead-8c865af74d6f`** — Scaffold `clearhead mcp`
   (stretch, do last). Its description has the full design decision written
   in — read it in full before starting. Scope is `orient`/`show`/`query_named`
   as read-only tools plus the three resources only; `capture`/`transact`
   wait on tasks 1 and 2. If you run out of time partway through the three
   tools, stop with whichever are genuinely complete and tested against a
   real MCP client interaction — never mark this complete with an untested
   or partial tool.

## Optional, only if the list finishes with time to spare

1. Check each `someday/` charter's promotion trigger against current
   reality. If one has quietly become true, don't promote it yourself — note
   it in that charter's README and flag it for the user.

## When you're done (or when you stop)

Run `clearhead doctor` in `platform`. Confirm everything committed is
pushed. Draw a final checkpoint summarizing which tasks completed, which
stopped early and why, and what's next in priority order.
