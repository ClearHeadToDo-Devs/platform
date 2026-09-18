---
type: Runbook
title: Crate merge and charter identity — long-running build plan
description: Invariants, ordered steps, gates and stop conditions for collapsing clearhead-rs to two crates and one binary, and for splitting charter document identity from domain identity. Decided 2026-09-18.
status: draft
generated: { by: agent/claude, at: 2026-09-18T18:00:00Z }
sources:
  - id: decisions
    resource: DECISIONS.md
    title: Decisions 39 and 40 (the why)
  - id: merge-action
    resource: ../.clearhead/charters/pure-core-split.actions
    title: crate merge and LSP fold-in actions
  - id: identity-actions
    resource: ../.clearhead/charters/support.actions
    title: charter identity parent action and its three children
  - id: spec
    resource: ../specifications/workspace.md
    title: Concept Identity (the rule this implements)
---

# Crate merge and charter identity

The *why* lives in [Decisions 39 and 40](DECISIONS.md). This document is the
*how*: the invariants that must hold when each step lands, the order, and when
to stop. Task state lives in the actions named in `sources`, not here.

## Invariants

Each is written to be checkable. "Enforced by" says what fails when it breaks;
an invariant with no enforcer yet is a step in the plan below, not an aspiration.

| # | Invariant | Enforced by |
|---|-----------|-------------|
| I1 | **Core is pure.** No clock, RNG, filesystem or environment call on `clearhead_core`'s portable path (`cfg(test)` excluded). Ids, times and bytes enter as arguments. | wasm dependency gate (crates) plus a call-site test with an allowlist that only shrinks (step 1) |
| I2 | **Two identities, one boundary.** A charter *document* has an optional id; the *domain* `Charter` has a required one. Strictness increases only at the conversion, which takes the id as an argument. | types (`Option<Uuid>` vs `Uuid`); parse determinism test |
| I3 | **Resolution order.** Frontmatter `id`, then sidecar `charter.id`, then the shell-supplied ephemeral id. Never derived from a title or path. | assembly test per branch |
| I4 | **Reads never write.** Load, query, lint, doctor, orient and every other read path leave the disk untouched. | test that snapshots the tree around each read verb |
| I5 | **Stamping is deliberate.** Only `normalize` and creation of a whole new document write a charter id. No other verb stamps as a side effect. | test: run each write verb on an id-less charter, assert no id appears |
| I6 | **One read, one revision.** A verb's new text is derived from the same read that captured the revision its write is checked against. | test: a change landing between read and write yields a conflict for `update`, `close` and `jot` |
| I7 | **Conflict is data.** A lost compare-and-swap surfaces as `VerbError::Conflict`, never a string. | existing (`2aea96a`) |
| I8 | **Two crates.** `clearhead_core` never depends on the effectful crate. Inside the effectful crate, frontends (cli, lsp, mcp) depend on the runtime, never on each other; internals are `pub(crate)` unless deliberately exported. | crate graph check plus an import-direction test |
| I9 | **stdout belongs to the protocol.** In `mcp` mode only the transport writes stdout. Command functions split `build()` (pure data) from `run()` (prints); MCP calls only `build()`. | test that runs the server and asserts stdout carries protocol frames only |
| I10 | **The minimal build stays minimal.** `--no-default-features` pulls neither oxigraph nor rmcp; `mcp` implies `sparql`. | extend the existing oxigraph-leak check to rmcp |
| I11 | **Additive ordering** (carried over from direct-delivery): mutations emit additive effects before removals. | existing, in core emission |
| I12 | **Persisted identity is declared identity.** Nothing persists an ephemeral id. Archival names files `{id}.actions`, `{id}.md`, `{id}.completed.actions` and stamps the crystallized sidecar from the charter id, so archiving an id-less charter must refuse and point at `normalize`. Found 2026-09-18 by an LSP references query on `MarkdownCharter.id` (about 45 uses; archive is the heaviest consumer). | test: archive an id-less charter, assert an error and no files written |

## Order of work

Each step ends on the gate below and a checkpoint. Do not start a step whose
predecessor is not merged and pushed.

0. **Spec first.** Add one implementation-agnostic paragraph to
   `specifications/workspace.md` (Concept Identity, charter row): a document
   that declares no `id` is a reportable gap; a read never persists an
   identity; `normalize` is the stamping pass. The spec is the authority, so
   it leads. Needs the user's go-ahead to push the submodule.
