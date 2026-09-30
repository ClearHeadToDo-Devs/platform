---
id: 01a0f38e-7c54-724a-b6cb-5f0e348b56c0
alias: spec-releases
parent: platform
state: Closed
---
# Spec Releases

Implementations name the specification they conform to by a release, never a moving branch, so the spec and each implementation can move on their own schedules.

Found 2026-09-30: every workspace file Core writes stamps `$schema` to `specifications/master/schemas/...`, so the schemas' identity moved with every commit to the spec's `master`. That made renaming the branch an identity change, and the name mismatch (three repos on `master`, the rest on `main`) broke the platform's on-demand submodule push. The schemas' `$id`s were also inconsistent: six on raw `master` URLs, `actions` and `charters` on `github.com/.../schemas/...` URLs that do not resolve.

## Decisions (2026-09-30, with the human)

- **One semver version for the whole specification repo**, starting at `v0.1.0`. A release is a coherent set that implementations adopt together; semver tells an adopter whether a bump breaks them. Pre-1.0 says the contract can still change.
- **Every schema `$id` is `https://raw.githubusercontent.com/ClearHeadToDo-Devs/specifications/<tag>/schemas/<name>.json`.** A release is one commit that moves every `$id` to the new tag and turns the changelog's heading into that version; the tag goes on that commit.
- **The platform gate ties them together.** `scripts/validate-pinned` checks that every `$id` in the pinned spec names one tag and that the schema URLs Core stamps equal those `$id`s. Implementations adopt a release when they choose; the composition cannot drift.
- **`master` becomes `main`** in specifications, tree-sitter-actions and clearhead.nvim, after the tag pinning so the rename only touches mutable links.

## Done when

- `v0.1.0` is tagged and pushed, and its schemas' `$id`s name it.
- Core stamps the `v0.1.0` URLs, and the gate fails when Core and the pinned spec disagree.
- No `$schema` in our repositories names a branch.
- All six repositories use `main`, and `git push` from platform pushes the submodules again.

## Log

- 2026-09-30 — CLOSED the same day: v0.1.0 tagged and pushed, all eight ids resolve; Core stamps them and the gate holds it to the pinned ids; 47 $schema pointers swept; specifications, tree-sitter-actions and clearhead.nvim renamed to main, and one git push from platform now pushes every submodule.
