---
id: 01a030a9-2c09-78a1-a9e1-7f2e99563193
alias: support
state: Active
---
# Support Ergonomics

How well does ClearHead *support real work* — not as a demo of itself, but as a
companion while you're heads-down building something. Seeded by a from-scratch
dogfooding session (2026-08-23, [[dogfooding-clearhead-quackboard-2026-08-23]]):
a local-first DuckDB-Wasm dashboard driven end-to-end through the CLI.

## Verdict

ClearHead is a strong **planning-and-memory** tool and a weak **execution
companion**. It shines at "decompose the work, tell me what's next" — the
`unscheduled` queue + `~` chains genuinely held the thread through the planned
phase. It went **silent exactly when the work got hard**: through a long
debugging stretch the real state lived in server logs and the operator's head,
never in ClearHead. The tool stayed used only through conscious discipline.

## The reframe: findings, not process

The instinct to "track the exploration" is a trap — that's capturing the
flailing, which is ephemeral and shouldn't be in a task manager. **ClearHead
should hold intentions and findings, never process.** Under that boundary, going
quiet during exploration is correct; the real gap is narrow: when you *surface*
with a finding, there's nowhere frictionless to drop it.

## Where findings live (two altitudes, one surface that works)

- **Charter markdown = the running notebook.** Prose, append-only in spirit, no
  state-gate. This is the workhorse; the `## Log` on a charter is the lab
  notebook. (Underused today — charters are created near-empty.)
- **Action description = the distilled per-action outcome.** BUT the no-reopen
  gap freezes it: you can't stamp a description on a completed action, so it only
  works if written *before* completing — nearly vestigial for retroactive use.
  The two altitudes aren't symmetric; the charter log carries the real weight.

## Capture vs clarify

Split them (GTD). **Capture** must be frictionless and structure **deferred** —
you can't decompose what you haven't discovered. Loop: capture a breadcrumb →
later *clarify* (promote the actionable ones to actions, leave the rest as charter
knowledge). Demonstrated live on the toy: its `dash.md` `## Log` + two promoted
follow-ups.

## The capture verb — NOT "log"

"Log" imports the firehose model (record everything, no judgment) — the exact
thing to avoid. The verb is *selective*: a distilled thing worth keeping. Prefer
**`jot`** or **`capture`**; avoid `note` (already the action `$…$` field) and
`log`. It appends a timestamped bullet to the current charter's `## Log`.

## Human vs agent — the fix differs, and today conflated them

- **Human at a terminal:** a CLI verb genuinely helps — not keystrokes, the
  **context switch**. `clearhead jot "…"` between two shell commands is the same
  medium; opening an editor on the `.md` is not. Build it.
- **Agent (today's actual operator):** a verb it can *forget to call* fails the
  same way an edit it can forget to make does. Evidence: the operator had a
  zero-friction Edit path to `dash.md` and still didn't capture in-flow — the
  whole `## Log` was reconstructed at the end from the chat transcript and server
  logs, not from anything ClearHead held. **Capture is the unsolved core.** For
  agents the only capture that survives contact with hard work is *ambient* —
  part of the agent's own loop, not a command on offer. That's the direction
  worth chasing: ClearHead as the agent's task substrate.

See also [[collaboration-centaur-config]], [[clearhead-philosophy]],
[[feedback_use_clearhead_cli_for_actions_files]].

## Log

- 2026-08-31T22:07 — charter subsystem: .md name-inference doesn't mirror charter_stem's next.actions special-case, so a derived next.md becomes a phantom colliding charter (jot guards against it; close/update share the latent bug)
- 2026-08-31T22:07 — charter writes (jot/close/update) bypass the locked+journaled workspace-fs seam and go straight through atomic_write; unlike .actions mutations
- 2026-09-13T22:24 — dogfood (direct-delivery charter, retiring journaling + the mutation typestate): confirms the verdict again. The charter markdown was the workhorse — its Done Gate is what forced the additive-ordering safety test instead of a hand-wave — while `next.actions` sat empty through the whole multi-hour job. Good planner, absent execution companion.
- 2026-09-13T22:24 — capture is STILL end-of-session reconstruction, not ambient: these log bullets were distilled from the transcript after the fact, the exact failure quackboard hit. For an agent, capture that isn't part of the agent's own loop doesn't happen — reinforces "ambient capture / ClearHead as the agent's task substrate" as the target.
- 2026-09-13T22:24 — the 2026-08-31 "charter writes bypass the locked+journaled seam" finding is now reframed: that seam is GONE (no journal/lock anywhere post-direct-delivery). Both `.actions` and charter writes go through `atomic_write` now; the remaining asymmetry is that charter writes skip core's `EffectBatch` precondition/validation path. Closed this charter by hand-editing `state:` frontmatter rather than trust the buggy charter-write verb — the charter half still lags the actions half.
- 2026-09-13T22:24 — agent-workspace (MCP kernel) read: useful at the seams (intent as a forcing function; the subtract-before-add data-loss finding recorded as a cited belief that outlives the session; per-phase checkpoints) but a ledger, not a co-pilot — it recorded decisions; the compile/diagnostic loop drove them. Known submodule-granularity gap seen live: the kernel is rooted at the superproject, so its checkpoint `git_revision` sat at the pre-work HEAD through the ENTIRE implementation while 100% of the change was one level down in the `clearhead-core` submodule. The spine watched the wrong repo.
