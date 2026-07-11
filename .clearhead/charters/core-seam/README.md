---
alias: core-seam
state: New
description: Re-route the CLI through the machinery core already built — one write path, one reference resolver, one config, one error strategy — deleting the parallel implementations the command layer grew instead
---

# Core Seam

The 2026-07-02 architecture review found a single recurring failure mode: **the
CLI command layer stopped calling core**. Core grew real machinery — atomic writes with crash recovery, a spec-complete reference resolver, a semantic `WorkspaceConfig` — and the commands kept (or re-grew) their own weaker copies beside it. Every finding below is an instance of that one gap.

## Why this charter exists

The likely history: most command handlers predate core's workspace-store and
durability work, and nothing forced a call-site sweep when the new capability
landed. [[write-durability]] is the proof — it closed with "route all
production writes through the primitive" checked off, but its scope only named
*core's* write sites. The CLI's own `save_file` (the path every `complete`,
`update`, `cancel`, and `delete` takes) still calls naive `std::fs::write`.
The crash-safety layer exists, is tested, and is bypassed by the most common
writes in the system.

The same shape repeats for reference resolution (three resolvers, and the one
used by mutating commands violates the spec's resolution order — alias no
longer beats name-contains), configuration (tag-hierarchy methods duplicated
verbatim in `environment_reader::Config`, tests included), and error handling
(125 `Result<_, String>` sites re-stringifying errors core already types).

## The disciplines

1. **One write path** — workspace data reaches disk only through core's
   `durability::atomic_write` (via `write_actions` or an equivalent). This
   finishes what [[write-durability]] started.
2. **One resolver** — a reference means the same thing in every command; the
   spec's resolution order (UUID → short UUID → alias → name) is enforced by a
   single implementation.
3. **One home for domain semantics** — what "complete an action" *means*
   (close the subtree, stamp timestamps, move to the completed file) is core's
   knowledge, not a command handler's.
4. **No compat shims for consumers that don't exist** — this codebase has one
   consumer. Backward-compat layers are pure carrying cost; sweep call sites
   and delete.

## Process guard

The lesson worth keeping after the code is fixed: **a core capability is not
done until the CLI call sites are swept onto it.** Charters that add machinery
to core should carry an explicit sweep action for the CLI (and a regression
guard where feasible) as part of their done-gate.

## Scope boundary

This charter re-plumbs existing behavior; it adds none. The CRDT/sync modules
stay as they are (Decision 19 makes them a deliberate bet — parking or keeping
them is a separate conversation). The `Action`-vs-`DomainModel` intermediary
stays (already evaluated and kept, see clearhead-core charter log).

## Done when

1. No `std::fs::write` of workspace data remains under `clearhead-cli/src/commands`
   (user-directed output like `write_or_print` and one-time `init` bootstrap are
   exempt), and a guard prevents the seam reopening.
2. `act_matches` / `find_act_mut` and `mutations::resolve_reference` are gone;
   mutating commands resolve through the single resolver and an
   alias-beats-name regression test passes at the new seam.
3. Subtree-close semantics live in core; `complete_action` and `cancel_action`
   are thin callers of the same function.
4. `environment_reader::Config` contains no duplicated `WorkspaceConfig` logic.
5. The dead-code inventory (see actions) is deleted and `cargo build` is
   warning-clean without `#[allow(dead_code)]` in the swept files.
