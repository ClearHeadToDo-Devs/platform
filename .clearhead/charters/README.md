---
id: 019c4f48-6441-75dd-b285-33718b9be996
alias: build_clearhead
---
# Build the ClearHead Platform
My dream is to build the ClearHead platform out of composable, open, data-driven components with the following values:

- local-first: data is stored on the user's device and only shared with explicit permission
- FOSS: open from the start, we want to make something that stands the test of time by making something that anyone can use, modify, fork, and contribute to
- functional: we use functional programming principles to make our code more predictable, testable, and maintainable
- data-driven: we want to make it easy to build data-driven applications on top of Clear

We are working through the individual structures such that we are going to be able to make a full platform just by handling individual structures

## Charter Map & Prioritization (2026-07-03)

How to pick work: take the highest-priority open action whose `<` predecessors
are all closed. `someday/` charters are README-only bets — do not start them;
check their promotion triggers instead.

### Work streams, in priority order

1. **[[caldav-integration]]** (`!1`, in flight) — finish the three-step
   reconcile shell already underway. Everything else queues behind it because
   its step 1 moves plan.rs mirror-path logic into core.
2. **[[core-seam]]** (`!1`×2) — repair the CLI↔core seam: route writes through
   the durability primitive; fix the alias-vs-name resolution bug and unify on
   one resolver. The naive-write sweep is predecessor-gated on the caldav
   reconcile; the close_subtree move is gated on action-lifecycle's Action
   struct extension.
3. **[[trust]]** (`!1`×2) — round-trip property tests (pairs with the two `!1`
   formatter bugs in clearhead-cli's charter file — same bug class) and
   git-backed undo (snapshot hook gated on core-seam's save_file delegation).
4. **[[query-system]]** (`!2`) — dependency views: frontier, unblock-impact,
   critical path, graph-shaped response type.
5. **[[trust]]** (`!2`) — doctor fsck and the five standing decisions.
6. **platform-model** — the mutation-theory charter (selectors, change sets,
   undo matrix). Its `!1` markers predate this pass; treat it as *informed by*
   core-seam and trust rather than ahead of them — the audit action is most
   valuable run against the post-core-seam system. Its action-lifecycle child
   charter, however, sits on the critical path (close_subtree depends on it).

### Cross-charter dependency edges

- core-seam naive-write sweep `<` caldav reconcile shell (plan-path logic moves first)
- core-seam close_subtree `<` action-lifecycle Action struct extension (cancelled_at)
- trust snapshot hook `<` core-seam save_file delegation (needs the single choke point)
- trust undo (mechanism) ↔ platform-model undo matrix (semantics) — layered, not blocking

### Housekeeping notes

- Every `.actions` file in the workspace lints clean as of this pass (three
  had silent syntax errors hiding their contents from loads — the doctor
  action in [[trust]] exists so this never needs a manual sweep again).
- Submodule-local charters (clearhead-cli, clearhead-core, ontology) hold
  repo-specific bugs and work; platform-level charters hold cross-repo work.
