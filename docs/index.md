---
okf_version: "0.2"
---

# Knowledge Base

Process and architecture knowledge for the ClearHead platform monorepo, shared between the team and any agent working in it. Task-level state (what's done, what's next) lives in ClearHead itself (`.clearhead/charters/`), not here — this bundle is for durable knowledge that outlives any one task.

## Development workflow

* [Platform Development](CONTRIBUTING.md) — the day-to-day loop across submodules and worktrees
* [Managing Git Submodules](SUBMODULES.md)
* [Git Worktree Workflow](WORKTREES.md)

## Architecture

* [ClearHead runtime workflows](workflows.md) — event order and information flow (LSP, CLI, calendar sync)
* [Architectural Decisions](DECISIONS.md) — the aggregate decision log

## Proposals

* [Consequence-Proportional Assurance](consequence-proportional-assurance.md) — concentrate executable assurance where failure can destroy trust without turning every change into permanent process work

## Runbooks

* [Agent sandbox guide](../scripts/agent-sandbox.md) — workspaces, agents, sessions, commands and the review/fix/landing loop
* [Sandbox runbook](overnight-runbook.md) — standing rules for sandboxed sessions and the work, review and fix run kinds

## History

* [Crate merge and charter identity](history/crate-merge-and-charter-identity.md) — the completed crate merge and charter identity plan (2026-09-18)
* [Overnight worker — crate merge and charter identity](history/overnight-worker-crate-merge-and-identity.md) — superseded branch-isolated task list (2026-09-18)
* [Overnight worker — clearhead-core task list](history/overnight-worker-clearhead-core.md) — superseded pre-decided task list (2026-09-18)
* [Query-surface spike](history/query-surface-spike/README.md) — evidence behind Decision 45, and the generator for the spec fixture's CCO graph (2026-10-02)
* [RDF publication migration baseline](history/rdf-publication-baseline.md) — archived, pre-migration evidence only
