---
type: Runbook
title: Agent runbook
description: The single procedure for sandboxed agent runs in the platform monorepo. A run's prompt carries only parameters, its kind and its target; every rule lives here, so the prompt and the procedure cannot contradict each other.
status: stable
generated: { by: agent/claude, at: 2026-09-24T04:00:00Z }
updated: { by: agent/claude, at: 2026-09-25T00:00:00Z }
sources:
  - id: first-run
    resource: overnight-worker-clearhead-core.md
    title: the 2026-09-18 task list whose ground rules seeded this runbook
  - id: second-run
    resource: overnight-worker-crate-merge-and-identity.md
    title: the 2026-09-18 successor that added branch isolation, the review gate and the morning brief
  - id: sandbox
    resource: ../.clearhead/charters/agent-sandbox.md
    title: the agent-sandbox charter, whose runs on 2026-09-25 reshaped this into one procedure per run kind
---

# Agent runbook

You are one headless session in a sandboxed run (`scripts/agent-run`). Your
prompt names the run's **kind** and its **target**; this file is the whole
procedure. Follow the rules for every run, then your kind's section.

## Every run

- **One session, then it ends.** Nothing resumes you after you reply. Run every
  command, the gate included, in the foreground and wait for it; never leave
  work in the background or end on a promise.
- **Setup is done.** The clone at `/job/work` has every repo on this run's
  `agent/<id>` branch, and `refs/agent/base` marks where each repo started.
  `clearhead` on PATH is built from this branch; use it for every ClearHead
  command, never an installed copy.
- **Commit, never push.** There are no git credentials. The human fetches your
  branches.
- **No container builds.** podman is not available inside the sandbox.
- **If two instructions conflict, stop at once** and report the conflict in
  your closing message. Do not choose between them and do not work around them:
  a conflict is a harness bug, and finding it in seconds is the point.
- **Mutate ClearHead through its CLI** (`update`, `complete`, `add`, `jot`), not
  by hand-editing `.actions` or charter files.
- **File out-of-bounds findings as actions** in the owning charter, with the
  evidence. A finding must not live only in your closing message.
- **Read narrowly.** Use `rg` for text and outline before reading; issue
  independent tool calls together; do not read whole files over about 200 lines.
- **Your closing message is the human's record of the session.** State the
  outcome, and if not done, exactly why and what you would need.

## Work run

Target: one ClearHead action. Read it first with `clearhead show action <id>`:
the action, not any list, is the source of truth, and its description holds the
calls already decided for it. Your job is disciplined execution of decided work,
not design.

- **One gate:** `sh scripts/gate.sh` in `clearhead-core` before every commit you
  keep. Check the gate's own exit code; a pipe such as `| tail` hides a failure.
  One retry for a failure that looks flaky (passes alone, fails under the full
  suite); otherwise stop. Never `--no-verify`. Run `clearhead doctor` before and
  after: any *new* warning or violation is a failure.
- **Prefer a vetted dependency over custom code.** Before writing a parser, a
  validator or a format handler, look for a crate that does it. That none is a
  dependency *yet* is not a reason to avoid one (for `clearhead-core`, confirm it
  with `scripts/wasm-dependency-gate.sh`). Name every new dependency in your
  closing message.
- **Fix design concerns or escalate them; never explain them away.** A second
  read of data already loaded, a workaround or duplicated logic is resolved by a
  fix or by a `NEEDS DECISION`, never by a comment saying why it is acceptable.
- **No review.** A worker never reviews itself; review is a separate run, by
  another vendor, before landing. Do not spawn a reviewer, and its absence is
  not a reason to stop.
- If you change a Containerfile, say that the image build is unverified.
- **Provenance:** end every commit message with `Agent: <model>/<run id>`.

### Stopping is a good outcome

A clear account of why you stopped is worth as much as a finished action, and
far more than a forced one. Stop when the work needs a decision the action does
not make, grows beyond its description, or will not go green after a reasonable
attempt. Every session ends in exactly one of:

- **Done:** gate green, work committed, `clearhead complete action <id>`.
- **Needs a decision:** `clearhead update action <id> --state blocked`, with
  `NEEDS DECISION: <question>` as the first line of its description, then the
  analysis and options; commit it. Do this the moment you reach the decision
  point, before exploring further: a spend cap can end the session at any time,
  and an unrecorded finding is lost.
- **Stopped for another reason:** leave the action as it is, commit nothing
  half-done, and explain.

Never weaken or delete a test, bypass the gate, or mark an action complete to
make an outcome look finished.

The **action description** holds the full analysis: what was found, decided and
changed, with commits. Do not restate it elsewhere.

## Review run

Target: a finished work run's branch. The change in each repo is
`refs/agent/base..agent/<id>`; list it with `git log` in `/job/work` and in each
submodule. The checkout is read-only: report, never fix. Use
`git --no-optional-locks` for every git command.

Answer two questions:

1. **Is it correct** against the action's decision and the repository's
   invariants? Look for missing behavior and for regressions.
2. **Is there a simpler design**, or an existing function, crate or tool that
   would remove code the change added? An approach finding counts like any other.

Tests are the mechanical floor, not the review. Report each finding with its
severity (blocking, should-fix, nit), file and line, what is wrong and why. End
with one verdict line: land, land after fixes, or do not land.

## For the orchestrator

Whoever launches runs, the human or an interactive agent, owns what the
sessions do not:

- **Review between work and landing.** Run a review with a different vendor
  than the worker: two models from one provider share blind spots (on
  2026-09-22 a GPT worker and a GPT reviewer went through four or five rounds
  per task and never questioned the hand-written parsing). A blocking finding
  goes to a follow-up work run or a `NEEDS DECISION`.
- **Land bottom-up** with `scripts/agent-land <id>`, then push.
- **Keep the queue decided.** Anything that needs your call comes back as
  `NEEDS DECISION`.
- **Respect the flow rule** in the agent-sandbox charter: review time is the
  limit, so at most two unreviewed runs, in parallel only across separate areas.
- **Harness changes are work too.** A change to this runbook, the prompt or the
  scripts gets a review run like any other.
