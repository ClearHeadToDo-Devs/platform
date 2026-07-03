---
alias: review-analytics
state: New
description: A review surface over the data the platform already accumulates and nothing reads — completed actions, telemetry NDJSON — closing the motivational loop that keeps a task system alive
---

# Review & Analytics

The platform diligently accumulates its own history — completed actions with
timestamps, monthly telemetry NDJSON, sidecar created-dates — and **nothing
reads any of it**. For a platform whose builder is a data analyst and whose
stated values include transparency, the observability gap pointed at the user
themself is the odd one out.

## The shape

A `clearhead review` command (or a family of saved query-system views —
probably both, the command being sugar over the views):

- **weekly review**: what closed, what stalled, what's been in-progress
  longest — the GTD weekly review as a first-class artifact
- **throughput**: completions over time, by charter and by context
- **context heatmaps**: where the hours actually go vs where charters say
  they should
- **charter momentum**: is a charter converging on its done-gate or
  accumulating scope

Renderings follow the query-system pattern: table for the terminal, and the
graph-shaped/mermaid response type once it exists. The telemetry NDJSON may
warrant its own named graph — which would make review queries the platform's
*second* cross-graph join, quietly rehearsing [[graph-federation]].

## Why it matters more than it looks

Task systems die when the loop doesn't close — capture without review breeds
distrust in the list, and distrust kills capture. A review surface is cheap
(the data exists, the query system exists) and is the retention feature for
the platform's first and most important user.

## Promotion trigger

Promote when the query-system dependency views land (the rendering seams will
be settled then), or the first time a weekly review gets skipped for lack of
tooling — whichever annoys first.

## First actions on promotion

1. decide telemetry's home: flat NDJSON read at query time vs its own named
   graph (rehearses the federation mount)
2. ship `review weekly` as a saved view + sugar command
3. add throughput and charter-momentum views
4. wire the review into the process spec so it has a cadence, not just a command
