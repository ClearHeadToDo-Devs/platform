---
alias: application-ontology
state: New
description: A semantic layer above the domain ontology and below client widgets, for workspace-scoped operational facts and interface-facing projections without polluting the core ontology
---

# Application Ontology

The platform already has two different kinds of meaning:

- the **domain ontology** — what an Action, Charter, Plan, dependency, or due
  date *is*
- the **workspace vocabulary** — facts about a specific loaded workspace
  snapshot: source file, source line, workspace identity, and similar
  filesystem-layer facts

A third layer is starting to appear in design conversations but has not yet
been named cleanly: **application semantics**. These are not domain truths,
and they are not raw UI details either. They are the operational concepts that
sit between the graph and the clients: locator bundles, mutation results,
query-row contracts, workspace-scoped projections, and the seam between
semantic identity and consumable payloads.

This charter exists so that layer can be designed deliberately if it ever
becomes load-bearing, rather than letting implementation convenience leak
piecemeal into either the core ontology or the query shapes.

## The shape

An application ontology would describe stable, cross-client operational
concepts such as:

- **workspace-scoped locators** — the bundle a client needs to navigate to a
  thing in a local projection (`source_file`, `source_line`, maybe
  `charter_root`)
- **query result identities and shapes** — not widget names, but the semantic
  distinction between a list entry, a table row, a graph edge set, and a
  mutation target
- **mutation result semantics** — success, already-complete, conflict,
  convergence, not-found; branchable outcomes instead of prose
- **projection-layer provenance** — why a thing is addressable here, in this
  workspace, through this output seam

The hard boundary: this is **not** a UI ontology. It must not contain Neovim's
quickfix list, telescope pickers, virtual buffers, clap subcommands, or any
other client-local widget. It names the application-level objects those clients
consume, not the widgets themselves.

## Why this is not the core ontology

The domain ontology should remain about the work itself. An action's status,
priority, predecessor, or parent relation belong there because they would make
sense even if ClearHead had no filesystem or editor.

Application semantics fail that test. `source_line` and `charter_root` are not
about what an action *is*; they are about where an action is *projected* in a
specific local system. That makes them real facts, but facts of a different
kind. Forcing them into the core ontology would confuse ontology with
implementation.

## Why this can wait

Right now the seam is still healthy:

- domain meaning stays in the ontology
- workspace-specific facts live in the workspace vocabulary when needed
- query shapes hand shallow payloads to clients so they do not have to perform
  extra graph hops just to open a file or act on a row

That is enough. Naming an application ontology too early would risk freezing
convenience fields as timeless semantics before repeated use proves which ones
actually deserve promotion.

## Promotion trigger

Promote when the same application-level concept appears in **three places** and
there is no agreed home for it — for example:

- multiple query shapes need the same locator/projection bundle
- CLI, nvim, and agent surfaces all depend on the same mutation-result
  semantics
- the workspace vocabulary starts carrying interface-facing facts whose
  difference from shape-only fields is no longer obvious

The rule of thumb: the third repeated seam violation earns the abstraction.

## First actions on promotion

1. inventory the repeated application-level concepts already in use: locator
   bundles, query-shape identities, mutation results, workspace-scoped
   projection terms
2. define the boundary explicitly: what belongs in the domain ontology, what
   belongs in the workspace vocabulary, what remains query-contract only
3. choose one proving example — likely locator bundles or structured mutation
   results — and model it end-to-end across core, CLI, and nvim
4. write the promotion criteria back into the query and workspace specs so the
   layering stays explicit going forward
