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

## Charter Map & Prioritization (2026-10-03)

Choose the highest-priority open action whose `<` predecessors are closed. Finish bounded active work before promoting another charter. `someday/` charters remain bets rather than backlog; promote one only when its recorded trigger is evidenced.

Refreshed 2026-10-03 by an agent at the end of a session with the human; the order follows what the human chose in it.

### Work streams, in priority order

1. **[[emit-the-ontology]]** (Active) — the application vocabulary is the graph; the specification's mapping is its CCO meaning (Decisions 45–51). The mapping and the time model are done. Next: `v5-projection`, then `migrate-iris`.
2. **[[deployment]]** (Active since 2026-10-03) — the specification publishes at `clearhead.dev` (Decision 49): `spec-site`, then the `v0.2.0` release with its `release` branch. Needs the human for the Cloudflare Pages setup.
3. **agent-sandbox** (Active) — extracted on 2026-10-03 into its own repository, `~/Products/agent-sandbox`, with its charter and actions as that workspace's root charter; platform uses it from PATH. Work on it there.
4. **[[agent-surface]]** (Active) — CLI-first orientation and capture, then a thin MCP wrapper, then a dogfood verdict.
5. **[[root-next-default]]** (Active) — resume the homelab calendar sync when the NUC is back, including moving the orphaned inbox calendar collection.
6. **[[support]]** — CLI friction surfaced by real use.
7. **[[pure-core-split]]** — parked on the WASM C-toolchain blocker (bundle the grammar per Decision 37).

Closed since the last map: app-to-cco. Decided since the last map: Decisions 48–51 (the due window, `clearhead.dev`, the ontology folding into the specification, intent as a range).

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
