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

## Findings

- 2026-09-25: headless sessions end when the agent replies. Tools that wait for a later turn (`ScheduleWakeup`, background jobs) silently lose the work, so they are disallowed.
- 2026-09-25: "exit 0" is not an outcome. The driver judges the action's state, and every session's closing message reaches the human at harvest.
- 2026-09-25: a spent budget ended a session before it recorded its finding. The prompt now says to record a decision point before exploring further.
