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

## History

* [RDF publication migration baseline](history/rdf-publication-baseline.md) — archived, pre-migration evidence only
