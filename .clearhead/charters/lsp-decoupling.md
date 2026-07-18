---
id: 019f733b-fa0e-7871-8ed0-2f1100562699
alias: lsp-decoupling
parent: platform
state: Closed
---
# Decoupling the LSP

The LSP already runs as a stdio process, but its implementation, async runtime,
protocol dependencies, and release lifecycle are still owned by
`clearhead-cli`. The CLI enables LSP support by default, so building the command
client also builds Tokio, Tower LSP, DashMap, editor document state, and every
protocol handler.

We will extract that runtime into an independent `clearhead-lsp` binary and
repository, following the graphd ownership pattern while using the standard LSP
JSON-RPC protocol rather than inventing a new process contract.

## Intended ownership

### `clearhead-core`

Core remains the shared graph- and editor-neutral library. It owns parsing,
source maps, lint findings, formatting, reference resolution, domain diffs,
workspace discovery, sidecar operations, and durable workspace mutations.

### `clearhead-lsp`

The new runtime owns:

- Tower LSP and Tokio
- stdio JSON-RPC lifecycle
- open-document state and workspace-folder routing
- conversion from core ranges/findings into LSP types
- diagnostics, code actions, completion, inlay hints, semantic tokens,
  definition, references, formatting, and custom commands
- LSP-specific telemetry output adapter
- protocol and provider tests

### `clearhead-cli`

The CLI returns to synchronous command concerns. During migration,
`clearhead start lsp` may remain as a compatibility shim that execs the
external `clearhead-lsp` binary without linking the LSP runtime.

### `clearhead.nvim`

The plugin launches `clearhead-lsp` directly, with an explicit configured path
and a temporary legacy fallback during transition.

## Hard requirement: fix archive durability before moving it

The existing `clearhead/archive` LSP command writes the completed-actions file
first and then asks the editor to apply the active-buffer edit. If the editor
edit fails, actions can exist in both locations. Auto-archive on save uses the
same ordering.

This behavior must not simply move into the new crate. Action archival needs a
shared durable workspace operation with explicit semantics for an open editor
buffer. The extraction can proceed around it, but the new runtime must not ship
with the split write/apply-edit failure mode preserved.

### Archival ordering found

There are currently two distinct unsafe implementations:

- the CLI writes the reduced active file first, then appends the terminal
  actions to `.completed.actions`; failure of the second write can lose actions
- the LSP writes `.completed.actions` first, then requests `workspace/applyEdit`
  for the active buffer; rejection/failure of that edit duplicates actions
- LSP auto-archive on `didSave` uses the same completed-first/apply-edit order

Core charter archival already demonstrates the intended mechanism:
`WorkspaceLock` plus `PendingBatch` and forward-recoverable journaled renames.

### Open-buffer decision

The LSP will not attempt a distributed transaction across filesystem writes and
an editor-owned buffer. Action and charter archival custom commands will leave
the LSP surface. `clearhead.nvim` already has the safer fallback shape and will
make it canonical:

1. save the buffer
2. invoke the CLI archival verb
3. let core atomically update all workspace files
4. reload/close the affected buffer only after success

Core will own both the pure partition/plan and the locked `PendingBatch`
application for action archival. The CLI becomes a thin caller. This removes
the inconsistency window rather than moving it into the new runtime.

## Process contract

Unlike graphd, no custom invocation payload is needed. The public contract is
Language Server Protocol over stdio. The canonical command becomes:

```sh
clearhead-lsp
```

The compatibility CLI command, if retained, delegates to that executable with
stdin/stdout/stderr inherited.

## Initial inventory (2026-07-17)

The implementation is contained in roughly 1,500 lines:

- `clearhead-cli/src/lsp/mod.rs`
- `clearhead-cli/src/lsp/handlers.rs`
- `clearhead-cli/src/lsp/providers.rs`
- `clearhead-cli/src/lsp_main.rs`

Direct CLI-library coupling is limited to:

- `archive::archive_actions` — requires durability redesign
- the NDJSON telemetry emitter — should become an LSP-owned adapter
- parser/lint/format re-exports that can import `clearhead-core` directly

The LSP does not depend on CLI argument parsing or `CommandContext`; workspace
roots already arrive through standard LSP initialization. This makes the
physical extraction lower-risk than the graph move.

## Baseline

Before extraction:

- `cargo tree --no-default-features`: 641 rendered dependency lines
- default `cargo tree` with LSP: 695 lines
- LSP-only direct dependencies: Tokio (`full`), Tower LSP, and DashMap
- current local debug artifacts are approximately 172 MB for the lightweight
  CLI and 430 MB for `clearhead-lsp` (debug sizes are directional, not release
  benchmarks)

The important acceptance test is structural: Tower LSP and DashMap must be
absent from the final CLI dependency tree, and the LSP-owned full-feature Tokio
edge must disappear rather than merely being dead-code eliminated. The
pre-extraction `--no-default-features` baseline already contained Tokio through
`clearhead-core -> topiary-core`; formatter ownership is outside this charter
and that pre-existing transitive edge is not evidence of an embedded LSP.

After removing the embedded runtime, the CLI tree returned from 695 to the
641-line no-LSP baseline. Tower LSP and DashMap are absent. The only normal
Tokio path is the pre-existing `clearhead_cli -> clearhead_core ->
topiary-core -> tokio` formatter path; Tokio, Tower, and DashMap are no longer
direct CLI dependencies.

## Outcome (2026-07-17)

The extraction is complete. `ClearHeadToDo-Devs/clearhead-lsp` is public and
pinned here as a submodule; a clean clone with the sibling core and parser
submodules passes the full provider and black-box stdio suites. Neovim launches
the standalone binary directly, while `clearhead start lsp` is only an
inherited-stdio `exec` compatibility shim. The CLI returned to its 641-line
no-LSP dependency baseline and no longer contains LSP sources, targets, direct
dependencies, or async-runtime symbols.

## Done gate

- `clearhead-lsp` is an independent public repository and platform submodule
- Neovim launches it directly
- CLI builds contain no Tower LSP, Tokio, or DashMap through LSP ownership
- `clearhead start lsp` is removed or is a dependency-free external shim
- LSP provider, protocol, workspace-routing, and mutation tests pass in the new
  repository
- action archival no longer has the completed-file/write-then-editor-edit
  inconsistency window
- documentation names one canonical server command
