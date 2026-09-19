---
type: Proposal
title: Consequence-Proportional Assurance
status: proposed
date: 2026-09-19
sources:
  - https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md
  - ../.clearhead/archive/019ff962-cac2-77b2-aa2f-fceea4697c98.md
  - ../.clearhead/charters/support.actions
  - ../clearhead-core/docs/ARCHITECTURE.md
---

# Consequence-Proportional Assurance

## Proposal

ClearHead should adopt the method behind TigerStyle, not its complete rule set:

> Determine what failure costs at a boundary, then require the cheapest evidence that adequately controls that failure.

Safety work has an operating cost. Tests, assertions, abstractions, review procedures, and compatibility layers all become things the project must continue maintaining. Applying maximum rigor everywhere would consume the capacity needed to improve the product. Applying it nowhere would make a plaintext system untrustworthy precisely where users depend on it most.

The proposal is therefore to concentrate strong, executable assurance at boundaries where a defect can silently lose user data, corrupt identity, overwrite concurrent work, or mislead another program. Reversible presentation and exploratory work should remain cheap to change.

This is a proposal for choosing assurance, not a new permanent compliance programme. Task state remains in ClearHead, accepted architecture decisions remain in `docs/DECISIONS.md`, and normative behavior remains in `specifications/`.

## Why this fits ClearHead

TigerBeetle orders its goals as safety, performance, and developer experience because it is foundational financial infrastructure. ClearHead has a different failure model. Its authoritative state is human-readable local plaintext, normally backed by Git, and its continued evolvability matters alongside correctness.

For ClearHead, a useful ordering at a given boundary is:

1. preserve user-authored information and stable identity;
2. prevent unnoticed stale writes and ambiguous mutations;
3. report failure honestly enough that humans and agents can recover;
4. keep interfaces and outputs tractable;
5. avoid assurance machinery whose maintenance cost exceeds the risk it controls.

The final item is not an exception to safety. A system that exhausts its ability to evolve is not sustainable.

## Evidence from the current platform

### The selective approach has already worked

The archived [Establish Executable Assurance charter](../.clearhead/archive/019ff962-cac2-77b2-aa2f-fceea4697c98.md) is the strongest precedent for this proposal. It deliberately bounded its inventory to reference routing, template targeting, and high-risk lifecycle mutations. It rejected aggregate coverage goals and generalized fixture frameworks, and selected properties, mutation testing, fixtures, and end-to-end checks only where each was the cheapest adequate technique.

That work produced concrete results:

- generated Action forests exercised 256 cases each for semantic round trips, formatter idempotence, link boundaries, and subtree-closing locality;
- focused reference mutation analysis went from 18 missed mutants to none in the exercised module;
- generated combinations exposed lost creation dates, malformed-link preservation errors, and an escaped terminal-backslash ambiguity;
- lifecycle testing exposed non-unique post-lock selection, writes during charter dry-run, and lexical path traversal;
- unresolved durability mutants were documented rather than forcing artificial seams merely to improve a score.

This is consequence-proportional assurance in practice: bounded scope, explicit residual risk, and a stopping condition.

### The Core boundary is already guarded well

[`clearhead-core/docs/ARCHITECTURE.md`](../clearhead-core/docs/ARCHITECTURE.md) states the governing rule, “Core decides; adapters observe and deliver.” The code represents writes as effects with resource preconditions and typed conflicts. CI and `clearhead-core/scripts/gate.sh` enforce formatting, strict Clippy, minimal feature builds, dependency capability boundaries, WASM portability, Core purity, and workspace tests.

On 2026-09-19, `cd clearhead-core && sh scripts/gate.sh --fast` passed every included check: formatting, Clippy, Core and CLI no-default builds, exclusion of Oxigraph from the minimal CLI, the WASM dependency gate, and the pure-Core source gate. This records only the fast gate; the test suite was not rerun for this proposal.

At platform level, `scripts/validate-pinned` rejects dirty or gitlink-mismatched submodules and delegates to repository-owned gates. It then runs specification conformance and an RDF interoperability proof over the exact pinned composition. This avoids inventing a second, weaker platform test framework.

