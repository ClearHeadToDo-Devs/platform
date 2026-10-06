---
id: 01a00363-93cf-7903-9080-a9ef8eb0ba2e
alias: deployment
parent: platform
objectives:
  - strong-CI-CD
state: Active
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

## Current status, 2026-10-05

The specification is released (v0.2.0) and published at `clearhead.dev`. Next is the CLI, as prebuilt binaries that `cargo binstall clearhead_cli` downloads: publish the grammar, then Core, to crates.io; build the binaries with `dist`; release. Decided with the human: each repository has its own semver, the CLI names the spec release it implements, and releases follow user-visible change rather than a calendar. Open: which targets to build.

## Log

- 2026-10-05 — spec-site and spec-release-0-2 done. Planned the CLI release: publish-grammar, publish-core, cli-dist, version-names-spec, cli-release. Found: crates.io serves clearhead_cli 0.2.1 from 2025-12-24, and the CLI's repository URL is a 404.
- 2026-10-05 — publish-grammar done; Core takes the grammar from crates.io and declares the specification release it implements (v0.2.0), which CI checks out and validate-pinned enforces. Decided with the human: rely only on published, pinned versions, as a consumer would. Core's CI is green for the first time in at least 100 runs: the platform-only [patch] had broken --locked, and tests assumed a sibling spec checkout and the formatting feature.
- 2026-10-06 — The specification is MIT-licensed (the human: permissive, commercial use is a win) and released as v0.2.1 so clearhead.dev serves the license; its contract is unchanged, so Core still declares v0.2.0 and the platform pins it. The README credits the imports' licenses (CCO BSD 3-Clause, IAO CC BY 4.0). clearhead.nvim has the MIT LICENSE its README claimed.
