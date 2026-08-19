---
id: 019c4f48-6441-75dd-b285-33718b9be996
alias: platform
---
# Build the ClearHead Platform

My dream is to build the ClearHead platform out of composable, open, data-driven components with the following values:

- local-first: data is stored on the user's device and only shared with explicit permission
- FOSS: open from the start, we want to make something that stands the test of time by making something that anyone can use, modify, fork, and contribute to
- functional: we use functional programming principles to make our code more predictable, testable, and maintainable
- data-driven: we want to make it easy to build data-driven applications on top of Clear

We are working through the individual structures such that we are going to be able to make a full platform just by handling individual structures

## Charter Map & Prioritization (2026-08-19)

Choose the highest-priority open action whose `<` predecessors are closed. Finish bounded active work before promoting another charter. `someday/` charters remain bets rather than backlog; promote one only when its recorded trigger is evidenced.

### Work streams, in priority order

1. **LSP runtime maintenance** — finish the bounded active repository charter: make the repository standalone, add independent release hygiene, handle workspace-folder lifecycle, and settle the telemetry-adapter decision.
2. **CalDAV recurring-action interoperability** — repair `RELATED-TO;RELTYPE=PARENT` hierarchy import ahead of broad calendar projection only when the live JTX/Thunderbird defect is affecting use. Re-charter the residual rather than extending the historical integration charter indefinitely.
3. **Objective integration** — first repair objective and charter metadata and define durable identity/resolution semantics; then implement load → charter linkage → graph projection → objective-actions view.
4. **[[deployment]]** — the specification authority and data-workflow gates are satisfied; promote release work when a standalone or edge consumer creates immediate pressure.

### Settled prerequisites

- The durability/core seam, durable verb boundary, bounded executable-assurance uplift, and validated query → transaction → query workflow are shipped. Their completed charters are archived as immutable UUID facts.
- `[[spec-conformance-gate]]` established `specifications/` as the sole DSL schema and example authority. Grammar, Core, and CLI consume its inert corpus at their own test boundaries; the exact pinned composition runs those conformance checks.
- `[[agent-surface]]` now has its stable query and mutation prerequisites, but remains a `someday/` bet until an actual agent workflow justifies promotion.

### Housekeeping notes

- Platform-level charters own cross-repository work; submodule-local charters own repository-specific maintenance.
- Keep charter states and action files executable: a designed charter without ordered actions does not belong in the active queue.
