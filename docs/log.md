## 2026-09-18
* **Creation**: Initialized OKF v0.2 knowledge bundle.
* **Update**: Added conformant frontmatter to the six migrated docs (`DECISIONS`, `CONTRIBUTING`, `SUBMODULES`, `WORKTREES`, `workflows`, `history/rdf-publication-baseline`) and wrote a real root `index.md` linking all of them. Bundle is now conformant per `okf validate`.
* **Creation**: Added `overnight-worker-clearhead-core.md` — a pre-decided, ordered task list for tonight's unsupervised overnight run, scoped to `clearhead-core` only.
* **Creation**: Added `crate-merge-and-charter-identity.md` — invariants I1–I11, ordered steps, gate and stop conditions for the crate merge and charter identity split. **Update**: `DECISIONS.md` gained Decisions 39 (one binary, two crates) and 40 (document identity optional, domain required).
* **Creation**: Added `overnight-worker-crate-merge-and-identity.md` — the successor overnight runbook: worktree and branch isolation, one gate command, a per-task review step, a morning brief, and a launch checklist for the human.

## 2026-09-22
* **Update**: Both overnight runbooks now make the independent review a gate on the `platform` submodule bump rather than a soft per-task step: a fresh agent, a different model when one is available, reviews the diff against the plan's invariants and a finding blocks the bump. The same-model same-context pass is named as a weaker fallback, not the review. Invariant tests in `clearhead-core` now enforce I4 (reads never write), I5 (`jot` does not stamp an id) and I6 (a change between read and write is a conflict for `update`, `close` *and* `jot`).
