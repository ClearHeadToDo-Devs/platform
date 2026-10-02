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

## Charter Map & Prioritization (2026-10-02)

Choose the highest-priority open action whose `<` predecessors are closed. Finish bounded active work before promoting another charter. `someday/` charters remain bets rather than backlog; promote one only when its recorded trigger is evidenced.

Refreshed 2026-10-02 by an agent from what the human worked on in the 2026-10-01/02 sessions; the human has not yet confirmed this order.

### Work streams, in priority order

1. **[[emit-the-ontology]]** (Active) — the application vocabulary becomes the graph people query and export, the ontology its mapping to CCO (Decisions 43–45). Next: `scheduled-vs-due`, then `app-vocabulary`, whose name waits on the human.
2. **[[agent-sandbox]]** (Active) — sandboxed agent sessions; next `sandbox-auto-reconcile`, then extraction to its own repository.
3. **[[agent-surface]]** (Active) — CLI-first orientation and capture, then a thin MCP wrapper, then a dogfood verdict.
4. **[[root-next-default]]** (Active) — one open action: resume the homelab calendar sync.
5. **[[support]]** — CLI friction surfaced by real use.
6. **[[pure-core-split]]** — parked on the WASM C-toolchain blocker (bundle the grammar per Decision 37).
7. **[[deployment]]** — promote release work when a standalone or edge consumer creates immediate pressure.

Closed since the last map: unified-workspace-root, ground-the-ontology. Objective integration was absorbed by emit-the-ontology (implement-objectives cancelled).

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

## Log

- 2026-09-17T23:24 — Task 6/7 of docs/overnight-worker-clearhead-core.md STOPPED by its own rule: 'generate the charter map from charter metadata' has no metadata to read. CharterFrontmatter has no description field (the model's description is parsed from the document body), so the frontmatter 'description:' lines that agent-surface and six someday/ bets carry are invisible to the tool — and any CLI charter write silently drops them (reproduced in a scratch workspace with update charter). Fixing that is a charter-data-model decision, so the action is marked blocked with the full analysis and the undecided calls recorded in its own description; no code was written and neither README was touched.
