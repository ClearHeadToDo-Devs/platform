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

The human's review time is the constraint, not the machine: every run produces work to review.

- **At most two unreviewed runs.** Starting more only grows the queue.
- **Parallel across separate areas, one at a time within one area.** Runs clone `main`, so runs over the same files conflict at landing, and a run built on unlanded work starts stale. One run per charter is a safe unit (`--charter`).
- **While a run works, the orchestrator works on something that doesn't overlap with it**, never `agents/` while a run has it mounted.
- The NUC fits about two runs at once (8 CPUs and 16 GB each; the shared build cache serializes compiles).

## Handoff, 2026-09-25

For the next agent picking this charter up. The queue holds the work; this is how to operate it.

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
