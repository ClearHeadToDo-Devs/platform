---
id: 01a0daa5-5016-7523-9e84-a3bfb0c585d7
alias: agent-surface
state: Active
objectives: [query-interface, capture-workflow]
description: An agent-shaped surface over the shared workspace — CLI-first orientation and capture, wrapped as a thin MCP server so any agent client can plan and record work alongside the humans it works with
---

# Agent Surface

Promoted from `someday/` on 2026-09-14.

The ecosystem shifted while this platform was being built: the consumer of a personal data platform is no longer only the person — it is the person *and* their agents. Everything distinctive here (machine-parseable plaintext truth, stable UUIDs, semantic grounding, local-first) is what agent-mediated work needs and what SaaS task tools structurally cannot offer.

## Boundary: ClearHead is for US

- **agent-workspace is for agents** — dense, revision-bound beliefs, intent, and checkpoints about the code. An agent's private working memory.
- **ClearHead is for us** — the durable plan shared by the user, their agents, and any teammates.

Consequences for this surface:

- Everything written through it must be **human-legible**: `.actions` DSL and charter markdown. Agent-only metadata (revision fingerprints, confidence, freshness) stays in agent-workspace.
- **Crossing the boundary is a deliberate promotion.** A private agent belief becomes a charter log entry or an action once it matters to the team — e.g. the subtract-before-add data-loss finding during [[direct-delivery]]. The reverse link already exists: an agent-workspace intent points at a charter via `external_reference`.
- **Client-agnostic.** Teammates may run different agents, so nothing load-bearing depends on one harness's hooks.

## Topology: CLI-first, not inside the LSP

Settled. The old rationale for growing an MCP endpoint in the LSP ("one resident process holding the warm graph serves both") does not hold:

- stdio MCP clients spawn their own server process; they cannot attach to the editor's LSP, so sharing one process would require a resident daemon, which is out of scope.
- The LSP holds buffer state, not a warm graph — workspace diagnostics re-read the workspace per call, and it carries neither the `sparql` feature nor the mutation path.
- The CLI already owns the verbs, `transact`, and queries, and is a library (`clearhead-cli/src/lib.rs`).

So new capabilities land as **CLI commands first** (useful to a human at a terminal too), and `clearhead mcp` is a thin wrapper over the same library functions, built on the official Rust MCP SDK (`rmcp`) rather than a hand-rolled protocol. Agent access to live editor state is already covered by nvim-mcp.

## The shape

A handful of agent-shaped tools, not a mirror of the CLI's two dozen commands — every tool schema costs agent context in every session.

| tool | purpose |
| --- | --- |
| `orient` | active charters, unscheduled queue, blockers, recent completions |
| `show` | resolve one item fuzzily and return its full record |
| `query_named` | run a saved view; the view list is a resource |
| `capture` | append to a charter log or add an action, with provenance |
| `transact` | typed batch mutations through the existing transaction engine |

Resources: charters, named queries, the ontology. Freeform SPARQL is deferred until named views prove insufficient.

**Output discipline** (a lesson from using agent-workspace): every section is bounded with an explicit omission count, and repeated payloads are referenced by id rather than re-emitted.

## What would falsify this

The problem this targets is the [[support]] verdict: ClearHead goes silent exactly when work gets hard. An `orient` command fixes the *start* of a session, not the middle. Success means agents capture findings into ClearHead during hard work without being reminded. If capture still fades with the tools in hand, the gap is workflow rather than interface — which is what support's ambient-capture exploration is probing.

## Promotion record

Trigger: core write-path discipline lands, or a second AI client wants at the workspace. Met when [[direct-delivery]] closed on 2026-09-13 — the write path is now plain `EffectBatch` delivery with additive ordering enforced in core.

## Log

### 2026-09-17

Shipped `orient` (clearhead-core `c1431b6`; closes the first action). Then designed the remaining shape with the user before scaffolding it, rather than while scaffolding it:

- **Still five tools, no sixth.** `orient`/`show`/`query_named`/`capture`/`transact`. Named queries and the ontology stay resources, not tool calls — an agent shouldn't spend a round trip on discovery it could get by reading a resource.
- **Concurrency safety was reviewed, not invented.** The user's condition going in: don't reintroduce the WAL/journaling `direct-delivery` retired. Checked before proposing anything: `EffectBatch::preconditions` + `validate_preconditions` + `DeliveryError::Conflict`/`ResourceConflict` already exist and are already enforced for action mutations — this is exactly the mechanism `direct-delivery` *kept*, not something to rebuild. Two real, narrow gaps instead, both now tracked in `support`:
  - Charter markdown writes (`jot`/`close`/`update`) skip the precondition check entirely via direct `atomic_write` — the existing action to route them through `EffectBatch` (`01a05b5d`).
  - Action mutations already detect a stale-write race but flatten it to a string (`clearhead-workspace-fs/src/lib.rs:492`) before it ever reaches `VerbError` — new action `01a0b2c2` threads the real `ResourceConflict` through instead.
  - `capture`/`transact` (`01a0a25d-86cc`) now depends on both: multiple concurrent agents writing through MCP is exactly the scenario that turns a currently-theoretical race into a routine one.
- **`capture`'s provenance line gets a concrete shape**: an optional `promoted_from` citing an agent-workspace claim id, closing the loop the README already names (a claim's `external_reference` already points *at* a charter; nothing currently points back).
- **`transact` stays scoped to update/complete/cancel.** Not extended to add/delete for MCP's convenience — creation and destruction deserve their own friction.
- **Found, not yet resolved:** `commands::*` is `mod commands;` privately in `clearhead-cli`'s `main.rs`, not `pub` from `lib.rs`. "A thin wrapper over the same library functions" isn't true yet. The scaffold action (`01a0a25d-86be`) now carries this — decide the boundary before writing the wrapper, not mid-write.
- 2026-09-17T23:28 — Task 7/7 of docs/overnight-worker-clearhead-core.md (the stretch item) STOPPED by the same rule as task 6, and it is the same blocker its own superseded note flagged: the recorded decision says to expose the build()-side functions as a 'pub mod mcp_support in clearhead-cli's lib.rs', but mod commands is declared privately in the bin's main.rs and orient::build (the function called 'already pure data') calls the bin-private, feature-gated sparql module — so the lib cannot host even the narrow surface without relocating commands + sparql + dataset into the library crate. show also has no build side to split (it prints tables), so that split means designing the agent-facing JSON shape first. No code was written, so nothing is half-migrated; the full verification, three options with costs, and a recommendation are in the action description, which is marked blocked. Also recorded there: with tasks 1 and 2 landed tonight, the sibling 'Add capture and transact MCP tools' action now waits only on this scaffold.
- 2026-09-18T10:51 — 2026-09-18 crate decision: one binary, two crates (pure core plus one effectful runtime absorbing workspace-fs and cli). mcp-scaffold's NEEDS DECISION is superseded: mcp is a subcommand of the merged crate, gated by an mcp feature implying sparql; see the merge action in pure-core-split.
