---
alias: observability
---
# Observability and Debugging Tools

Right now debugging the clearhead system requires `RUST_LOG=debug` and reading source code — you can't inspect what the graph actually contains, why a SPARQL query returned nothing, or what the system resolved a charter name to.

The architecture already has everything needed to fix this: the RDF store is queryable, the domain model is structured, and the CLI is the right place to expose it. The goal is to make the system self-describing so that bugs like the "recursive charter returns empty" class can be diagnosed in seconds, not hours.

Longer term, this is also the foundation for unifying telemetry — if events are written as RDF triples into the store, `query sparql` becomes the single interface for debugging, analytics, and introspection.
