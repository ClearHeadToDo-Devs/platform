---
id: 01a0200b-24a2-7762-9176-8e47a2b4baf1
alias: pure-core-split
parent: platform
state: Active
---
# Pure Domain Core and the Delivery Boundary

ClearHead's domain logic belongs in one place that every host can reach —
native binaries and a browser alike. This charter re-establishes Core as a pure
domain library with no I/O, and relocates filesystem work to a shared native
workspace adapter. It reverses the earlier decision to pull I/O into Core, which
made a component that must stay portable and stable depend on the one thing a
WebAssembly host cannot provide.

## Problem

The workspace module currently fuses three separable concerns: translating
bytes to and from domain objects, deciding what a workspace is and what a
mutation does to it, and actually touching the filesystem to read and write.
That fusion was tolerable while the only host was a native binary. It stops
being tolerable the moment a second host exists that shares the first two
concerns but cannot share the third.

We want WASM bindings so local-first plugins (Obsidian, VS Code, a website) can
run the real domain instead of reimplementing it. A browser host has no
filesystem; it reads and writes through a vault API. If domain translation and
mutation logic live inside a module built for `std::fs`, that host can only
parse individual files — it cannot apply a verb — and any capability it does
have must be hand-reimplemented in another language, which is exactly the format
drift the spec-as-authority discipline already exists to prevent.

The same tangle also complicates the native story. `clearhead-lsp` was recently
made independently buildable; the question of whether to fold it back into the
CLI only looked open because drift felt like it required a shared binary. It
does not — it requires shared crates.

## Decisions

### The workspace remains the only canonical write model

Plaintext files stay the source of truth. This charter does not introduce a
database as the authoritative store, and therefore introduces no bidirectional
sync between a database and the files. A derived read index may appear later if
and only if a host measurably needs it, and it must be rebuildable from files
such that deleting it loses nothing. The portable path is:

```text
host inventory + resource bytes
    -> WorkspaceSnapshot
    -> DomainModel
    -> prepare(command)
    -> PreparedMutation { next_state, EffectBatch }
    -> host execution
```

The host reports what exists and supplies bytes; Core decides what those
resources mean and what should change.

### Core is pure domain logic, native and WASM

Core does no I/O. It holds the domain model, the verbs, the semantic
transaction (the sequential all-or-nothing fold), the codecs that translate
bytes to and from domain objects, the RDF projection, and query. Its mutation
entry point is a pure function of the shape `prepare(state, command) ->
Result<PreparedMutation, DomainError>`, and its reads take host-neutral
inventories and already-loaded resources as input. Core stays synchronous: no
host's asynchrony leaks into domain logic.

Crucially, Core owns not only per-file translation but the *assembly and
mutation* logic — which logical resources constitute a workspace, how many
resources fold into one coherent model, and what a verb changes across that
model. These are decisions, not I/O, so they belong where every host can reach
them. Leaving them below the WASM line would reduce browser hosts to read-only
file parsers.

### The portable boundary is snapshots, logical paths, and prepared effects

Core never receives an ambient host directory or an OS path from which it can
read. A host supplies an inventory and immutable resource snapshots containing
validated workspace-relative logical paths, bytes, and revision evidence. Core
may perform pure read-planning over that inventory before assembly. Logical
paths express workspace identity and layout without inheriting filesystem
canonicalization, separators, permissions, or symlink behavior.

A mutation result is speculative preparation, not a completed commit:

```text
PreparedMutation {
    next_state,
    effects: EffectBatch,
    preconditions,
}
```

The host may adopt `next_state` only after executing the effects successfully.
A conflict or failure before durable intent leaves the prior state authoritative.
Once native durable intent exists, an error is reported as recovery-required:
the batch's state is indeterminate until forward recovery converges it. A weaker
host that cannot recover forward reports partial execution explicitly. The
`EffectBatch` describes opaque resource writes, removals, and proven move
semantics as one semantic atomic group; it does not describe `std::fs` calls.

### A shared native workspace adapter owns filesystem execution

