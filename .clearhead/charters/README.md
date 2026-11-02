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

## Charter Map & Prioritization (2026-10-04)

Choose the highest-priority open action whose `<` predecessors are closed. Finish bounded active work before promoting another charter. `someday/` charters remain bets rather than backlog; promote one only when its recorded trigger is evidenced.

Refreshed 2026-10-03 by an agent at the end of a session with the human; the order follows what the human chose in it.

### Work streams, in priority order

1. **[[deployment]]** (Active since 2026-10-03) — the specification publishes at `clearhead.dev` (Decision 49). `spec-site` and `spec-release-0-2` are done (2026-10-05). clearhead 0.3.1 is released (2026-10-06): a prebuilt x86_64 Linux archive that `cargo binstall clearhead` downloads. Next, none blocking: `windows-ci`, `lint-minimal`, `keep-line-endings`, then the assembled changelogs and a platform release. Put first by the human on 2026-10-05: today `cargo binstall` builds a 10-month-old CLI.
2. **[[emit-the-ontology]]** (Active) — the application vocabulary is the graph; the specification's mapping is its CCO meaning (Decisions 45–53). Core projects the app graph, the CLI queries it, v4 is retired and the ontology lives in `specifications/ontology/`. Published at `clearhead.dev` as v0.2.0 (2026-10-05). Next: `objective-actions-view`; `window-lints` whenever convenient.
3. **agent-sandbox** (Active) — extracted on 2026-10-03 into [its own repository](https://github.com/ca-mantis-shrimp/agent-sandbox) (checked out at `~/Products/agent-sandbox`), with its charter and actions as that workspace's root charter; platform uses it from PATH. Work on it there.
4. **[[agent-surface]]** (Active) — CLI-first orientation and capture, then a thin MCP wrapper, then a dogfood verdict.
5. **[[root-next-default]]** (Active) — resume the homelab calendar sync when the NUC is back, including moving the orphaned inbox calendar collection.
6. **[[support]]** — CLI friction surfaced by real use.
7. **[[pure-core-split]]** — parked on the WASM C-toolchain blocker (bundle the grammar per Decision 37).

Closed since the last map (2026-10-04): spec-site and spec-release-0-2 (2026-10-05); v5-projection, v5-queries, retire-v4, fold-ontology; support: CLI health findings route to doctor, piped charter listing, stable charter order. Decided: Decisions 52 (a time is kept as written) and 53 (queries read the application graph).

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
- 2026-10-16T05:58+00:00 — =x-prop-survival 2026-10-16, Google Calendar (Android) via DAVx5 4.5.20 to Radicale 3.8.3: an in-place edit kept X-CLEARHEAD-TEMPLATE (DAVx5 preserves unknown properties); 'this and following' rename split the series: original got RRULE UNTIL and kept the property, the continuation is a new UID with no property and no RELATED-TO, so merge-base restore has nothing to restore from. Template binding must survive splits. 'All events' not tested
- 2026-10-16T05:58+00:00 — =unrecur-series-test 2026-10-16, same path: 'does not repeat' made DAVx5 DELETE the series and PUT a new single event with a new UID at the current occurrence (10-16), not the series start (09-21); identity and history are lost rather than DTSTART pulled back. A second client (OneCalendar) on the same account wrote first, so the DELETE got 412 and left a duplicate. khal untested
- 2026-10-16T06:03+00:00 — =template-binding-home DECIDED 2026-10-16 by Darrion: the binding lives in the event DESCRIPTION as a 'template: <name>' line, not an X-CLEARHEAD-TEMPLATE property. Reason: X-properties can't be seen or edited on mobile; evidence: a 'this and following' split drops X-props on the continuation (=x-prop-survival). An event is a recurring action, or with a template line it is stamped from that template (action files need root actions). Decision 55's directive guard stays. Pending: confirm Google copies DESCRIPTION across a split
- 2026-10-16T06:04+00:00 — =template-binding-home confirmed 2026-10-16: a 'this and following' split in Google Calendar via DAVx5 copied DESCRIPTION 'template: test' to the continuation (new UID) and kept it on the truncated original
- 2026-10-16T06:21+00:00 — =spec-habits DECIDED 2026-10-16 by Darrion: a Habit's calendar entry is its occurrence's window only (e.g. weekly review 8-12, the child list may sit in the description); children never get recurrence rules or their own calendar entries ('it has to be enough, because i dont know how to make recurring subtasks not horrible'). To break a block into calendar pieces, make separate root Habits; the charter is the thread between them. PROPOSED framing (facilitator, not yet checked against Decision 56): the Habit recurs the window, children inherit it via the existing effective-window rule (E008/W015), and each occurrence is an independent stamp of the template, so per-day planning never edits the template
- 2026-10-31T22:33+00:00 — Dispatch failure: run cancel-keeps-completed-20261031-223212 used my incorrect urn:clearhead:action: prefix rather than urn:uuid:. wf-brief failed but work still started with an empty brief. Stopped run and session 20261031-223227 immediately; filed workflow-brief-fail-closed for facilitator. Retrying with correct URN; this is unplanned repair against cancel-keeps-completed/unaided.
- 2026-10-31T22:48+00:00 — Run cancel-keeps-completed-20261031-2233: both fix rounds stopped without changes, because docs/overnight-runbook.md asked for finding what text and agent-fix's prompt asks for ids (changed 2026-10-25). Runbook fixed in c36bc09. wf-cycle still prints 'fixed round N' for a fix with no commits and reviews unchanged code again, spending two reviews here; that fix belongs to meta-analysis.
- 2026-11-01T19:09+00:00 — =complete-keeps-closed landed 2026-11-01 (run complete-keeps-closed-20261101-1841, platform 2da637a, Core 5e18864) after two fix rounds. The completed action's record stops at the first implementation because update refuses a closed action; later Core commits are 8bfa1fc, 598d747, ee9fcbf. Landing was first refused: platform pin commit 70aabbc was titled test:, which locked the clearhead-core path against the next pin move; session 20261101-184122/7 reworded it to 39712d8 with an identical tree, and the landing gate then passed. For agent-sandbox (message to the facilitator held, not delivered): run-kind contracts should say a pin commit is never test:, or the lock should ignore gitlinks.
- 2026-11-02T01:21+00:00 — =close-individually, Darrion on 2026-11-02, A (settled unless they say otherwise): 'archival is a bulk process usually done at the end of a charter, we CAN archive individual actions but the default is a state change.' B (still thinking aloud, not settled): 'for reopen... i think that again it defaults to just that actions and really im trying to think... i think we can only unarchive root actions and below? because otherwise we get into this sticky "do you want the parents too?" and then if so... do we make a it a new root? unarchive the parent tree?'
- 2026-11-02T01:27+00:00 — =close-individually, Darrion on 2026-11-02. B confirmed: 'the root unarchive is a move then we need to reopen as a separate thing with an optional flag.' C: 'i think the default stays, it should be rare that you unarchive a parent only to reopen the root and i think that should still be a warning by default.' D: 'the cascade implies we arent just looking at one so i think same rules apply, the selected action, and all open actions should be marked completed no?'
- 2026-11-02T01:31+00:00 — =close-individually, Darrion on 2026-11-02. Flags: 'i think one could aqrgue for both? reopen cascade is for reopening a task and its children, while unarchive --reopen would BOTH move and reopen the actions.' Archive on save: 'yes the archive on save stays on its how we keep the active charters tidy'. Single-action archive: 'yes i think having this archive granularity is important so that we are building from the ground up'.
- 2026-11-02T01:35+00:00 — =close-individually: sweep-back tested 2026-11-02 at Core 5e18864 through real archive_saved in headless nvim. A closed tree in the active file returns to the completed file on the next save, even for an edit elsewhere, with states, dates and links intact; reopening the root in the buffer before saving keeps it. Also settled: a successor is ready with its predecessor closed in the active file; open root over closed children draws W003, not W002; archive charter puts closed-in-place lines in archive/<id>.actions, not .completed.actions.
- 2026-11-02T01:39+00:00 — =close-individually, Darrion on 2026-11-02, unarchive flags: 'yea --reopen and --cascade need to be two separate flags, one cascades down to the whole tree, while the other reopens the single action. combined, they will open AND move the whole tree. composobility'.
- 2026-11-02T02:38+00:00 — =close-individually, Darrion on 2026-11-02, answering whether complete --cascade on a closed target changes it: 'no it becomes closed especially if its the target this is an intention we are trying to close the action and all children and you know what the cascade is easy it just forces it and everything below it closed, im tired of all this trying to be smart, if we say cascade the implication is "this and all children should be closed GO" the only piece that we skip is stuff that is already closed so it doesnt lose the closure date and cancelled is a different thing so if im closing it im CLOSING it do what i mean and stop trying to be smart'
- 2026-11-02T02:52+00:00 — =close-individually run cis1 pushed back at decide: the review said land, but the branch kept children: 0 in the result schema while the proposal's Close section says results drop children and gain open_children. A review checks the action brief, not the plan it cites, so a brief citing a plan must spell out the plan's schema consequences.