1. **Identity types** — child 1 of the identity parent action, which now
   follows the pure-core source gate action (`01a0b5d0-da21`: Decision 38 cites
   `scripts/pure-core-source-gate.sh` but it does not exist, and it is the I1
   enforcer). The gate action owns the audit below; child 1 lands I2 and I3.
   The audit: grep `clearhead-core/src` for `now_v7`, `new_v4`,
   `SystemTime::now`, `Instant::now`, `Local::now` and `Utc::now`, classify
   each as test-only or portable-path, and commit the classified list as the
   I1 allowlist. Known portable-path suspects: `Workspace::from_parts`
   (`workspace/store/load.rs`) and `parse_charter`. Then land I2 and I3.
2. **Crate merge** — the `pure-core-split` merge action, in three commits so
   each is reviewable and bisectable:
   a. Move `clearhead-workspace-fs` into the CLI crate as a module tree.
   b. Move the LSP source in as a module tree. **It must move in the same
      step**: `clearhead-lsp` depends on `workspace-fs` today, so merging the
      others first would make the LSP depend on the CLI crate, backwards.
      Keep `clearhead-lsp` as a second `[[bin]]` target of the same crate so
      the nvim plugin's `cmd` does not break yet.
   c. Turn `mod commands` from bin-private into library modules behind
      `pub(crate)`, leaving `main.rs` a thin dispatcher, then add the I8
      import-direction test.
   Also update every consumer of the old names: `.githooks/pre-push`,
   `.github/workflows/ci.yml`, `scripts/wasm-dependency-gate.sh`, both READMEs,
   the workspace `Cargo.toml` description, and the `platform` submodule pin.
   Crate name stays `clearhead_cli`, binary `clearhead` (open: rename later,
   it is a separate decision and not needed for this).
3. **Verbs edit text** — child 2 of the identity parent (I5, I6). After the
   merge so the edits are not rewritten after a move.
4. **`normalize` stamps ids; lint text points at it** — child 3. Also land I12: archive refuses an id-less charter (own action, after child 1).
5. **`mcp-scaffold`** — `clearhead mcp` as a subcommand behind an `mcp`
   feature implying `sparql` (I9, I10). Read-only tools first (`orient`,
   `show`, `query_named`) plus the three resources; `capture` and `transact`
   wait on the CAS work already landed plus step 3. Splitting `show` needs an
   agent-facing schema decision: stop and ask before choosing one.
6. **LSP binary retirement** — the later fold-in action: `clearhead lsp`
   subcommand, retire the second `[[bin]]`, migrate the nvim `cmd`. Carries the
   unsaved-buffer versus on-disk question for sparql.
7. **The review nits** — the small tidy action, any time after step 3.

## Gate (every step, before every push)

The versioned gate script from the process-friction action once it exists;
until then, the full sequence from the overnight runbook: `cargo fmt --all
--check`; `cargo clippy --workspace --all-targets --no-deps -- -D warnings`;
`cargo test --workspace --quiet`; `cargo check` of both crates with
`--no-default-features`; the oxigraph-leak check; `sh
scripts/wasm-dependency-gate.sh`; then `clearhead doctor` in `platform`.
Never `--no-verify`. One retry for a failure that passes in isolation, then stop.

## Stop conditions

Stop the step, write the question at the top of the action's description as a
`NEEDS DECISION` line, and move on, when:

- an invariant above would have to be weakened to make the step work;
- a change is needed in a repo outside `clearhead-core`, `specifications` or
  `platform` (`clearhead.nvim`, the grammar) other than the nvim `cmd` in step 6;
- a public type or verb-output schema must change shape (agent-facing schemas
  are the user's call);
- the I1 audit finds a portable-path clock or RNG use that is not the two
  suspects, since that changes the size of step 1.

## Working protocol

Navigate code with the shared read-only language server ([Decision 41](DECISIONS.md)),
not `sed` and `grep`: use the compact views, and grep only for text. Batch
independent tool calls in one turn.

Use the `clearhead` CLI for every action and charter mutation, never a raw
edit. Write each resolution into the action's description before completing it
(what was found, decided, changed, which commit). Record a belief in the agent
workspace after each step, citing the changed files, and checkpoint at the
end of each step. Leave the report in the actions and the charter `## Log`.
