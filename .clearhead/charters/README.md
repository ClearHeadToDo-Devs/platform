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

## Charter Map & Prioritization (2026-07-03)

How to pick work: take the highest-priority open action whose `<` predecessors
are all closed. `someday/` charters are README-only bets — do not start them;
check their promotion triggers instead.

### Work streams, in priority order

1. **[[core-seam]]** (`!1`×2) — repair the CLI↔core seam: route writes through
   the durability primitive; fix the alias-vs-name resolution bug and unify on
   one resolver. The naive-write sweep is now unblocked by the closed caldav
   charter; the close_subtree move is gated on action-lifecycle's Action struct
   extension.
2. **[[trust]]** (`!1`×2) — round-trip fidelity (rescoped 2026-07-03 per
   Decision 33: not a full proptest generator but the artifact-agreement
   residue — reserved-char escaping; the multi-tag `!1` cli bug is now closed,
   the spacing one remains) and git-backed undo (snapshot hook gated on
   core-seam's save_file delegation).
3. **[[query-system]]** (`!2`) — dependency views: frontier, unblock-impact,
   critical path, graph-shaped response type.
4. **[[trust]]** (`!2`) — doctor fsck and the five standing decisions.
5. **platform-model** — the mutation-theory charter (selectors, change sets,
   undo matrix). ; treat it as *informed by* core-seam and trust rather than ahead of them — the audit action is most
   valuable run against the post-core-seam system. Its action-lifecycle child
   charter, however, sits on the critical path (close_subtree depends on it).

### Cross-charter dependency edges

- caldav-integration is closed; its mirror-path move unblocks the core-seam naive-write sweep
- core-seam close_subtree `<` action-lifecycle Action struct extension (cancelled_at)
- trust snapshot hook `<` core-seam save_file delegation (needs the single choke point)
- trust undo (mechanism) ↔ platform-model undo matrix (semantics) — layered, not blocking

### Housekeeping notes

- Every `.actions` file in the workspace lints clean as of this pass (three
  had silent syntax errors hiding their contents from loads — the doctor
  action in [[trust]] exists so this never needs a manual sweep again).
- Submodule-local charters (clearhead-cli, clearhead-core, ontology) hold
  repo-specific bugs and work; platform-level charters hold cross-repo work.