The CLI and LSP do not implement durability independently. They both use a
separate native-only crate (working name `clearhead-workspace-fs`) that reads
resource snapshots and executes prepared effects using the existing lock,
journal, staging, recovery, rename, and `fsync` machinery extracted from Core.
It is a separate package rather than a Core feature: native dependencies cannot
be additively enabled into Core, and the dependency direction remains
`workspace-fs -> core` only. The packages may remain in one repository and
release together.

This crate is a **ClearHead workspace adapter**, not a charter to design and
publish a general transactional-filesystem framework. Its internal commit
machinery should remain codec-agnostic and reasonably reusable, but
abstraction, replacement by an external crate, or independent publication
requires a real second consumer and a separate decision.

The single litmus test for every line moved remains: **does it touch the host,
or does it decide something?** Touching goes to an adapter; deciding goes to
Core.

### Charter archival is a native workspace convention

Archival does not create a second Charter domain category beyond the existing
closed/cancelled lifecycle state. Core owns the pure Charter and Action codecs,
semantic/reference helpers, and lifecycle decisions. Archive discovery,
crystallization workflow, archive naming and layout, supporting-file ownership,
file moves, cleanup, locking, recovery, and durable delivery belong to
`clearhead-workspace-fs` as conventions of the native plaintext workspace.

### Plans are domain schedules; vdir storage is native delivery

Core owns Plan semantics, recurrence, calendar codecs, and pure reconciliation
decisions. It does not own vdir discovery, collection or physical-path
ownership, file reads and writes, external plan-path mounts, sync-store
persistence, or filesystem-shaped calendar orchestration. Those concerns belong
to `clearhead-workspace-fs`, which presents workspace and external plans mounts
as distinct host inventories rather than flattening physical paths. This does
not restore legacy VEVENT support: ClearHead-owned Plans remain VTODO+RRULE.

### The WASM host reuses Core's brain over a different pair of hands

A browser host links Core (translation, assembly, mutation, the whole brain) and
supplies its own adapter against the vault API. It executes the *same*
`EffectBatch` Core produces and reuses the *same* Core codecs, so no host
reimplements the `.actions`/`.ics`/`.md` formats and no drift is introduced.
The adapter must report its execution outcome honestly: applied, conflict,
not-applied, recovery-required, or partial. Native delivery offers recover-forward
atomic convergence; a vault host may provide weaker atomicity and must expose
partial failure rather than letting Core treat speculative state as committed.

### Hosts are separated by operating model, not by domain

The CLI (one-shot, stateless) and the LSP (long-lived server holding a live
in-memory model, working on unsaved editor buffers) are genuinely different
lifecycles and remain separate binaries. Both are thin shells over the same Core
and native workspace adapter, so filesystem behavior and domain behavior each
have one owner. The LSP alone owns its unsaved-buffer overlay; editor-facing
edits may be returned as protocol `WorkspaceEdit`s, while durable workspace
writes use the shared adapter. `clearhead-lsp` stays independently buildable.

The governing rule — merge by operating model, not by domain — also settles
adjacent questions: one-shot capabilities such as SPARQL evaluation fold into
the CLI as a feature (per the RDF-publication charter), because they share the
CLI's lifecycle; the LSP does not, because it does not.

### Codecs are pure and named, but not yet a framework

Each `format <-> domain-object` mapping is a distinct, pure, cohesively named
unit in Core. Today there is exactly one format per object
(`.actions`/Action, `.ics`/Plan, `.md`/Charter). A pluggable codec framework —
a registry, a trait, dynamic dispatch — is not built until a real second format
(e.g. todo.txt) demands it and reveals whether it is a lossless peer or a lossy
one-way projection. Keeping each mapping cohesive leaves the seam latent at no
cost; building the framework now would fix an abstraction we cannot yet design.

## Target ownership

