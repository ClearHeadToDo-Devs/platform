---
id: 019fcb1b-cf35-7500-941d-bb333dd1b9e1
alias: tech-debt
parent: platform
---
# Technical Debt

## Complexity review — 2026-08-05

The review measured the five files named by the complexity action after the
reference-resolution, calendar-serialization, archive, and Core-boundary seams
had stabilized. Raw file size overstated three candidates because their unit
tests live beside the implementation:

| Module | Total lines | Production | In-file tests |
| --- | ---: | ---: | ---: |
| Core `calendar/reconcile.rs` | 1,625 | 1,236 | 389 |
| CLI `commands/action.rs` | 1,331 | 1,228 | 103 |
| Core `archive_charter.rs` | 1,221 | 606 | 615 |
| Core `calendar/ics.rs` | 1,232 | 784 | 448 |
| graphd `graph/insert.rs` | 1,155 | 655 | 500 |

Strict Clippy with `clippy::cognitive_complexity` enabled found no function over
its threshold in any of these modules. The large files are concentrations of
related policy and tests, not presently evidence of tangled control flow.

### Decisions

- **Keep calendar reconciliation cohesive for now.** It contains distinct pure
  merge, vdir discovery, application, occurrence-materialization, and
  roll-forward phases, but they share one lock, merge-base store, and
  load-bearing write order. The materialized-occurrence write lane
  (`resolve_materialized_occurrence` through token/template stamping) is the
  strongest future extraction candidate. Extract it only while implementing
  archived Plan lineage, when the new semantic edge can give that module an
  independent contract and tests.
- **Keep CLI action commands together.** Individual command functions remain
  below the cognitive threshold. Materialized actions deliberately win over
  recurring-occurrence fallbacks, and each verb supports a different subset of
  occurrence operations; replacing those adapters with a generic target
  resolver now would blur policy rather than centralize it. A read-only
  submodule becomes worthwhile only if its collection/presentation path gains
  another consumer with shared acceptance tests.
- **Do not split charter archival by file size.** Half the file is regression
  coverage. `archive_many` is long, but it is one transaction planner/executor
  whose ordering preserves preconditions, crystallization side effects,
  journaling, and directory cleanup. Archived Plan lineage may justify a small
  crystallization-plan type; it does not justify moving helpers today.
- **Keep iCalendar parsing and rendering together.** The production surface is
  a focused RFC 5545 adapter: Plan masters, recurrence deviations, standalone
  Action projections, and canonical serialization. Its small parsing
  similarities are not separate ownership seams.
- **Keep graph insertion explicit.** Charter, Plan, Action, workspace, and
  context projection functions are independently bounded. Their repetitive
  triples make ontology mappings auditable; a generic emitter would save lines
  while hiding schema intent.

### Follow-up threshold

Revisit an extraction when a feature introduces a second consumer, a function
crosses the cognitive-complexity threshold, transaction ordering becomes hard
to test, or archived lineage establishes a genuinely independent occurrence
crystallization contract. Do not move in-file tests merely to reduce headline
line counts.

The review also exposed one unrelated concrete dependency issue: the CLI's
stale `build.rs` still generates an unused `mybin.1` from a dummy Clap command,
forcing duplicate build-only `clap` and `clap_mangen` dependencies. That cleanup
belongs under the existing dependency-audit action rather than this complexity
work.
