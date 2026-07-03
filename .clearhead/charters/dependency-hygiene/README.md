---
alias: dependency-hygiene
state: New
description: Get every submodule green on its own CI and drive dependabot to zero — mostly by deleting a dead dependency, swapping one unmaintained crate, and running the updaters, because the surface is smaller than the alert count suggests
---

# Dependency Hygiene

Two complaints arrived together — "jsonld tests are failing" and "dependabot
is unhappy" — and the analysis found they share a shape with [[core-seam]]:
**the alert count is bigger than the problem.** Most of the vulnerable
dependencies are ones we don't use or don't directly own. Fix the small number
of real declarations and the noise collapses.

## What's actually wrong

### 1. The "failing jsonld tests" are green — CI can't build

`clearhead-core`'s jsonld suite passes locally (219 tests, 0 failures). What's
red is the standalone CI, and it never reaches the tests: the build aborts.
`clearhead-core/Cargo.toml` declares

```
tree-sitter-actions = { path = "../tree-sitter-actions", version = "0.9.4" }
```

That sibling path only exists because the platform super-repo lays the
submodules out side by side. `clearhead-core` has no `.gitmodules`, so its own
CI checkout (`submodules: true` notwithstanding) has no sibling to find, and
`cargo` fails on a missing `Cargo.toml`. The jsonld job "fails" only because
the crate never compiles. This is the same seam bug as core-seam: **a piece
that only works inside the super-repo.**

### 2. The dependabot alerts trace to three declarations, not thirteen

- **The openssl cluster (8 alerts, up to high) is a dead dependency.**
  `clearhead-cli` declares `reqwest` with zero usages anywhere in the crate —
  not src, tests, or benches. It drags in `native-tls → openssl` and the
  `hyper/h2` stack. Deleting the line removes the entire cluster (and likely
  the `bytes` alert with it).
- **`serde_yml` / `libyml` (unmaintained + unsound) is one file.**
  `clearhead-core` uses `serde_yml` in exactly two call sites, both in
  `workspace/charter.rs`, to parse charter frontmatter. `serde_yaml_ng` is a
  maintained, API-compatible drop-in.
- **The rest is `cargo update`.** `time` (via the `jsonschema` dev-dep) and
  `rand` (via `automerge`) are transitive and low-leverage; a lockfile refresh
  addresses what has patches and the remainder waits on upstream bumps.
- **The npm highs (`fast-uri` ×2, `tar-fs`) are build tooling.**
  All three sit under `tree-sitter-actions`' devDependencies
  (`tree-sitter-cli`, `prebuildify`), not in the shipped parser. `npm update`
  plus merging the dependabot PRs clears them.

## The one real decision

Fixing the CI break means choosing how `clearhead-core` names its dependency on
`tree-sitter-actions` so the crate builds *both* standalone and inside the
super-repo, without losing the local edit-both-together loop:

- **git dependency** (`git = "…", tag = "v0.9.4"`) — simplest, CI already has
  network, but local edits to the parser no longer flow into core without a
  `[patch]`.
- **nested submodule** + `path = "tree-sitter-actions"` — keeps `submodules:
  true` meaningful and preserves local path edits, at the cost of
  submodule-of-a-submodule bookkeeping.
- **CI sibling-checkout step** — smallest diff, makes CI mirror local reality,
  but leaves the crate un-buildable by anyone cloning it alone.

My lean: **git dependency pinned to a tag**, with a documented local `[patch]`
for the platform dev loop. It's the only option that makes `clearhead-core` a
truthfully self-contained crate — which is the whole point of it being a
separate repo — and the platform super-repo is where we already accept the
"edit several at once" complexity. But this is your call on the dev loop; I
haven't picked it for you.

## Scope boundary

This charter changes dependency *declarations* and lockfiles only — no behavior
change. If swapping `serde_yml` surfaces a parsing difference in charter
frontmatter, that's a bug to fix in place, not a scope expansion. Anything that
needs an upstream crate to cut a release (the residual `rand`/`time` alerts if
`cargo update` can't reach them) is noted and left for dependabot, not forced.

## Done when

1. `clearhead-core` CI is green — the crate builds standalone, and the jsonld
   suite runs (and passes) there.
2. `clearhead-cli` no longer declares `reqwest`; `cargo tree` shows no
   `openssl`/`native-tls`, and the crate still builds and tests clean.
3. `clearhead-core` parses charter frontmatter through a maintained YAML crate;
   `serde_yml`/`libyml` are gone from the lockfile.
4. `cargo update` has been run in both Rust crates and `npm update` in
   `tree-sitter-actions`; remaining open dependabot alerts are only ones
   blocked on an upstream release, listed here.
5. Dependabot shows zero high/critical across all submodules.
