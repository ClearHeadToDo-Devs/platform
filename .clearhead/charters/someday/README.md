---
alias: someday
state: New
description: Parked bets — future-facing charters with real vision behind them but no near-term commitment; each names the trigger that would promote it
---

# Someday

This folder holds charters that are **bets, not commitments**. Each one came
out of a real design conversation and deserves to be remembered precisely —
but starting it now would compete with work that is tangible today. Parking
them here keeps the vision written down without letting it masquerade as a
backlog.

## Semantics

- A someday charter is a **README only** — deliberately no `next.actions`.
  Someday items are not next actions (the GTD distinction is the point), and
  keeping them action-less keeps `read` output and agenda queries honest.
  Each README ends with a "first actions on promotion" section; when a charter
  is promoted, that prose becomes its real `next.actions`.
- Each charter names its **promotion trigger** — the observable condition
  under which the bet should convert to active work. Triggers make the review
  cheap: scan the folder, check the triggers, promote or leave.
- Promotion = move the directory up to `.clearhead/charters/` and write the
  actions file. History stays in git.

## Current bets

- [[graph-federation]] — the load-bearing bet: cross-application queries
  through the shared graph, proven by an importer over real data before any
  second app exists.
- [[agent-surface]] — MCP server over the workspace; agents as the primary
  ad-hoc query interface.
- [[review-analytics]] — a review surface over the data the platform already
  accumulates and nothing reads.
- [[mobile-capture]] — inbound capture from the phone without abandoning
  local-first.
- [[explainable-reasoning]] — a real reasoner, gated on evidence, with
  derivation transparency as a hard requirement.
- [[semantic-token-augmentation]] — LSP semantic tokens that augment
  tree-sitter with computed meaning (overdue, dangling, blocked), projecting
  the linter's analysis into ambient colour instead of re-emitting syntax.
- [[application-ontology]] — a semantic layer for workspace-scoped operational
  facts and interface-facing projections, kept out of the core ontology until
  repetition proves the abstraction.
