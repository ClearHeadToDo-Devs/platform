---
id: 019f738f-0897-7e92-988f-3cfe7cd84fc0
alias: workspace-durability
parent: platform
state: Closed
---
# Workspace Mutation Durability

Workspace files are the source of truth, so every mutation that spans files
must either complete coherently or leave enough durable intent to recover
forward. The LSP extraction established the right primitive for action archive
sweeps, but the final review found that the policy is not yet universal.

## Findings

- `complete action` and `cancel action` still remove a subtree from the active
  file before appending it to the completed file; failure of the second write
  can lose the subtree
- `WorkspaceLock` is a create-once PID file with no stale-owner recovery, so a
  killed writer can permanently block operations that require the lock
- lock contention is handled inconsistently: action archival refuses to race,
  while model save and calendar reconciliation silently continue unlocked
- the old CLI archive module remains as dead duplicate code and still contains
  the superseded unsafe write ordering

## Direction

Core owns the read-plan-apply operation and the concurrency contract. CLI,
LSP, calendar, and future agent surfaces call that operation rather than
assembling filesystem writes independently. Locks must have explicit stale,
contention, and recovery semantics shared by every writer.

## Done gate

- complete and cancel cannot lose or duplicate a subtree after any partial
  write
- all multi-file workspace writers follow one documented lock policy
- stale lock ownership is detected and recoverable without deleting a live
  writer's lock
- interrupted batches recover before a subsequent mutation reads workspace
  state
- no obsolete alternate archive implementation remains in the CLI

## Resolution (2026-07-17)

The mutation seam is now core-owned end to end:

- `close_action_subtree` performs the locked recovery/read/plan/batch-commit for
  complete and cancel; the CLI only resolves a selector and emits the result
- legacy id-less lines survive the second parse through a selector carrying the
  preferred UUID plus alias/name fallback, while inline UUID remains canonical
- `WorkspaceLock` uses an OS exclusive file lock (`fs2`) on a persistent inode;
  PID text is diagnostic only, process death releases ownership, and callers
  uniformly fail on contention rather than continuing unlocked
- action archival, charter archival, model save, and calendar reconciliation
  recover pending intent under the lock before reading mutation inputs
- batch commit and recovery fsync every affected source/destination directory
  before removing the journal; malformed journals are retained for diagnosis
- directory-form charter archival moves every charter-local supporting file,
  not only formats core already recognizes
- the dead `clearhead-cli/src/archive.rs` duplicate was removed; its behavioral
  coverage already lives with the core implementation
- the remaining `archive plans` cross-boundary writer was retired: plans are
  externally-owned schedules, `delete plan` is the explicit deletion verb, and
  generated actions keep their independent action lifecycle

The shared policy is specified in `specifications/workspace.md` under “Mutation
durability and locking.” Crash recovery, lock contention/stale PID behavior,
selected-subtree closure, duplicate prevention, and supporting-file archival
all have core regression coverage.
