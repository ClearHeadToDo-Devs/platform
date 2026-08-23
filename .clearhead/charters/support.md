---
id: 01a030a9-2c09-78a1-a9e1-7f2e99563193
alias: support
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