### Passing mechanisms did not guarantee a correct operation

The open action “Edit charter documents as text in update, close and jot, with the revision from the same read” in [`.clearhead/charters/support.actions`](../.clearhead/charters/support.actions) records a consequential gap: revision preconditions existed and had tests, but `update charter` and `close charter` derived replacement text from an earlier load and captured the revision through a later read. A concurrent edit between them could therefore be overwritten.

The mechanism was tested; the end-to-end invariant was not. The same file records the proposed corrective evidence: every charter write must derive bytes and revision from one read, and an intervening change must yield a conflict while preserving the newer content.

This is evidence against indiscriminate test volume and for invariant-level tests around complete operations.

### Silent representation loss remains the clearest trust risk

The open “Stop dropping newlines inside an action note” action records a current reproduction: a multi-paragraph description is stored with newline boundaries removed and adjacent words joined. The same loss occurs when hand-written multiline notes are parsed and serialized.

The repository history records related defects:

- multiple context tags were once parsed but silently reduced to the last tag;
- formatter token boundaries produced inconsistent spacing and required a grammar-level correction plus an idempotency property;
- malformed recovered Action source once remained eligible for rewriting until `TrustedDocument` made that impossible;
- charter write paths can discard frontmatter that is not represented by the current model;
- `update action --description` replaces the prior note, forcing callers to reconstruct text before adding a resolution.

These are not independent demands for exhaustive tests. They identify one high-consequence boundary: parsing and rewriting authoritative user text must never discard information silently.

### Structured failure has already improved agent operation

The completed support action “Surface `DeliveryError::Conflict` as a structured `VerbError::Conflict`” records the transition from an opaque string to a typed outcome carrying path, expected revision, and actual revision. That lets an agent or other caller reload and recompute instead of scraping prose.

The same principle applies to malformed input, ambiguity, missing identity, stale state, and partial delivery. Machine consumers need branchable outcomes; human prose remains useful as an explanation, not as the only contract.

### The Neovim surface has a different assurance profile

A 2026-09-19 repository snapshot found approximately 2,761 lines of Lua and five test files in `clearhead.nvim`. `lua/clearhead/init.lua` alone contains 1,054 lines spanning workspace discovery, buffer mappings, command execution, charter operations, formatting, normalization, navigation, and pickers. The plugin CI runs the Busted suite, but the active queue also proposes a sidebar, tree view, quick-add view, priority switching, and charter functionality.

Line and file counts are not quality metrics. They are evidence that the main interactive surface is accumulating responsibilities while its stateful workflows have less executable protection than Core. The appropriate response is not blanket coverage or a hard function-length limit. It is a small set of journey-level contracts before adding more interaction modes.

## Proposed policy

### 1. Classify the boundary, not the file

Before choosing tests or review depth, identify the consequence of failure for the behavior being changed.

#### Tier A — trust-critical boundaries

Examples:

- rewriting authoritative plaintext;
- assigning or preserving identity;
- selecting a mutation target;
- concurrent read–modify–write operations;
- multi-resource movement or deletion;
- external synchronization and format conversion.

Required evidence should normally include:

- an explicit invariant;
- a positive and negative-path check;
- a semantic reload-and-compare assertion where persistence is involved;
- typed failure behavior;
- independent review when the change is unattended or crosses repositories.

Property or mutation testing is appropriate only when the state space makes it cheaper or more discriminating than examples.

#### Tier B — stable contracts

Examples:

- CLI and LSP request/response shapes;
- parser and linter classifications;
- reference resolution;
- query result schemas;
- reusable view models.

Required evidence should normally be a focused contract, conformance, or integration test at the owning boundary. Avoid duplicating the same assertion in every client.

#### Tier C — reversible interaction and presentation

Examples:

- layout, labels, key choices, picker presentation;
- experimental views;
- internal refactors with no semantic change.

Prefer direct exercise, a smoke test for the principal journey, and easy rollback. Promote the behavior to stronger assurance only after it stabilizes or a real failure demonstrates the need.

