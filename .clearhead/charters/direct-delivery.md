---
id: 01a09de3-5d8b-739f-808f-80025c265e23
alias: direct-delivery
parent: platform
state: Closed
---
# Direct Delivery: Retiring the Journaling Machinery and Two-Phase Mutation Protocol

ClearHead currently maintains an enterprise-grade durability framework inside
`clearhead-workspace-fs`: multi-file write-ahead journaling (`.pending`),
tombstone recovery, and OS lockfiles (`flock`). To feed it, `clearhead-core`
wraps its effect batches in a speculative-state typestate — `PreparedMutation`,
`AppliedMutation`, and an `adopt()` handshake — so a pure Core can describe
writes without performing them.

This machinery was built to keep Core pure for WASM while preventing partial
writes across multi-file mutations. In practice the journal does nothing to
protect cross-device sync (Syncthing ignores OS locks and chokes on rapid
`.pending` files), and the two-phase protocol has become more ceremony than the
domain it wraps.

This charter retires the journaling/lock layer and the two-phase protocol. Core
keeps its purity but speaks plain **data-in / data-out**; durability collapses
to single-file POSIX atomic writes. Crucially, we **keep the
`clearhead-workspace-fs` crate** — we slim it. The crate boundary is what makes
Core's I/O-purity compiler-enforced (Core simply doesn't depend on fs) rather
than policed by a source-gate script; and the crate holds the read path
(discovery, manifest, detection) and `doctor`, which must survive.

> **Supersedes:** this reverses the `PreparedMutation` *typestate* direction
> introduced by the pure-core-wasm-split work. That split correctly moved I/O
> *out* of Core; it over-built the *handshake*. We keep the pure-core /
> thin-driver outcome — and keep `EffectBatch` as the plain data-out — while
> deleting the speculative-state ceremony wrapped around it.

## Problem

1. **The typestate wrapper is heavier than the domain**: the generic
   `PreparedMutation<S, O>` threads a speculative `next_state` and an `adopt()`
   handshake through every verb signature, plus `AppliedMutation`, recovery
   tokens, and the CI purity gate — none of which any driver consumes (they
   discard `next_state` and re-read files). The ceremony exceeds the logic.
2. **Over-insuring against microsecond failures**: `PendingBatch` exists to
   prevent an interrupted write when an operation touches more than one file.
   But these are personal plaintext files already living in git and/or
   Syncthing — **git is already the write-ahead log** for this data. Maintaining
   a second WAL on top of a versioned store is an enormous tax for a vanishingly
   rare failure mode that git already covers.
3. **Hostile to eventual-consistency sync**: `flock` does not cross network
   boundaries, and writing `.pending` journals into a Syncthing workspace
   actively triggers sync-conflict storms. The journal meant to protect data
   actively corrupts the multi-device story.
4. **Cognitive and context saturation**: two-phase effects plus custom
   persistence machinery force both human contributors and AI agents to hold a
   large protocol in context before performing a simple write.

## Target Architecture

The crate graph does **not** change. `clearhead-cli` and `clearhead-lsp` already
depend on both `clearhead-core` and `clearhead-workspace-fs` (a diamond). What
changes is the *handshake* across the core→driver arrow — not the arrows.

```text
        ┌────────────────────────────────────────────┐
        │                clearhead-core               │  pure · zero I/O
        │     AST · domain models · codecs · RDF      │  verbs: data in → data out
        └────────────────────────────────────────────┘
                    ▲                        ▲
                    │  (fs and both drivers depend on core)
        ┌───────────┴──────────────┐         │
        │   clearhead-workspace-fs │         │
        │   (thin) atomic_write ·  │         │
        │   discovery · manifest · │         │
        │   detection · doctor     │         │
        └───────────▲──────────────┘         │
                    │   (drivers depend on both fs and core)
        ┌───────────┴────────────┬───────────┴─────────┐
        │     clearhead-cli      │     clearhead-lsp    │
        │     args · UI          │     buffers · diags  │
        └────────────────────────┴──────────────────────┘
```

### 1. `clearhead-core` is a pure data-in / data-out library
* Core owns types, validation, Tree-sitter AST surgery, and RDF publication.
* Core performs **zero I/O** and wraps its writes in **no speculative-state
  typestate** — no `PreparedMutation` / `AppliedMutation` / `adopt`. Verbs take
  plain data (`&str`, AST references, in-memory file maps) and return a plain
  `(EffectBatch, outcome)` — the batch describing the writes, its preconditions
  carrying the revision compare-and-swap the driver checks before applying.
* Core's purity then needs no source-gate script to enforce: the absence of an
  fs dependency enforces it, and the compiler checks it.
* **WASM caveat**: I/O-purity is necessary but *not sufficient* for WASM. Core
  links the Tree-sitter grammar (C), which still requires a wasm libc sysroot
  (see the bundle-tree-sitter-for-wasm decision). This charter removes the I/O
  and gate obstacles; the C-toolchain step is separate and unchanged.

