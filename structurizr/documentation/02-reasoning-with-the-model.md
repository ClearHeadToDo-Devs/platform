# Reasoning with the architecture model

The model is a thinking surface, not a requirement to display every known fact
at once. Different questions need different views.

## 1. Zoom before adding detail

Use C4's levels as progressive disclosure:

- **System context:** Who depends on ClearHead, and which standards cross its
  boundary?
- **Containers:** Which independently running applications and durable stores
  participate?
- **Components:** Where does responsibility live inside one runtime?
- **Code:** Read the source when a component boundary is no longer the useful
  unit of reasoning.

A lower-level view should answer a question raised by the level above. It should
not merely enumerate modules.

## 2. Separate dependency from behavior

Structurizr answers a structural question: **who is aware of or depends on
whom?** Every arrow points from the knower to the known dependency. A protocol
server does not point back to a client merely because it sends a response, and
two applications are not coupled merely because they read the same standard
file representation.

Mermaid sequence diagrams answer the behavioral question: **what happens next?**
Use the separate workflow diagrams for requests, responses, branching, retries,
and data movement. When following a scenario, ask:

1. What initiates this behavior?
2. Which representation is authoritative at each step?
3. Where is a decision made?
4. Where is an effect delivered?
5. What happens if the final step fails?

This separation prevents runtime chatter from being mistaken for architectural
coupling.

## 3. Locate the seam

The most important ClearHead boundary is **Core decides; adapters deliver**.
Read the technical views by classifying each component:

- **Pure (green):** deterministic model, parsing, projection, or decision logic
- **I/O (orange):** filesystem discovery, observation, locking, journaling, or
  delivery
- **Boundary (purple hexagon):** host-neutral evidence and effects crossing
  between the two
- **Host (blue):** interaction policy and runtime lifecycle

An arrow that makes Core depend on native I/O is an architectural warning, even
if the software still compiles.

## 4. Track sources and projections

For every representation, ask whether it is:

- an **authority** — human-editable workspace facts;
- an **in-memory interpretation** — the `DomainModel`;
- a **projection** — VTODO or RDF that can be reconstructed;
- or **delivery metadata** — revisions, sidecars, sync state, and journals.

This prevents a cache or interoperability format from accidentally becoming a
second source of truth.

## 5. Pair diagrams with decisions

Diagrams describe the current answer; decision records explain why it was
chosen. When a boundary changes:

1. Record the decision and rejected alternatives in `DECISIONS.md`.
2. Update structural dependencies in Structurizr and event order in Mermaid,
   changing only the representation affected by the decision.
3. Add or change a fitness check that protects the decision where practical.

Examples of architectural fitness checks include:

- Core builds for `wasm32` and imports no native filesystem API.
- CLI and LSP depend on Core; Core never depends on either host.
- The LSP does not depend on the CLI.
- Minimal builds contain no Oxigraph dependency.
- Exported RDF remains queryable by an independent engine.
- Pinned submodules match the platform gitlinks and pass their own gates.

## 6. Keep uncertainty visible but out of the runtime model

The C4 model should describe implemented architecture. Use ClearHead actions,
charters, and decisions for proposals, unknowns, and planned seams. Promote an
idea into the model when code or an accepted architecture decision makes it
real.

## 7. Test whether a view earns its upkeep

A view is useful when it supports at least one recurring activity:

- onboarding;
- design review;
- incident or failure analysis;
- change-impact analysis;
- conformance review;
- or explaining a user-visible workflow.

If a view is only a list that no one uses, simplify or remove it. Accuracy and
question-answering value matter more than coverage.
