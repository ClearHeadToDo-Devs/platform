---
id: 01a0dab2-c8dc-7eb1-bdf0-36d42e27a5f6
alias: agent-sandbox
state: Active
objectives: [trustworthy-evolution, strong-CI-CD]
description: Run headless agents on our own hardware in a disposable container whose only output is commits, with standard telemetry, so unattended work is safe, reviewable and measurable without a proprietary cloud
---

# Agent Sandbox

Started 2026-09-25. The NUC runs agents unattended; this charter keeps that disciplined.

## Principles

- **Git is the only channel.** A run clones the repo, the agent commits, `scripts/agent-harvest` fetches the commits back. No credentials enter the container except the model's own.
- **The host stays boring.** Tools live in the image; runs, caches and images are disposable.
- **Stopping is a good outcome.** A clear account of why an agent stopped beats a forced finish. Spend caps bound every session, and nothing rewards gaming the result.
- **Standards first.** The environment is the repo's root `Containerfile` (OCI). Telemetry uses OpenTelemetry semantic conventions; a custom attribute needs a reason.

## Dependency direction

ClearHead is aware of everyone; nobody is aware of ClearHead. Charters and actions have lifecycles, and the sandbox must outlive any one of them.

| Layer | Knows about | Owns |
| --- | --- | --- |
| sandbox | git, podman, harnesses | clone, container, harness adapters, manifest, telemetry |
| ClearHead driver | sandbox, ClearHead | queue loop, prompt, completed/blocked/unfinished |
| ClearHead data model | whatever it links to | an action points at the commits a run produced |

So the sandbox works on any repo with a root `Containerfile`, with or without a `.clearhead/`.

## Flow

The human's review time is the constraint, not the machine: every workspace produces work to review.

- **At most two unreviewed workspaces.** Starting more only grows the queue.
- **Parallel across separate areas, one at a time within one area.** A workspace clones `main`, so workspaces over the same files conflict at landing, and one built on unlanded work starts stale. Work that belongs together goes in one workspace, as sessions (`--in`).
- **While a session works, the orchestrator works on something that doesn't overlap with it.** Editing `agents/` is safe: a workspace uses its own snapshot.
- The NUC fits about two sessions at once (8 CPUs and 16 GB each; the shared build cache serializes compiles).

## Current status, 2026-09-30 (handoff)

**Where it stands.** The runner is harness-neutral and knows nothing about ClearHead. Workspaces, agents and sessions are separate (`scripts/lib/agent-runs.sh` states the model; the Log below has the decisions):

| To | Run |
| --- | --- |
| start any task | `ref=$(scripts/agent-run --prompt <file\|text>)`, prints `<workspace>/<n>` and returns |
| add a session to existing work | `scripts/agent-run --in <workspace> --prompt ... [--harness pi] [--model ...] [--read-only]` |
| review with another vendor | the line above with `--harness pi --read-only` and a review prompt |
| read a result (JSON) | `scripts/agent-result <workspace>[/<n>] --wait` |
| work ClearHead actions | `scripts/clearhead-work [<action>]` (one workspace, a session per action) |
| see everything | `scripts/agent-status [<workspace>]` |
| bring work back | `scripts/agent-harvest <workspace>`, review, `scripts/agent-land <workspace>`, `git push` |

The repo's own startup is `.sandbox/`: `setup` (sourced before each session), `prompt.md` (ahead of every prompt), `work-prompt.md` (the driver's template). Default models are in `agents/models.env`.

**What to work on next, in order:**

1. `sandbox-premerge-gate` (priority 1, decided, needs nothing from the human): `agent-land` still merges before the gate runs, so a red gate leaves `main` advanced locally. It is the safest thing for an unattended agent to pick up.
2. `sandbox-auto-reconcile` (priority 1): partly overtaken on 2026-09-30, see the note at the end of its description. Narrow it before working it.
3. `sandbox-extract` (priority 3, but the direction the human asked for next): its description lists the platform assumptions still in the runner, found by reading the code on 2026-09-30. **Blocked on two decisions that are the human's**, so ask before any code:
   - **Language.** The earlier plan was to port to Rust or Babashka when the runner moves out; it is about 900 lines of POSIX sh today and works. Port, or move as is?
   - **Where it lives and what it is called**: the repo's name, and whether platform uses it as a submodule or from PATH.