| Concern | Owner |
| --- | --- |
| Domain model, verbs, semantic transaction | Core (pure) |
| Codecs: bytes <-> domain objects | Core (pure) |
| Workspace assembly and layout policy | Core (pure) |
| RDF projection and query | Core (pure) |
| Logical paths, inventory/read planning, snapshot assembly | Core (pure) |
| `prepare(state, cmd) -> Result<PreparedMutation, DomainError>` | Core (pure) |
| Resource discovery/reads, lock, journal, recovery, durable commit | `clearhead-workspace-fs` |
| Charter archive discovery, crystallization, naming, moves, and cleanup | `clearhead-workspace-fs` |
| Vdir mounts/discovery, collection paths, calendar I/O, sync-store persistence | `clearhead-workspace-fs` |
| Unsaved editor-buffer overlay and `WorkspaceEdit` responses | `clearhead-lsp` |
| Vault-side execution of the same EffectBatch | WASM host adapter |
| CLI argument parsing, invocation, I/O wiring | `clearhead-cli` |
| Long-lived server, live buffers, in-memory model | `clearhead-lsp` |
| Authoritative store | Plaintext files (never a database) |

## Non-goals

- making a database authoritative over the workspace, or introducing
  bidirectional file/database synchronization
- building a persistent or on-disk read index before a host measurably needs one
- folding `clearhead-lsp` back into the CLI as a feature flag
- building a pluggable codec framework or a second file format in this charter
- allowing adapters to redefine codecs or domain mutation semantics; the native
  adapter owns only the archive, vdir, and other filesystem conventions named above
- making Core asynchronous to accommodate a host's async I/O
- designing or publishing a general-purpose transactional-filesystem framework
- replacing the proven lock/journal/recovery implementation merely because a
  young external crate exposes a superficially similar API

## Delivery strategy

Un-fuse before rebuilding hosts. First design the host-neutral inventory,
snapshot, logical-path, precondition, and `PreparedMutation` contracts. Then
cleave the workspace module along the host/decision seam, extracting the current
durability implementation and its tests intact into `clearhead-workspace-fs`.
Prove the native CLI and LSP behave identically over the new boundary before any
WASM binding exists. The WASM host is the payoff, not the first step — it should
light up mostly by supplying a second pair of hands to a brain that already
runs.

The native adapter must preserve the ordering currently guaranteed by
`with_locked_mutation`: acquire the workspace lock, recover pending intent,
load the trusted snapshot, invoke Core's pure preparation, and durably commit
before releasing the lock. Pure does not mean temporally outside the lock; a
pure function can run while its caller holds one. If a host cannot hold one lock
across read, decide, and commit, every affected resource carries expected
revision/content evidence that is checked immediately before execution, and a
mismatch returns a typed conflict for reload and recomputation. Atomic staging
without this stale-state protection is insufficient because it can atomically
commit a lost update.

## Implementation handoff — 2026-08-21

Completed and pushed:

- host-neutral logical paths, inventories, snapshots, revisions, read plans,
  preconditions, effects, prepared mutations, and typed delivery outcomes
- `clearhead-workspace-fs` crate and the ordered transaction vertical slice
- action insert/update/delete/close/archive preparation in Core with native
  delivery, sidecar pruning, locking, recovery, and tests in the adapter
- native config precedence/XDG/path expansion, NDJSON telemetry delivery,
  workspace detection, archived-fact discovery, and manifest I/O moved out of Core
- explicit workspace and optional external-plans mount namespaces, collection
  inventories, bounded read plans, immutable read evidence, and mount-aware findings
- pure Core workspace assembly over supplied bytes, preserving project/user naming,
  parser quarantine, global sidecar hydration, exact collection ownership, parent and
  predecessor resolution, and live occurrence linkage
- one native mount inventory/read facade shared by CLI, graphd, and LSP; external vdirs
  remain a separate namespace and reads detect inventory races without refusing an
  otherwise relaxed workspace read
- native action/sidecar read-write wrappers and template probing moved to
  `clearhead-workspace-fs`; Core retains codecs, metadata stamping policy, path
  conventions, and template instantiation
- host-neutral doctor byte/revision evidence, pure diagnosis, and typed repairs in
  Core; completed/archive/sidecar/manifest/durability observation plus locked
  recover-revalidate-execute repair delivery in `clearhead-workspace-fs`,
  including stale sidecar and external-vdir collection rejection
- charter archival selection fallback, locking/recovery, UUID-flat naming,
  supporting-file ownership, cleanup, and path-bearing results moved to
  `clearhead-workspace-fs`; Core retains pure lifecycle, hierarchy, reference,
  and surgical frontmatter policy
