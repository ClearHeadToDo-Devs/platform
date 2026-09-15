---
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
