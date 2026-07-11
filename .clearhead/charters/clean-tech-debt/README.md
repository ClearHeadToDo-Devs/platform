---
id: 019f4f3c-47e2-7162-80de-f4dcb0974960
---
# Cleaning Up Technical Debt 
We want to always keep a tidy code base because what starts as small divergence will cause issues in the long run

This will be a general guide on the open items and is a good dumping ground for what we need to do

## Act to Action Cleanup
Awhile ago we moved from using the Act noun to the Action since that matches the format name and has already been encoded into the ontology.

Still, some of the leftover code still references acts which i can already see messing with the llms so we should do a check to clean that up

## Schema Enforcement & Linking
The json schemas in `specifications/schemas/` describe our wire formats, but the serde structs that actually define them live in the `clearhead-core` submodule — a different repo with no enforced link. So schema and code are free to drift, and today a schema is only ever loaded in a single test.

A schema should be a contract the code is held to and the data points back at, not prose that rots. We want drift caught by a build, data files that carry a `$schema` pointer, and a decided source of truth.
