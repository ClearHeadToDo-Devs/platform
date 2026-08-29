---
id: 01a04a9a-b542-7033-9eee-d9ed347d8de0
alias: state-governance
parent: platform
state: Active
---
# State-Governed Work Selection

Make “what can I work on next?” a trustworthy projection of explicit workspace
state rather than prose priority, hidden focus, or competing query conventions.

## Semantic contract

- Charter state governs admission of a work stream: `New` is defined but not
  admitted, `Active` is eligible for engagement, `Blocked` cannot currently
  advance, and `Closed`/`Cancelled` are terminal.
- Action state governs execution of one concrete act. `InProgress` means work is
  presently underway; it is not another spelling of charter `Active`.
- `Ready` is derived rather than stored: a `NotStarted` Action is ready only when
  its owning Charter and every ancestor Charter are `Active`, its predecessors
  are satisfied, and applicable schedule/context constraints permit it.
- States remain local facts and never cascade implicitly. Effective eligibility
  is inherited through Charter ancestry.
- Cross-level contradictions are diagnosed, not silently normalized. Active
  descendants or InProgress Actions beneath New/Blocked ancestry are warnings;
  open descendants beneath terminal ancestry are violations.
- An Active Charter with no Actions is valid.

## Scope

This is primarily a process and query-semantics charter. Keep implementation
thin: repair the existing query surfaces, encode omitted Charter state as `New`
in semantic projections, apply ancestry-aware eligibility, and expose shared
workspace-coherence findings through doctor and LSP. Do not introduce focus
pointers, ambient session state, automatic lifecycle cascades, or a stored Ready
state.

The normative workflow belongs in `specifications/process.md`, with concise
field semantics in `specifications/charters.md`. CLI and LSP documentation should
link to that authority and describe only their presentation and remediation
behavior.

## Rollout constraint

Existing Charters commonly omit state, which currently means `New`. Populate and
review intended Active Charters before making Active ancestry a hard filter, so a
semantically correct implementation does not silently empty the working queue.

## Log

- **2026-08-28 — Candidate range semantics for Action dates.** Reframe
  `scheduled_at` / `@` as the lower bound and `due_at` / `:` as the upper bound
  of an Action's feasible execution range. A descendant's effective range is the
  intersection of its local range with every ancestor range: latest start and
  earliest due date. Missing child bounds therefore inherit naturally; explicit
  child bounds may narrow the containing range. A local bound outside its
  ancestor range remains visible and receives a coherence warning, while an
  empty intersection is a semantic violation. Queries operate on the effective
  range, but tools never write derived bounds back into source without an
  explicit materializing fix. This is a design finding, not yet a normative
  decision; it would sharpen the current meaning of `@` and must be specified in
  the Action format and process rather than hidden in agenda SPARQL.
- **2026-08-28 — Open priority constraint question.** Explore whether priority
  should compose down Action ancestry similarly. The promising algebra is the
  minimum numeric priority over self and ancestors: a priority-1 parent makes
  every executable descendant effectively priority 1, while a priority-1 child
  may tighten a priority-3 parent's baseline without mutating the parent. A
  locally weaker child priority remains visible and may warrant a warning.
  Settle the semantic reading and diagnostics before encoding it in queries.
- **2026-08-28 — Context composition remains unresolved.** Structural context
  inheritance from parent Actions, and potentially explicit Charter defaults,
  could eliminate repeated tags such as `computer`. Before adopting it, define
  whether multiple contexts are conjunctive requirements or alternative
  classifications and whether a local child set replaces or adds to ancestor
  constraints. Do not conflate structural composition with the existing context
  taxonomy, where a narrow tag such as `neovim` implies broader tags such as
  `terminal` and `computer`.
- **2026-08-28 — Effective values are read-model derivations.** Keep source files
  and the canonical domain model faithful to locally asserted facts and
  containment. Define constraint composition normatively in the process/query
  specifications, but derive effective ranges, priorities, contexts, readiness,
  and their provenance in portable queries. CLI and LSP should present those
  results and offer explicit materializing fixes rather than independently
  implementing or persisting inherited values.
- **2026-08-28 — SPARQL is a provisional reasoning boundary.** The desired
  capability is closer to Datalog with recursion, stratified negation,
  aggregates, temporal comparison, and derivation provenance than to ordinary
  OWL classification. Until a FOSS, deterministic, embeddable, local-first and
  preferably WASM-capable engine is practical, centralize these policies as
  declarative SPARQL rather than scattering imperative inference across Core,
  CLI, and LSP. Any future derived or findings graph remains a replaceable
  projection, never workspace authority.
