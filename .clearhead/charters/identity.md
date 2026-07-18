---
id: 019f6e9c-2118-7ff1-8565-5ac7194accac
state: Closed
---
# Durable Concept Identity

Every concept in a workspace — the workspace itself, charters, plans, and
actions — needs a stable identity that survives renames, moves, and edits.
Right now that is true in patches and false in the gaps, and the gaps bite:
an un-`init`'d workspace has no `workspace_id`, so it never gets a graph node
and every query silently drops all rows.

This charter makes identity **one policy applied uniformly**, so that the graph
decoupling work (its sibling) can lean on references that don't break when a
file moves into the archive.

## The bet

Identity lives *with the concept*, not with its file path. You can rename a
charter, reorder actions, move a whole subtree into `archive/`, and every
reference still resolves — because references point at durable UUIDs, not at
titles or locations.

Two properties fall out of that, and they're the whole point:

- A broken reference is a **visible dangling UUID**, never a silent rebind to a
  phantom. (Title/path resolution fails silently into the wrong thing; UUIDs
  fail loudly into nothing — which `doctor` can then report.)
- Archival becomes a plain file move, because identity travels *in* the moved
  bytes (line + sidecar), not in the directory it used to sit in.

## One policy, four anchors

Every concept follows the same lifecycle:

> **mint-or-derive once → persist to the concept's anchor → read from
> persistence → `doctor` reconciles drift**

They differ *only* in where the persisted id lives:

| Concept   | Anchor                                    |
|-----------|-------------------------------------------|
| Workspace | `.clearhead/config.json` (`workspace_id`) |
| Charter   | frontmatter `id` (+ sidecar mirror, move-safe) |
| Plan      | the `.ics` UID                            |
| Action    | inline on the line (tool-managed) + optional charter-UUID link |

Writing this as *one* rule keeps the four from drifting into four subtly
different schemes.

## Tool-managed, not invisible

Humans never type a UUID. The CLI and LSP mint and maintain them; `lint`
already guards the half-typed shapes (`E006`, `W013`). "Invisible" here means
*unobtrusive and barrier-free* — not literally absent. For a mutable line,
literally-absent-but-stable is not achievable, so the id sits on the line,
quietly, maintained for you.

**Derivation is only a bootstrap when identity is missing — never a live
recompute.** Recomputing a UUID from mutable content (v5-from-title,
v5-from-path) *is* the silent-rebind bug: change the content, change the
identity, orphan everything that pointed at it. Derive once to fill a gap,
persist immediately, then treat the persisted value as truth.

### Actions carry their charter

An action gets an **optional** charter-UUID alongside its own id, so the
action↔charter link is durable independent of which file the action sits in.
This is a *denormalized* link — the file location also implies the charter — so
the rule is explicit: **embedded id authoritative when present, file location
the fallback when absent; `doctor` reconciles on conflict.**

## The workspace gap — retire the v5 fallback

The spec (`specifications/workspace.md:184`) says an un-`init`'d workspace
should fall back to a **UUIDv5 derived from the root path**. That fallback is
now *implemented* (`effective_id()`, `load.rs:60`) and it is the wrong kind of
stable: a path-derived id changes when the directory moves, and differs from the
v7 that `init` later writes — so `init` silently *re-identifies* a workspace
that was already answering queries. It's exactly the path-coupling this charter
removes, against the section's own invariant (`:176`, "must never be
regenerated").

The fix rests on one observation: **the workspace_id is an in-session
graph-node identity — nothing references it durably.** The graph is rebuilt in
memory on every read; no file and no external tool consumes the workspace URI
across sessions. So persistence is *polish, not correctness*, and the write/read
split the decoupling charter draws falls out gently:

- **Read side** (graphd / queries): when `workspace_id` is absent, mint an
  **ephemeral id per load** — distinct per workspace, never path-derived, never
  written back. Queries always resolve because the query graph and the
  `ws:Workspace` node both go through the same fallback. This replaces the v5
  branch outright.
- **Write side**: `init` is the *sole* minting site — the one deliberate act
  that makes identity durable, extended to cover the home/user workspace, which
  nothing stamps today. No mutating command stamps identity as a side effect.
- **`doctor`**: reports a missing `workspace_id` as an informational nudge to
  run `init`, not an error. Identity is *offered, not forced*.

Net: the v5-from-path fallback is needed by neither side. Delete it from the
spec.

## First slice

The read-side ephemeral fallback (swap out v5-from-path) is independently
shippable: it makes queries correct for any workspace, init'd or not, without a
single persisted write. Do it first, ahead of the rest of this charter and
ahead of the graph-decoupling crate split.

## Relationship to graph-decoupling

This charter is the foundation. Only the **archival** and
**reference-resolution** actions in `graph-decoupling` depend on it — and
specifically on its core deliverable ("every concept has a persisted id;
references are durable UUIDs"), not on the whole charter. The extraction /
CLI-exec / rendering work there proceeds in parallel. That cross-charter
dependency is itself the `<` reference we chose to *permit* rather than forbid —
dogfooded on day one.

## Out of scope

Not the graph daemon, not multiple graph backends. Identity only.

## Workspaces/user data
the next thing that we want to make sure to structure user/workspace config for easy reading and configuring

specifically data that is workspace scoped includes:
- workspace uuid
- workspace creation date
- additional workspaces

as compared to user config like:
- default_to_user_scope

which is ALSO different from stuff that CAN be set as a default but then allows the workspace OVERWRITE it:
- tag hierarchies

this is how we ENSURE that workspace-level stuff like identity is set automatically and reliably, while user config can still remain where it needs and the override can be different.


