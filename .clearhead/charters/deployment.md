---
id: 01a00363-93cf-7903-9080-a9ef8eb0ba2e
alias: deployment
parent: platform
objectives:
  - strong-CI-CD
state: New
---
# Everything Ships a Release

Every repo in the platform should have a real *release* — versioned, published, consumable on its own — so each is independently deployable rather than only path-linked inside the workspace. This is the implementation side of the [[strong-CI-CD]] objective: edge devices (phone, laptop) download a working binary instead of building from source. Deferred on purpose: publishing is a stability commitment (semver, registry versions, tagged artifacts) that is premature while the seams are still moving. We take it up only once the project feels proper.

## The shape

- Each repo publishes: a semver'd, tagged release; libraries to their registry (crates.io for the Rust crates, the grammar included); binaries as prebuilt artifacts for the consumers that need them.
- A single repo can be cloned, built, and tested without its siblings on disk or the `platform` meta-repo — the workspace becomes a convenience for co-development, not a build requirement.
- Edge consumers install a released binary; they never compile the Rust toolchain on-device.

## Why it can wait (and why not long)

The concrete cost is already visible: `tree-sitter-actions` is an unpublished path dependency, so a bare clone of Core does not build standalone today — it needs the sibling grammar on disk. That is tolerable while Core and the grammar co-evolve rapidly. It stops being tolerable once their APIs settle: at that point "clone one repo and build" is a reasonable expectation we cannot meet, and edge distribution has no path at all.

## Promotion trigger

Promote when the moving seams stabilize — specifically once [[spec-conformance-gate]] establishes the spec as the single authority (so the grammar↔Core contract is fixed) and the core-seam churn subsides — or sooner if a real consumer needs to build or run a single repo without the workspace.

## First actions on promotion

1. Publish `tree-sitter-actions` to a registry with a real version, closing Core's standalone-build gap (the near-term motivator).
2. Establish per-repo semver + tagged releases across the platform.
3. Prebuilt binaries for the edge-facing tools (CLI, graphd) so phone/laptop install rather than compile.
