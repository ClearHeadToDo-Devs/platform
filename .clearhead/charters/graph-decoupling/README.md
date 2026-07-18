---
id: 019f6da6-c313-7531-92dc-0f69ca01c4e3
alias: graph-decoupling
parent: platform
state: Closed
---
# Decoupling the graph

The decision to move the graph functionality out of the existing stack did not come lightly. 

the reason why comes down to a few things:
- build speed: we dont want to build a whole damn database no matter what
- simplicity: while relatively small, the structure of the integration makes it feel large for the footprint and makes the interface 
- flexibility: i was just looking at things that run GQL and i want to support various graph implementations which is why we want to decouple this specific implementation
- philisophically: the graph, like all other integrations should operate on the workspace like any other integration so having this be read and queried by a separate thing will help us get this structure

## the how

we will ship a `clearhead-graphd` binary which will take the functionality which currently runs in the cli and runs it entirely with existing functionaltiy.

## the implication

this means that our cli/core structure will have all the graph data/logic removed and the core/cli usage is going to rely entirely on core functionality meaning:
- archive will be created using the DSL and normal files rather than pushing everything to the archive.ttl
- reference handling is going to be done entirely using the domain structure
- views/queries will be the purview of the graph binary not the cli 

## outcome

The extraction landed on 2026-07-17:

- `clearhead-core` is graph-neutral and has no Oxigraph dependency
- `clearhead-cli` speaks JSON to the out-of-process graph backend
- the independent `ClearHeadToDo-Devs/clearhead-graphd` repository—pinned here
  as a submodule—owns RDF insertion, SPARQL, Turtle, query shapes, JSON-LD,
  Oxigraph, graph resources, and graph tests

See [inventory.md](./inventory.md) for the final ownership map and transition
notes.
