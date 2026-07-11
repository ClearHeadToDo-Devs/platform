---
id: 019f4f3c-47e2-7162-80de-f4dcb0974960
---
# Cleaning Up Technical Debt 
We want to always keep a tidy code base because what starts as small divergence will cause issues in the long run

This will be a general guide on the open items and is a good dumping ground for what we need to do

## Act to Action Cleanup — resolved
Awhile ago we moved from using the Act noun to the Action since that matches the format name and has already been encoded into the ontology.

Leftover `Act` naming across specifications, `clearhead-core`, and `clearhead-cli` (types, functions, SPARQL variables, CLI aliases) has been renamed. The one wire-sensitive spot — the sidecar's `acts` JSON key — got a `#[serde(alias = "acts")]` for backward-compatible reads plus a one-off migration of every existing sidecar file, in this workspace and the user's real one. See `next.actions` for the itemized breakdown. The CRDT/Automerge mirror types (`SyncActPhase`, `SyncPlannedAct`) were deliberately left as-is, matching prior team precedent for that layer.

## Schema Enforcement & Linking
The json schemas in `specifications/schemas/` describe our wire formats, but the serde structs that actually define them live in the `clearhead-core` submodule — a different repo with no enforced link. So schema and code are free to drift, and today a schema is only ever loaded in a single test.

A schema should be a contract the code is held to and the data points back at, not prose that rots. We want drift caught by a build, data files that carry a `$schema` pointer, and a decided source of truth.
