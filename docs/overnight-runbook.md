---
type: Runbook
title: Agent runbook
description: The single procedure for sandboxed agent runs in the platform monorepo. A run's prompt carries only parameters, its kind and its target; every rule lives here, so the prompt and the procedure cannot contradict each other.
status: stable
generated: { by: agent/claude, at: 2026-09-24T04:00:00Z }
updated: { by: agent/claude, at: 2026-09-25T00:00:00Z }
sources:
  - id: first-run
    resource: history/overnight-worker-clearhead-core.md
    title: the 2026-09-18 task list whose ground rules seeded this runbook
  - id: second-run
    resource: history/overnight-worker-crate-merge-and-identity.md
    title: the 2026-09-18 successor that added branch isolation, the review gate and the morning brief
  - id: sandbox
    resource: ../.clearhead/charters/agent-sandbox.md
    title: the agent-sandbox charter, whose runs on 2026-09-25 reshaped this into one procedure per run kind
---

# Agent runbook

You are one headless session in a sandboxed run (`agent-run`, from [the agent sandbox](../agent-sandbox/README.md)). Your
prompt names the run's **kind** and its **target**; this file is the whole
procedure. Follow the rules for every run, then your kind's section. A prompt
that names no kind is a plain task: the rules for every run apply, and the
prompt is the whole task.

## Every run

- **One session, then it ends.** Nothing resumes you after you reply. Run every
  command, the gate included, in the foreground and wait for it; never leave
  work in the background or end on a promise.
- **Setup is done.** The clone, your working directory (`/job/<workspace>/work`), has every repo on this run's
  `agent/<id>` branch, and `refs/agent/base` marks where each repo started.
  `clearhead` on PATH is built from this branch; use it for every ClearHead
  command, never an installed copy.
- **Commit, never push.** There are no git credentials. The human fetches your
  branches.
- **No container builds.** podman is not available inside the sandbox.
- **If two instructions conflict, stop at once** and report the conflict in
  your closing message. Do not choose between them and do not work around them:
  a conflict is a harness bug, and finding it in seconds is the point.
