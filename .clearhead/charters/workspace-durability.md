---
id: 019f738f-0897-7e92-988f-3cfe7cd84fc0
alias: workspace-durability
parent: platform
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
