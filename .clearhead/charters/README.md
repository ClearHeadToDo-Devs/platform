---
id: 019c4f48-6441-75dd-b285-33718b9be996
alias: platform
state: Active
---
# Build the ClearHead Platform

My dream is to build the ClearHead platform out of composable, open, data-driven components with the following values:

- local-first: data is stored on the user's device and only shared with explicit permission
- FOSS: open from the start, we want to make something that stands the test of time by making something that anyone can use, modify, fork, and contribute to
- functional: we use functional programming principles to make our code more predictable, testable, and maintainable
- data-driven: we want to make it easy to build data-driven applications on top of Clear

We are working through the individual structures such that we are going to be able to make a full platform just by handling individual structures

## Charter Map & Prioritization (2026-09-14)

Choose the highest-priority open action whose `<` predecessors are closed. Finish bounded active work before promoting another charter. `someday/` charters remain bets rather than backlog; promote one only when its recorded trigger is evidenced.

### Work streams, in priority order

1. **[[unified-workspace-root]]** — one canonical root-charter layout for project and user workspaces; already specified and sequenced. A predecessor of agent-surface: `orient` projects whatever root shape this settles.
2. **[[agent-surface]]** — a CLI `orient` command first, then a thin MCP wrapper over the CLI library, then a dogfood verdict on mid-task capture.
3. **[[support]]** — CLI friction surfaced by real use: query output consistency, charter actions-file creation, ambiguous short ids, ambient capture.
4. **Objective integration** — first repair objective and charter metadata and define durable identity/resolution semantics; then implement load → charter linkage → graph projection → objective-actions view.
5. **[[pure-core-split]]** — parked on the WASM C-toolchain blocker (bundle the grammar per Decision 37); resume when that is scheduled.
6. **[[deployment]]** — the specification authority and data-workflow gates are satisfied; promote release work when a standalone or edge consumer creates immediate pressure.

### Settled prerequisites

- The durability/core seam, durable verb boundary, bounded executable-assurance uplift, and validated query → transaction → query workflow are shipped. Their completed charters are archived as immutable UUID facts.
- `[[direct-delivery]]` retired the journaling and typestate mutation protocol; mutations are plain `EffectBatch` delivery with additive ordering enforced in core.
- Calendar: VEVENT is the default Plan codec. VTODO bidirectional sync was deprioritized because it lacked the intended feel, so its `RELATED-TO;RELTYPE=PARENT` hierarchy-import gap (JTX children import as flat root actions) is **parked, not fixed** — the archived `[x]` on that action records the charter closing, not a working round-trip.
- LSP decoupling is closed and no live charter tracks further LSP runtime work; re-charter it if a concrete need appears.
- `[[spec-conformance-gate]]` established `specifications/` as the sole DSL schema and example authority. Grammar, Core, and CLI consume its inert corpus at their own test boundaries; the exact pinned composition runs those conformance checks.
- `[[agent-surface]]` was promoted on 2026-09-14 once `[[direct-delivery]]` settled the write path; its topology is settled as CLI-first with a thin MCP wrapper, not an LSP endpoint.

### Housekeeping notes

- Platform-level charters own cross-repository work; submodule-local charters own repository-specific maintenance.
- Keep charter states and action files executable: a designed charter without ordered actions does not belong in the active queue.
