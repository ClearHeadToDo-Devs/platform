---
id: 01a08e88-fda6-7ea0-bc05-11b606e56295
alias: unified-workspace-root
parent: platform
state: Active
---
# Unified Workspace Root

ClearHead currently gives project-local and user workspaces different root
shapes. Project workspaces use a project-named root represented by
`charters/README.md` and `charters/next.actions`, while user workspaces can
materialize a separate `next` charter entity. That distinction leaks into
loading, name inference, plans, mutations, tests, and migration behavior.

The target is one structural model for every workspace:

- `charters/README.md` is the root charter's prose and identity anchor.
- `charters/next.actions` is the root charter's reserved action anchor — the
  same stem every charter uses for its own actions at every level of the tree.
- The root anchor is a reserved file *role*, not a charter entity named `next`,
  so named charters cannot collide with the root.
- Every other charter descends from the root; flat charters are its direct
  children and nested placement expresses deeper lineage.
- Project and user scope affect discovery, configuration, and the initial name,
  but not the resulting domain shape.

At initialization, a project root takes the persisted project/workspace name. A
user root takes a persisted username-derived default that the user may override.
The UUID and chosen name are minted or derived once and persisted; normal loads
must not repeatedly infer them from the current path or environment.

## Compatibility

The `next.actions` anchor stem is unchanged, so no file rename is required. The
migration is limited to root *identity*: user workspaces that materialized a
standalone `next` charter, and project workspaces whose root name was recomputed
from the working directory, are reconciled to a single reserved root with stable
persisted identity. `doctor` owns that reconciliation and conflict reporting.
Normal workspace loading must not silently rewrite, merge, or repeatedly
reinterpret existing roots.

## Done gate

- Fresh project and user initialization produce the same canonical root files.
- Each workspace loads exactly one root charter with stable persisted identity
  and name.
- All other charters have a deterministic path to that root.
- Intake, plans, references, charter mutations, sidecars, and archival agree on
  the canonical root anchor, and the `next` root sentinel lives in one place.
- Existing roots keep loading unchanged and have a tested doctor identity
  reconciliation.
- The platform workspace is migrated through that supported path after the
  implementation and conformance suite are green.

## Log

### 2026-09-10

Landed the keystone read-side fix (commit `06dfe7f`):
`NativeWorkspaceMounts::resolve` now derives the project root-charter name from
the persisted `workspace.json` `workspace_name`, falling back to the cwd basename
only when no manifest exists, then to `"workspace"`. This kills the "runtime
recomputes the name from cwd" defect that produced the original `unresolvable-parent`
doctor failure. (The recursion trap: `resolve()` must read `.clearhead/workspace.json`
directly, never via `read_workspace_manifest`, which re-enters `resolve()`.)

Full workspace suite green. NOT yet done, in rough order:

- **A test that actually proves the fix.** Every current test runs where the
  cwd basename already equals the persisted name, so none exercises divergence.
  Add: init in dir `A`, then load from a renamed/copied dir, assert the root name
  and child-parent resolution stay `A`. Until this exists the fix is unguarded.
- init should also write `README.md` (root prose anchor); it currently only
  writes `next.actions` + sidecar + `workspace.json`. (#3)
- User-workspace root is still shapeless — no persisted name, no root charter —
  so the project-vs-user branch in `resolve()` remains. (#3, #4)
- Optional `clearhead init --name` so the initial name is a deliberate choice,
  not hostage to the directory. (#2)
- `doctor` should detect the `file_name()` fallback (a workspace with no persisted
  name) and offer to mint + persist it, instead of limping silently. (#5)
- The `next` root sentinel is still duplicated across charter/plans/reconcile;
  consolidate to one constant. (#6)
- Re-amend the specs for the `next.actions` decision (#1 was reopened).
