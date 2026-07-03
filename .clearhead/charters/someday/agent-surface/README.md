---
alias: agent-surface
state: New
description: MCP server over the workspace — agents as the primary ad-hoc query interface, with the ontology as the grounding that makes generated SPARQL reliable
---

# Agent Surface

The ecosystem shifted while this platform was being built: the primary
consumer of a personal data platform is no longer only the person — it is the
person's agents. Everything distinctive here (machine-parseable plaintext
truth, stable UUIDs, semantic grounding, local-first) is exactly what
agent-mediated computing needs and what SaaS task tools structurally cannot
offer.

## The shape

An **MCP server** over the workspace, mostly a thin layer on clearhead-core:

- **resources**: charters, actions, the ontology itself, and the saved
  query-system views — the ontology is what grounds agent-written SPARQL so
  generated queries are reliable rather than hallucinated
- **tools**: `add`, `complete`, `update`, `query` (freeform SPARQL and named
  views), `expand` — the same verbs the CLI has, behind a protocol every AI
  client speaks
- **validation as the safety net**: SHACL/lint catches nonsense before it
  misleads; the strict-mutation parse gate already exists and applies

This resolves the SPARQL-intuitiveness problem's top layer: raw SPARQL is the
assembly language, saved views serve the recurring questions, and agents
handle the ad-hoc long tail — "grep but for meaning" typed at any client.

## Why it can wait (and why not long)

The CLI's composability charter already carries the philosophy; the LSP
already proves the long-running-server pattern. But the mutation path an MCP
tool would call is the same one [[core-seam]] found bypassing the durability
layer — agents writing through an unsafe seam multiplies the risk. Fix the
seam first.

Evidence this works predates the server: this platform's own charters are
already read and written by agents through the CLI — the dogfood is running.

## Promotion trigger

Promote when [[core-seam]]'s write-path discipline lands, or the moment a
second AI client (beyond this CLI-driving one) wants at the workspace —
whichever comes first.

## First actions on promotion

1. decide daemon topology: standalone MCP binary vs the LSP server growing an
   MCP endpoint (one resident process holding the warm graph serves both)
2. expose read-only resources first — charters, actions, ontology, view list
3. add the query tool (named views, then freeform SPARQL with SHACL guard)
4. add mutation tools last, routed through the same core write path as the CLI
