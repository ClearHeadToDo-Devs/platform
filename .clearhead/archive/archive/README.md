---
id: 019f52cd-924a-782c-9e3a-572b24b35e26
alias: archive
parent: platform
state: Closed
---
# Archive Functionality

Within the structure we have a concept of archival which is different from the existing work of actually closing a piece of work.

in preparation for the graph rework, we are going to update the archive process to have the entire structure done using the DSL/markdown files of the domain model and NOT the archive we are used to

so we are going to need to actually update the archive process so that we are able to decouple the graph functionality and just save the existing work to filesystem as the core thing rather than the translation

## Why this comes first

`archive_charter.rs` is the **only** place in `clearhead-core` that still touches
Oxigraph outside the `graph/` module — it serializes the closed charter into
`archive.ttl`. So this charter is not downstream of the graph decoupling; it
**gates** it: core cannot shed Oxigraph until archival stops writing Turtle.
Dependency order is **identity → archive → graph-decoupling**.

## The shape

Identity travels *in the moved bytes* — the action's inline UUID plus the
sidecar — so references survive a move. The graph is rebuilt on read; archived
files sit in an `archive/` region that is excluded from the default read but
stays parseable when we need it.

## The decisions

**1. Recursive subtree archival.** Archiving a parent charter archives its whole
subtree as one unit. The open-actions precondition goes recursive too: refuse if
*any* descendant still has open actions — that is what "closing it right" means.
Both the check and the move are local to the subtree's files; no graph needed.

**2. Atomic move via the transaction subsystem.** The subtree's `.actions`,
`.completed.actions`, `.md`, and sidecar move all-or-none. The sidecar moves
*with* the files (rather than folding its `created_at` / `external_schedule_id`
into the lines), and atomicity is what makes that safe — there is no
half-archived state that orphans metadata.

**3. Archive is excluded from view but still resolvable.** The `archive/` region
is not in the default read set, but reference resolution can still look into it.
That lets an archived `<` target resolve to one of three states, and the message
a user needs differs in each:

- **satisfied** — target Completed (dependency met; arguably "unblocked")
- **abandoned** — target Cancelled (you depend on something that was dropped)
- **dangling** — resolves nowhere (a genuine broken reference)

This three-way signal is the whole reason archives stay readable plaintext
rather than opaque. It depends on identity's references-as-UUIDs: only a durable
UUID makes a break *visible* instead of silently rebinding to a phantom.

## Out of scope

The archived form is data, not a projection — no Turtle, no JSON-LD is written on
archive. Any RDF view of archived data is regenerated on read by the graph
binary, exactly like live data.