### 2. Slimming `clearhead-workspace-fs` (not deleting it)
* The crate stays. We delete its journaling/lock layer and keep its read path.
* **Deleted**: `durability.rs`'s `.pending` write-ahead journal, `PendingBatch`,
  `recover_pending`, tombstones, startup forward-recovery, and the `flock`
  `WorkspaceLock`.
* **Kept**: discovery, manifest, detection, config, sidecar, calendar, archive,
  templates, and `doctor` — the read path and reconciliation both drivers need.
* The boundary is retained deliberately: it keeps Core's purity
  compiler-enforced and gives `clearhead-cli` and `clearhead-lsp` one shared
  home for file logic instead of duplicating it.

### 3. Durability simplified to POSIX `atomic_write`
* Single-file atomic pattern: write to a tempfile in the target directory,
  `fsync`, `rename`.
* Multi-file operations execute as **sequential, additive-ordered** atomic
  renames — see §4.
* All `.pending` journals, tombstones, and startup forward-recovery logic are
  deleted.

### 4. Self-Healing via UUIDs, Additive Ordering, and Doctor
* Consistency across files is maintained through domain identities, not
  distributed-transaction locks.
* Actions carry stable UUIDs (`# 0195...`) and timestamps. **Invariant**:
  multi-file writes are strictly *additive-ordered* — the destination file is
  written and `fsync`ed **before** the source is removed. A crash mid-operation
  therefore leaves the action in *both* places (a duplicate `doctor` can
  reconcile), never in *neither* (silent loss). This ordering is the safety
  property the journal used to provide; it must be explicit and tested, not
  assumed.
* `clearhead doctor` detects and reconciles duplicate action UUIDs. In
  git-backed workspaces, `git diff` / `git restore` provide instant rollback.
* **Semantics change, stated plainly**: recovery moves from
  automatic-on-startup to run-when-invoked (`doctor` is manual). Acceptable for
  a git-backed personal tool, but a real downgrade to acknowledge — worth
  considering an opportunistic duplicate check on load.

### 5. Derived Projections are One-Way
* `.ics` calendar sync and RDF triplestores are one-way projections.
* They are generated on demand or as post-write exports. They do not
  participate in transactional batches.

## What is Eliminated

- `durability.rs`: the `.pending` write-ahead journal, `PendingBatch`, and
  `recover_pending`.
- OS-level exclusive `WorkspaceLock` / `flock` (unblocking Syncthing).
- Core's speculative-state typestate: `PreparedMutation<S, O>`,
  `AppliedMutation`, the `adopt()` handshake, and the per-verb `next_state`
  structs (`ClosePreparedState`, `DeletePreparedState`, `CalendarSyncState`).
  Verbs now return a plain `(EffectBatch, outcome)`.
- `scripts/pure-core-source-gate.sh` (the crate boundary makes it redundant).

> **Not** eliminated: the `clearhead-workspace-fs` crate itself (its read path —
> discovery, manifest, detection, sidecar, config, calendar, archive, templates
> — and `doctor` survive, slimmed not deleted); and **`EffectBatch` +
> `ResourcePrecondition`**, kept as plain data-out. Their preconditions are the
> revision compare-and-swap that, with the lock gone, is now the *only* guard
> against a concurrent writer's stale overwrite. (`MutationDecision` never
> existed — an earlier draft named it in error.)

## Compatibility & Migration

1. **Data Format**: Zero changes to the `.actions` file format or grammar.
2. **CLI & LSP Behavior**: User-facing commands and editor behaviors remain
   identical.
3. **Git/Syncthing Interop**: Workspaces become cleaner; no ephemeral journal or
   lock files pollute the filesystem or trigger sync conflicts.
4. **WASM & Future Hosts**: An Obsidian or web host simply passes vault file
   strings to `clearhead-core` functions and writes the returned strings back
   via the host API — no bespoke WASM workspace adapter. (The Tree-sitter C
   sysroot step of §1 still applies; it is orthogonal to this charter.)

## Done Gate

- `clearhead-core` exposes no speculative-state ceremony: verbs return a plain
  `(EffectBatch, outcome)` — no `PreparedMutation` / `AppliedMutation` / `adopt`
  / `next_state`. `EffectBatch` is retained as the precondition-carrying value
  object.
- CLI and LSP invoke Core directly with in-memory data, validate the batch's
  preconditions, and persist via the fs crate's `atomic_write`.
- File writes use single-file atomic renames without `.pending` files.
- Multi-file writes are additive-ordered (destination `fsync`ed before source
  removed), with a test asserting a crash between renames yields a recoverable
  duplicate, never data loss.
- `clearhead doctor` verifies and heals duplicate action UUIDs across files.
- `flock` / `WorkspaceLock` is removed; a rapid-write (Syncthing-style) scenario
  produces no lock or journal artifacts.
- All existing CLI commands and LSP tests pass green.
