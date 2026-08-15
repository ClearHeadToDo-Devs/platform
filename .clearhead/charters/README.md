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

## Charter Map & Prioritization (2026-08-15)

Choose the highest-priority open action whose `<` predecessors are closed. Finish bounded active work before promoting another charter. `someday/` charters remain bets rather than backlog; promote one only when its recorded trigger is evidenced.

### Work streams, in priority order

1. **[[data-workflows]]** — the active platform stream. Start with `index-json-contract`, then publish transaction schemas, restore transparent graphd forwarding, implement the bounded Core transaction, and prove the query → jq → transact loop. This is the stable data/mutation seam later agent surfaces should reuse.
2. **CalDAV recurring-action interoperability** — repair `RELATED-TO;RELTYPE=PARENT` hierarchy import ahead of broad calendar projection only when the live JTX/Thunderbird defect is affecting use. Re-charter the residual rather than extending the historical integration charter indefinitely.
3. **Objective integration** — first repair objective and charter metadata and define durable identity/resolution semantics; then implement load → charter linkage → graph projection → objective-actions view.
4. **[[deployment]]** — the specification authority gate is now satisfied, but release work should follow the data-workflow seam unless a standalone or edge consumer creates immediate pressure.

### Settled prerequisites

- The durability/core seam and bounded executable-assurance uplift are shipped.
- `[[spec-conformance-gate]]` established `specifications/` as the sole DSL schema and example authority. Grammar, Core, and CLI consume its inert corpus at their own test boundaries; the exact pinned composition runs those conformance checks.
- `[[agent-surface]]` remains parked until `[[data-workflows]]` gives it stable query and mutation contracts, even though its original write-path trigger has fired.

### Housekeeping notes

- Platform-level charters own cross-repository work; submodule-local charters own repository-specific maintenance.
- Keep charter states and action files executable: a designed charter without ordered actions does not belong in the active queue.
