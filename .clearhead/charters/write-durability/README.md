---
alias: write-durability
state: Closed
description: Step-zero durability layer for file-authoritative writes — atomic single-file writes, set-atomic saves, and a staged multi-file commit seam that the CalDAV reconcile work will build on
---

# Write Durability

Foundational pre-work for [[caldav-integration]]. Before any two-way reconcile
touches the A/B/C triangle (action / sidecar snapshot / ICS), the workspace
needs to make file writes *safe under failure* — otherwise the file-authoritative
model will get blamed for losing data that an unprotected write actually lost.

## Why this comes first

The architecture is aligned with the product's values — plaintext files are the
source of truth, the graph is a derived read-model, the sidecar is a ruthlessly
scoped ledger. What's missing is **durability discipline**, and it's the one part
of the file model that is not optional once an external writer (radicale via ICS)
shares the workspace.

Today every production write is a naive `std::fs::write(path, content)`:

- `workspace/action_files.rs` — `.actions` files
- `workspace/sidecar.rs` — the `.json` ledger
- `workspace/store/save.rs` — the whole domain model
- `workspace/archive_charter.rs` — `archive.ttl`

`NamedTempFile` appears only in tests. A crash or a concurrent reader mid-write
can observe a truncated file, and `save_domain_model` writes files one at a time
with a separate orphan-removal pass — so a partial failure can leave a torn
workspace with no rollback.

## The disciplines

There are four disciplines total. This charter owns the two durability
disciplines; the other two — non-destructive archival and loud conflicts — live
with the reconcile work itself:

1. **Atomic single-file write** *(durability — this charter)* — temp file in
   the same directory, fsync, atomic rename. One primitive, every write routed
   through it.
2. ** Recoverable saves** *(durability — this charter)* — `save_domain_model`
   stages all writes and commits them as a batch so a partial failure can't
   tear the workspace. even with our partial method this should be fine due to the idempotency of many commands
3. **Staged multi-file commit** *(durability — this charter, as a seam)* — the
   seam reconcile will use to move an action and its sidecar snapshot together
   (A + B as one unit).
4. **Advisory workspace lock** *(durability — this charter)* — serialize
   ClearHead's own writes; reconcile only runs against a clean, unlocked
   workspace.

## Failure model (POSIX reality)

A single-file atomic write is genuinely atomic on POSIX: `rename(2)` in the
same directory is atomic, and with an `fsync` of the temp file before and the
directory after, prior content always survives a crash. Item 1 is real.

A *multi-file* "batch commit" is **not** atomic on POSIX — there is no
`rename`-multiple syscall. The set-atomic save (item 2) is therefore a
**staged-temps + ordered-renames + directory-fsync + pending-marker** scheme,
not a true atomic batch:

1. Write every target to its own temp file in the target directory, `fsync` each.
2. Write a `.pending` journal listing the intended (temp → final) renames,
   `fsync` it and the directory.
3. Perform the renames in a fixed order.
4. `fsync` the directory, then unlink the `.pending` marker.

On startup, a present `.pending` marker means a batch was interrupted: replay
the listed renames (idempotent — renaming a temp that's already gone is a
no-op), then clear the marker. This is recoverable-durability, not true
atomicity, and the crash tests must assert exactly that recovery path rather
than an impossible all-or-nothing guarantee.

this is important especially when we consider multi-file edits between various systems as we want to commit changes to action files and sidecars for example all at once so that we dont change one set of items and NOT the other

## Scope boundary

This charter does **not** build reconcile. It builds the primitive reconcile
stands on. When the staged-commit seam exists and is crash-tested, Decision 31
becomes safe to implement on top.

### Non-goals

- **The advisory lock does not serialize radicale.** It guards ClearHead's own
  writes against concurrent ClearHead invocations only. Radicale writes ICS
  through its own path; serializing it is a reconcile-charter concern (a radical
  e-side lock or a reconcile-time pause), not this one. A reader must not assume
  the lock makes concurrent ICS writes safe — it does not.
- **The staged-commit seam is provisional.** It has no consumer until reconcile
  lands; its API should be treated as revisable when the reconcile charter
  defines its actual call site.

## Done when

The layer is complete when **all three** hold:

1. Every production write site named above routes through the atomic primitive
   (tests may stay naive).
2. `save_domain_model` uses the staged-batch scheme and a crash mid-batch leaves
   either the pre-batch state or the full post-batch state — never a torn one —
   per the crash tests.
3. The staged-commit seam has a passing A+B failure test (commit A's file,
   simulate failure before B, assert neither A nor B is committed and prior
   content survives).

The advisory lock and its tests are required but are not a gate — they protect
ClearHead from itself, and a missing lock degrades to today's behavior rather
than to data loss.