### 2. Adopt five cross-cutting invariants

#### Preserve or refuse

A read–modify–write path must do one of the following:

1. preserve uninterpreted source information;
2. apply an explicitly documented transformation; or
3. reject the operation without writing.

Parser recovery is useful for diagnosis, but recovered input must not become trusted rewrite input automatically.

#### Derive and guard from the same evidence

Replacement bytes and their expected revision must come from the same read. Delivery checks that revision immediately before writing. A mismatch is a typed conflict, and the intervening content remains untouched.

#### Make failures branchable

Expected operational failures cross process boundaries as typed data. Human messages explain the outcome but do not define it.

#### Bound agent-facing output honestly

Every agent-facing outline, diagnostic collection, reference list, or orientation view has deterministic ordering, an explicit limit, and an omission count or continuation mechanism. Truncation is never silent.

#### Give each rationale one durable owner

A decision is explained once in `docs/DECISIONS.md`; actions hold state and link to it; charter logs record dated findings; specifications own normative behavior; implementation documents describe current internal structure. Repeating the same analysis in several stores is drift, not additional assurance.

### 3. Prefer semantic evidence

For durable mutations, the strongest economical pattern is usually:

1. construct or load representative source;
2. apply the public operation;
3. reload through the normal read path;
4. compare domain meaning and preserved source obligations;
5. separately exercise an invalid, ambiguous, or concurrent case;
6. assert that rejected work left authoritative source unchanged.

Tests should assert membership, identity, ordering, preservation, and failure state—not private helper calls or incidental formatting unless the bytes themselves are the compatibility contract.

### 4. Keep promotion triggers explicit

Do not establish permanent property, fuzz, mutation, or review programmes by default. Promote assurance when one of these occurs:

- a production defect escapes at a trust-critical boundary;
- a second implementation or backend appears;
- a format or identity path gains another owner;
- focused mutation analysis reveals a consequential surviving behavior;
- repeated manual verification demonstrates a stable contract worth automating;
- a component's expansion makes its current smoke coverage unable to protect its principal journeys.

Once the bounded risk is addressed, close the assurance effort and record residual risk.

## Immediate applications

This proposal does not create a parallel backlog. The current queue already contains the right first applications:

1. resolve multiline action-note behavior so a boundary is preserved or rejected, never deleted silently;
2. make charter update, close, and jot derive text and revision from the same read, with a conflict-preserves-newer-content test;
3. add invariant-level review to unattended runs rather than repeating more mechanism checks;
4. establish the single-source knowledge rule to reduce duplicated process work;
5. before expanding `clearhead.nvim` with several new views, protect the small number of workflows on which those views depend and separate responsibilities when touched.

The fifth item should remain bounded. Candidate journeys are: select the correct project or user workspace; open the intended inbox or charter; apply a mutation and surface a typed failure; avoid installing ClearHead mappings in unrelated Markdown; and preserve the distinction between saved workspace state and unsaved editor state.

## Explicit non-goals

This proposal does **not** adopt:

- test-driven development as a universal implementation sequence;
- minimum assertion counts;
- aggregate coverage or mutation-score targets;
- a fixed maximum function length;
- zero dependencies;
- static allocation or bounded internal collections everywhere;
- exhaustive tests for every CLI option or presentation detail;
- a central platform test suite that duplicates repository-owned gates;
- “zero technical debt” as a claim that uncertainty and trade-offs do not exist.

Dependencies and abstractions should continue to be justified by ownership and capability. Function and module size should be treated as design signals, not pass/fail metrics.

## Adoption test

This proposal is successful if, over the next relevant changes:

- no known lossy source transformation remains silent;
- every durable write family has evidence that stale input cannot overwrite newer content;
- agent-facing failures and truncation are machine-detectable;
- Neovim growth is protected by a few stable workflow contracts rather than broad UI snapshots;
- assurance work closes when its stated consequence is controlled;
- contributors spend less time duplicating rationale and maintaining low-value tests.

If applying the proposal increases routine ceremony without making a named failure easier to prevent, detect, or recover from, the application is wrong and should be removed.
