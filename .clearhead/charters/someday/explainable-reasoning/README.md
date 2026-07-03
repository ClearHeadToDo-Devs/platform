---
alias: explainable-reasoning
state: New
description: A real RDFS/OWL-RL reasoner over the graph, gated on evidence of need, with derivation transparency as a hard requirement from day one
---

# Explainable Reasoning

The à-la-carte structure vision runs vocabulary → shapes → **reasoning**:
subsumption (a fitness app's `Run` is-a `Exercise` is-a `Activity`, so a
query for activities finds runs without the app knowing about the query),
transitive closure, consistency checking. Reasoners are also a natural
[[agent-surface]] tool — inference the agent can invoke instead of grepping.

## The evidence so far

The platform has already written a reasoner without calling it one:
`inject_context_hierarchy` materialising `contextBroader` closures is
hand-rolled RDFS transitivity. That is one closure. The gate for this charter
is the **third** hand-rolled closure — at that point a general reasoner
deletes more code than it adds, and the abstraction is proven by repetition
rather than anticipation.

## The hard requirement: no spooky triples

Derived triples are spooky action at a distance — a query returns something
no file contains, and the plaintext-truth story breaks in the layer meant to
crown it. Unless the system can say *why*, reasoning violates the platform's
own transparency value. So, non-negotiable from the first spike:

- every inferred triple can produce its derivation on demand —
  "`Run ⊑ Exercise ⊑ Activity`, asserted in ontology v4.3"
- inferred triples are distinguishable from asserted ones in query output
  (separate named graph for inferences is the obvious mechanism)
- materialisation is regenerable and disposable, like every other read-model
  in the architecture — files stay the only truth

## Promotion trigger

The third hand-rolled transitive closure or subsumption hack in core — or
[[graph-federation]] landing a second vocabulary whose class hierarchy the
killer query needs to traverse.

## First actions on promotion

1. inventory the hand-rolled inferences (context hierarchy is the first;
   name the others that triggered promotion)
2. pick the profile deliberately — RDFS or OWL-RL, nothing fancier — and
   record why in DECISIONS.md
3. spike materialisation into a dedicated inference graph with
   derivation-on-demand, replacing `inject_context_hierarchy` as the proof
4. add the "explain this triple" surface (CLI first, agent tool second)