- archival now emits revision-guarded `Move` effects for verbatim resources and
  atomic `Write` plus recover-forward `Remove` effects for crystallized files;
  journaled tombstones make removal crash-recoverable, while missing sources,
  stale revisions, existing destinations, and duplicate flat names are rejected
- canonical effects and preconditions now carry `ResourceLocation`, so one native
  journal can deliver mixed workspace and external-plans `Write`/`Move`/`Remove`
  effects without flattening mount identity
- effective-vdir discovery/immutable reads and sync-store reads moved to
  `clearhead-workspace-fs`; CLI Plan reads use the same native mount inventory
- Plan add/update/delete, projected-occurrence deviations, and recurring-master
  roll-forward persistence moved to stale-guarded native batches; loose `--file`
  preserves its exact ad-hoc path without imposing vdir hierarchy, and existing
  Plan updates preserve alarms, vendor properties, and calendar metadata
- Core retains byte-level RFC 5545 parsing/rendering, including pure Plan,
  occurrence-deviation, master-roll-forward, and Action-mirror transformations
- Core direct dependencies on `config`, `dirs`, `shellexpand`, and `tracing` removed
- no-default Core build check, spec-conformance, strict workspace Clippy, and full
  pre-push workspace tests green at Core `bb93bef`

Next coherent slice (tracked as sequential child actions):

1. `migrate-calendar-sync`: replace filesystem-shaped Core `apply_sync` with
   reconciliation recomputed from fresh evidence under the native lock and pure
   preparation of Action/calendar/sync-store effects in one stale-protected
   mixed-mount batch. Recovery precedes mutable reads; dry-run remains observational.
2. `remove-core-calendar-io`: migrate materialized-occurrence resolution and the
   remaining root-based calendar/store loader callers, then remove obsolete Core
   calendar I/O APIs while retaining recurrence, reconciliation, and codecs in Core.
3. `extract-native-durability`: move locks, journaling, staging, fsync, recovery,
   and remaining host dependencies into `clearhead-workspace-fs`; remove
   `fs2`/`tempfile` from Core, run native/no-default/WASM dependency gates, and
   reconcile ownership docs, specifications, decision history, and pinned checks.

Do not flatten an external plans mount into workspace-relative paths, duplicate
native loader ownership, restore VEVENT support, move codecs/reconciliation semantics
into the filesystem adapter, compute sync from a pre-lock report, or split one logical
sync across independently durable commits.

## Done gate

This charter is complete when:

- Core compiles to both a native library and WASM with a documented portable
  feature set, contains no host I/O, and does not depend on the native adapter;
  its feature/dependency audit identifies and removes native filesystem,
  network, user-directory, and async-runtime capabilities from the portable graph
- host-neutral inventory, logical-path, immutable snapshot, and pure read-planning
  contracts let Core assemble a workspace without ambient filesystem access
- the workspace module's translation, assembly, and mutation logic live in Core;
  resource discovery/reads and durable execution live in `clearhead-workspace-fs`
- Core exposes pure preparation returning a `PreparedMutation`; its next state is
  adopted only after successful execution, and the `EffectBatch` shape explicitly
  covers preconditions plus whatever move and atomic-group semantics real
  mutations such as crystallization prove necessary
- `clearhead-workspace-fs` is a separate native package shared by CLI and LSP,
  contains the extracted and regression-protected lock/journal/recovery machinery,
  owns the named native archive/vdir/filesystem conventions, and holds no codec
  or domain-mutation opinion
- native writes preserve stale-state safety by holding the lock across
  recover -> snapshot -> prepare -> commit, or by validating equivalent
  preconditions under the lock before touching any target
- the CLI and LSP are thin shells over shared Core and native adapter crates, remain
  separate independently buildable binaries, and behave identically over the new
  boundary as evidenced end-to-end
- a WASM binding executes the same `EffectBatch` and reuses the same Core codecs
  against a non-filesystem host, with no format logic reimplemented outside Core;
  weaker atomicity or partial failure is represented honestly in its outcome
- files remain the sole authoritative store; no database is authoritative and no
  bidirectional sync exists
- specifications, decision history, and pinned-platform validation agree that
  Core is pure and the delivery boundary is where I/O begins