- **Mutate ClearHead data through its CLI** (`update`, `complete`, `add`, `jot`),
  not by hand-editing `.actions` files or a charter's frontmatter. A charter's
  Markdown body below the frontmatter is prose: edit it directly when the task
  asks for it.
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
  A failure your change caused is part of the work: fix it and run the gate
  again. One retry for a failure that looks flaky (passes alone, fails under the
  full suite). Stop only when the failure is not yours to fix (the gate or the
  environment is broken, or the fix would leave the task's scope), and then
  keep your work: leave it in the working tree and say where you stopped,
  never discard it. Never `--no-verify`. Run `clearhead doctor` before and
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
  analysis and options, and the `human` context added (`--context` replaces
  the whole set, so repeat any contexts the action already has); commit it. Do this the moment you reach the decision
  point, before exploring further: a spend cap can end the session at any time,
  and an unrecorded finding is lost.
- **Stopped for another reason:** leave the action as it is, commit nothing
  half-done, and explain.

Never weaken or delete a test, bypass the gate, or mark an action complete to
make an outcome look finished.

The **action description** holds the full analysis: what was found, decided and
changed, with commits. Do not restate it elsewhere.

## Fix run

Target: the review session or review file named in the prompt. The prompt contains its verdict,
findings as JSON, and an optional note carrying the human's or orchestrator's
decisions and answers. No ClearHead action is required.

- Address each finding in the prompt or state exactly why you declined it.
  Stay inside those findings and the note; do not invent decisions the note
  does not make. If a decision is missing, decline that finding with the
  question and options needed to proceed.
- Follow the rules for every run above. The Work run's gate, dependency,
  design-concern, no-review and provenance rules also apply, including its
  Containerfile and closing-message requirements. Commit no half-done work.
- A fix does not reconcile a finding. The human does that after checking it;
  do not change the review record or mark findings reconciled.

End with a fenced `json` block, using each finding's exact `what` text and
accounting for every finding in the prompt (including nits when supplied):

```json
{
  "fixed": ["finding what"],
  "declined": [{"what": "finding what", "why": "reason or decision needed"}]
}
```

Use empty arrays when appropriate. Report note-only work and commits in the
closing prose. If the gate fails, do not claim uncommitted fixes as fixed.

## Review run

Target: a finished work run's branch. The change in each repo is
`refs/agent/base..agent/<id>`; list it with `git log` in your working directory and in each
submodule. The checkout is read-only: report, never fix. Use
`git --no-optional-locks` for every git command.

Answer two questions:

1. **Is it correct** against the action's decision and the repository's
   invariants? Look for missing behavior and for regressions.
2. **Is there a simpler design**, or an existing function, crate or tool that
   would remove code the change added? An approach finding counts like any other.

Tests are the mechanical floor, not the review. Report each finding with its
severity (blocking, should-fix, nit), file and line, what is wrong and why. End
with a fenced `json` block (the host stores it as the session's `review`):

```json
{
  "coverage": [{"check": "invariant or behavior checked", "how": "files, commands and evidence"}],
  "findings": [{"severity": "blocking", "file": "repo/path", "line": 1, "what": "problem", "why": "impact"}],
  "for_human": ["where human judgment is needed"],
  "verdict": "land after fixes"
}
```

Use empty arrays when appropriate. Severity is `blocking`, `should-fix` or
`nit`; verdict is `land`, `land after fixes` or `do not land`. Coverage is your
account of checks, including shell and diff reads. Approach findings may use
`null` for file and line. A fenced JSON report that cannot be parsed or does not
validate is stored as `{"unparsed": true}` so it remains visible.

A verdict informs landing, never gates it. `agent-land` prints unreconciled
blocking findings; the human decides. Send blocking findings to a fixer
session in the same workspace; a fix alone does not reconcile a finding.
The human may record `reconciled: true` on a finding in the session record.

## For the orchestrator

Whoever launches runs, the human or an interactive agent, owns what the
sessions do not. The runner's commands, review loop and landing are in [the
agent sandbox guide](../agent-sandbox/README.md); what follows is how this repo
uses it.

- **Setup.** Put `agent-sandbox/bin` on `PATH` and run from this checkout.
  `.sandbox/setup` builds `clearhead` from the branch and puts it first on
  `PATH`; `.sandbox/prompt.md` points every session here; `.sandbox/gate` runs
  `scripts/validate-pinned`; `.sandbox/work-prompt.md` is the driver's
  per-action prompt.
- **Limits.** Besides the runner's per-session limits, the driver stops at
  `AGENT_MAX_ACTIONS` (10) sessions or `AGENT_RUN_USD` ($15). The NUC fits
  about two sessions at once, and the shared build cache serializes compiles.
- **Start work with the driver, anything else with a prompt.**
  `scripts/clearhead-work [<action>]` works the queue or one action: one
  workspace, one session per action. `agent-run --prompt <file|text>`
  starts any other session, and `--in <workspace>` puts it in a workspace that
  already holds work. `agent-result <workspace>[/<n>] --wait` returns
  the record as JSON.
- **Review between work and landing.** A review is a read-only session in the
  worker's workspace, e.g. `agent-run --in <workspace> --harness pi
  --read-only --prompt "Run kind: review. Target: this workspace's branch."`
  Run it with a different vendor than the worker: two models from one provider share blind spots (on
  2026-09-22 a GPT worker and a GPT reviewer went through four or five rounds
  per task and never questioned the hand-written parsing). An orchestrator's
  review can instead be supplied to `agent-fix` with
  `--review <file> --reviewer <name>`: one JSON report in the same shape as a
  review session's report, used instead of the session's review. The reviewer
  name is required; a session number cannot be combined with `--review`.
  Each supplied report is retained in `reviews/` with its reviewer for
  calibration, harvest summaries and landing advisories. A blocking finding
  goes to `agent-fix <workspace>[/<n>] [--harness claude|pi]
  [--model id] [--note <file|text>] [--wait]`, or a `NEEDS DECISION`.
  With no session number, `agent-fix` uses the latest read-only session with
  a parsed review. It supplies blocking and should-fix findings (`--nits` also
  includes nits); use `--note` for decisions and answers to `for_human` points.
- **Land bottom-up**: `agent-harvest <workspace>`, then
  `agent-land <workspace>`, then push; pushing platform also pushes the
  submodules' `main` branches. `agent-land` merges into a
  candidate clone and runs `.sandbox/gate` on it in the sandbox image; no real
  branch moves unless the gate passes. A red gate leaves the candidate and
  `gate.log` in the workspace directory.
- **Record the human’s landing verdict:** `agent-verdict <workspace> [--agree] [--overrule <text>]... [--missed <text>]... [--note <text>]`; an orchestrator may record it on the human’s word.
- **Keep the queue decided.** Anything that needs the human's call comes back
  as `NEEDS DECISION` with the `human` context. Ask the human only through that
  queue, never by repeating a question in chat: `clearhead query named
  for-human` lists everything waiting on them, and empty means nothing is.
- **Respect the flow rule** in the agent-sandbox charter: review time is the
  limit, so at most two unreviewed runs, in parallel only across separate areas.
- **Harness changes are work too.** A change to this runbook, the prompt or the
  scripts gets a review run like any other.
