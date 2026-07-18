---
id: 019f4f3c-47e2-7162-80de-f4dcb0974960
alias: clean-tech-debt
parent: platform
state: Closed
---
# Cleaning Up Technical Debt

We want to always keep a tidy code base because what starts as small divergence will cause issues in the long run

This will be a general guide on the open items and is a good dumping ground for what we need to do

## Act to Action Cleanup — resolved
Awhile ago we moved from using the Act noun to the Action since that matches the format name and has already been encoded into the ontology.

Leftover `Act` naming across specifications, `clearhead-core`, and `clearhead-cli` (types, functions, SPARQL variables, CLI aliases) has been renamed. The one wire-sensitive spot — the sidecar's `acts` JSON key — got a `#[serde(alias = "acts")]` for backward-compatible reads plus a one-off migration of every existing sidecar file, in this workspace and the user's real one. See `next.actions` for the itemized breakdown. The CRDT/Automerge mirror types (`SyncActPhase`, `SyncPlannedAct`) were deliberately left as-is, matching prior team precedent for that layer.

## Schema Enforcement & Linking - resolved
The json schemas in `specifications/schemas/` describe our wire formats, but the serde structs that actually define them live in the `clearhead-core` submodule — a different repo with no enforced link. So schema and code are free to drift, and today a schema is only ever loaded in a single test.

A schema should be a contract the code is held to and the data points back at, not prose that rots. We want drift caught by a build, data files that carry a `$schema` pointer, and a decided source of truth.

The data-carries-a-`$schema`-pointer half is done: `write_sidecar` (clearhead-core) and `clearhead init` (clearhead-cli) now stamp every emitted sidecar and `config.json` with a `$schema` key pointing at the raw GitHub URL of the matching schema in `specifications/schemas/` (whose `$id` fields were updated to match, replacing dead `github.com` blob-URL placeholders). Every sidecar and `config.json` in this repo's own `.clearhead/` trees was backfilled the same way — round-tripped through the real `read_sidecar`/`write_sidecar` path rather than hand-edited, which also quietly fixed 10 sidecars still carrying the pre-rename `acts` key that the earlier migration missed (they'd been hand-authored, not written by the CLI, so they never passed through the code that would have normalized them).

Both follow-ups landed: platform integration CI validates representative serialized metadata against the schemas, and `DECISIONS.md` records hand-maintained schemas plus drift tests as the source-of-truth policy.

## Strict CLI Clippy — resolved

`cargo clippy --all-targets --no-deps -- -D warnings` is clean across the CLI library, binary, and integration tests. The cleanup covered the original production findings plus test-target findings exposed once `--all-targets` advanced past them. A CLI workflow now checks out the sibling core and tree-sitter repositories explicitly, runs the locked test suite, and enforces this exact Clippy command on pushes and pull requests.
