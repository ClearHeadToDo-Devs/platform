---
id: 7f58c64d-b701-4f95-80cb-ccdfa12ef152
alias: platform-model
state: Active
---
# Platform-Level Semantic Mutations and Undo

This charter formalizes the platform-level mutation model needed to keep ClearHead coherent across the CLI, LSP, hotkeys, sync, and future interfaces.

At the platform level, the primary mutable semantic entities are **charters** and **actions**. Files such as `.actions`, charter markdown, `.completed.actions`, and `archive.ttl` are important, but they are projections and persistence surfaces rather than the semantic center of the system.

The core design direction under this charter is:

- selectors and filters resolve concrete platform objects before mutation
- mutations are expressed as semantic operations on stable identifiers
- observability is emitted from semantic meaning, not incidental file writes
- persistence is a projection step that records those semantic changes into workspace files and archives
- undo must operate on resolved targets and reversible semantic operations rather than by replaying textual queries

This work should give us a shared model for command design, editor integrations, dry runs, telemetry, and eventual undo/redo behavior.

the goal of this work is to make a _declarative system of mutation and process and automates the underlying plumbing at the filesystem level_