**Verified on the host, 2026-09-30:** a Claude worker, a `gpt-6-sol` read-only reviewer and a Claude fixer as three sessions in one workspace (the reviewer saw the worker's commit and was refused a write by the mount); a second writer and a reader refused while a writer ran; two simultaneous launches; `.sandbox/setup` putting the branch's `clearhead` on PATH; `clearhead-work` on one missing action; harvest. `scripts/agent-runs.test.sh` and `scripts/agent-quadlet.test.sh` pass.

**Not verified, so do not assume:**

- `clearhead-work` over a real queue of several actions. Only the single-action path ran.
- `agent-land` on a workspace made by the new scripts. The two landings on 2026-09-29 used the old runner; `agent-land` itself did not change.
- A pi *work* session (read-write) through `agents/session`. Only a read-only pi session ran.
- A stop (`agent-stop`), a timeout and an OOM under per-session units. The outcome mapping is unchanged and unit-tested, but the per-session wiring has only seen clean exits.

**Known gaps:**

- The two harness test files are not run by any gate; wire them into `scripts/validate-pinned`.
- `agent-new` reads `~/.pi/agent/settings.json` unconditionally, so a host without pi cannot create a workspace even for a Claude session.
- `sandbox-cross-vendor-review` stays open until a real work run has been reviewed by a read-only session from another vendor; the mechanism exists.
- pi is pinned at 0.85.1, whose newest model is `gpt-6-sol`. `gpt-6.1-sol` needs 0.99+ (same `openai-codex` provider id, breaking changes in between): bump it with a smoke session, as part of the runner's own image layer.
- Two writers at once in one workspace would need a worktree per session; nothing needs it yet.

**Gotchas:** `agent-land` needs `~/.local/bin` on PATH for `check-jsonschema`. Pushing platform also pushes submodule `main` branches. The RDF proof in `validate-pinned` runs the `clearhead` on PATH, not the pinned build (platform action 01a0f109), so reinstall the CLI after core changes. Headless `nvim`/`busted` hang on an inherited open stdin; append `< /dev/null`.

## Historical handoff, 2026-09-25

Retained as the record of the earlier queue; the current status and actions above supersede these instructions. It describes the runner before 2026-09-30, when one `scripts/agent-run [action]` was one run in one container and `agents/loop` worked the queue inside it.

- **Start with `land-run-171333`** (priority 1): a Codex review said "land after fixes" (two should-fixes, recorded on the action). Fix them with a follow-up work run, or land and file them, then push.
- **The loop:** `scripts/agent-run [action]` → `scripts/agent-status [id]` → `scripts/agent-harvest <id>` → a review by the *other* vendor → `scripts/agent-land <id>` → `git push`. Land one run before starting the next in the same area.
- **Only `agent-run` starts Claude.** pi/Codex runs were started by hand today; the pi adapter (`sandbox-cross-vendor-review`) holds the lessons. **Harvest before landing:** `agent-land` now refuses to delete an unharvested run.
- **Review runs** today used `pi -p --mode json --provider openai-codex --model gpt-5.6-sol` with the run directory mounted read-only. The sandbox's Codex login lives in the `agent-pi` volume.
- **Gotchas:**
  - `agent-land` needs `~/.local/bin` on PATH for `check-jsonschema`.
  - Sandbox Claude runs use the subscription's default model (Sonnet), since none is set.
  - Never edit `scripts/agent-run` or `agents/` while a run is using them.
  - Pushing platform also pushes submodule `main` branches.
  - `$6` per session is tight for a change that touches many files.
- **Next in the queue:** `sandbox-dated-snapshot`, then the driver split with work and review runs, then telemetry and benchmarks, then `sandbox-extract`, porting to Rust or Babashka when it moves out.

## Findings

- 2026-09-25: headless sessions end when the agent replies. Tools that wait for a later turn (`ScheduleWakeup`, background jobs) silently lose the work, so they are disallowed.
- 2026-09-25: "exit 0" is not an outcome. The driver judges the action's state, and every session's closing message reaches the human at harvest.
- 2026-09-25: a spent budget ended a session before it recorded its finding. The prompt now says to record a decision point before exploring further.

## Log

- 2026-09-30T01:27-07:00 — driver-split step 1 of 3 landed: agent-run --prompt <file|text> starts one generic session (agents/session) and returns the run id on stdout at once; agent-result <id> --wait finalizes and prints the manifest, which now carries sessions {label, ok, cost_usd, closing, stop_reason, transcript} and commits per repo. agents/loop keeps the ClearHead queue for now and adds action and outcome (the action's real state) to the session it started. Run ids are claimed with mkdir so parallel launches cannot collide. Verified on the host with four real runs: string prompt with a commit, file prompt, two simultaneous launches, and the loop path on a missing action. Next: move the queue loop to a host orchestrator that calls --prompt, then the repo setup hook.
- 2026-09-30T01:30-07:00 — driver-split step 2 of 3 landed (reordered: the hook had to precede the orchestrator, since per-action runs each need clearhead on PATH): agents/session sources the clone's .sandbox/setup and prepends .sandbox/prompt.md, both optional. Platform's setup builds clearhead from the branch (3s with the shared cache); its prose points every session at the runbook. Open question before step 3, the host orchestrator: one run per action means each clone starts from HEAD, so a queue no longer stacks its actions' commits on one branch the way the in-container loop does.
- 2026-09-30T01:50-07:00 — driver-split DONE, with a redesign decided with the human on 2026-09-30: workspaces, agents and sessions are separate things. A workspace (agent-new) is a clone on its own branch; an agent is a harness plus a model, chosen per session (--harness, --model, defaults in agents/models.env); a session (agent-run --prompt, --in <workspace>) is one agent on one prompt in one workspace, with its own Quadlet unit and its own record, sessions/<n>.json, which names the commits it made. One writer at a time per workspace, a writer excludes readers, read-only sessions may overlap. agent-result <workspace>[/<n>] --wait is the JSON contract. The ClearHead side is scripts/clearhead-work (host: one workspace, a session per action, outcomes in clearhead-work.json) plus .sandbox/ (setup, prompt.md, work-prompt.md); agents/loop is gone. Verified on the host: a Claude worker, a gpt-6-sol read-only reviewer and a Claude fixer in one workspace, the reviewer seeing the worker's commit and refused a write by the read-only mount; the writer guard; the driver; harvest. This also delivers the mechanism of sandbox-cross-vendor-review (a review is a read-only session with another harness); that action stays open until a real work run has been reviewed this way. Not done: concurrent writers in one workspace, which would need a worktree per session.
