---
id: 019fcb1b-cf35-7500-941d-bb333dd1b9e1
alias: tech-debt
parent: platform
---
# Technical Debt

## Complexity review — 2026-08-05

The review measured the five files named by the complexity action after the reference-resolution, calendar-serialization, archive, and Core-boundary seams had stabilized. Raw file size overstated three candidates because their unit tests live beside the implementation:

| Module | Total lines | Production | In-file tests |
| --- | ---: | ---: | ---: |
| Core `calendar/reconcile.rs` | 1,625 | 1,236 | 389 |
| CLI `commands/action.rs` | 1,331 | 1,228 | 103 |
| Core `archive_charter.rs` | 1,221 | 606 | 615 |
| Core `calendar/ics.rs` | 1,232 | 784 | 448 |
| graphd `graph/insert.rs` | 1,155 | 655 | 500 |

Strict Clippy with `clippy::cognitive_complexity` enabled found no function over its threshold in any of these modules. The large files are concentrations of related policy and tests, not presently evidence of tangled control flow.

### Decisions

- **Keep calendar reconciliation cohesive for now.** It contains distinct pure merge, vdir discovery, application, occurrence-materialization, and roll-forward phases, but they share one lock, merge-base store, and load-bearing write order. The materialized-occurrence write lane (`resolve_materialized_occurrence` through token/template stamping) is the strongest future extraction candidate. Extract it only while implementing archived Plan lineage, when the new semantic edge can give that module an independent contract and tests.
- **Keep CLI action commands together.** Individual command functions remain below the cognitive threshold. Materialized actions deliberately win over recurring-occurrence fallbacks, and each verb supports a different subset of occurrence operations; replacing those adapters with a generic target resolver now would blur policy rather than centralize it. A read-only submodule becomes worthwhile only if its collection/presentation path gains another consumer with shared acceptance tests.
- **Do not split charter archival by file size.** Half the file is regression coverage. `archive_many` is long, but it is one transaction planner/executor whose ordering preserves preconditions, crystallization side effects, journaling, and directory cleanup. Archived Plan lineage may justify a small crystallization-plan type; it does not justify moving helpers today.
- **Keep iCalendar parsing and rendering together.** The production surface is a focused RFC 5545 adapter: Plan masters, recurrence deviations, standalone Action projections, and canonical serialization. Its small parsing similarities are not separate ownership seams.
- **Keep graph insertion explicit.** Charter, Plan, Action, workspace, and context projection functions are independently bounded. Their repetitive triples make ontology mappings auditable; a generic emitter would save lines while hiding schema intent.

### Follow-up threshold

Revisit an extraction when a feature introduces a second consumer, a function crosses the cognitive-complexity threshold, transaction ordering becomes hard to test, or archived lineage establishes a genuinely independent occurrence crystallization contract. Do not move in-file tests merely to reduce headline line counts.

The review also exposed one unrelated concrete dependency issue: the CLI's stale `build.rs` still generates an unused `mybin.1` from a dummy Clap command, forcing duplicate build-only `clap` and `clap_mangen` dependencies. That cleanup belongs under the existing dependency-audit action rather than this complexity work.

## Dependency ownership review — 2026-08-05

A dependency is a capability and obligation imposed on every downstream computer, not merely a line in a manifest. The audit therefore asks which layer owns each capability, whether it is needed in normal operation or only by maintainers/tests, and which transitive code that choice forces on consumers.

### Findings and changes

- **Core:** `cargo machete` found no unused direct dependency. The apparent `tempfile` candidate is production-owned by the atomic durability writer, not test scaffolding. Calendar, configuration, parser, formatting, telemetry, and persistence dependencies all have production call sites consistent with Core's adopted boundary.
- **CLI:** neither the CLI nor graphd directly depends on Tokio. The stale `build.rs` generated an unused `mybin.1`; it and its duplicate build-only Clap dependencies were removed. The real manpage skeleton generator is maintainer tooling, so it moved from an automatically installed binary to an example and `clap_mangen` moved from normal to dev dependencies. End-user installations now build and install only the `clearhead` binary.
- **graphd:** graphd uses only Oxigraph's in-memory `Store::new`, but Oxigraph's default feature compiled RocksDB, bindgen, Clang discovery, and a native C++ build. Disabling that default removed RocksDB and 11 other lockfile package entries. Direct `serde` and the duplicate dev-only `chrono` declaration were also unnecessary and removed.
- **LSP:** the LSP is the correct owner of an async runtime, but Tokio's `full` feature falsely claimed network, process, signal, filesystem, timer, and parking-lot capabilities. Restricting it to stdio, macros, multithreaded task execution, and synchronization removed `mio`, `parking_lot`, `signal-hook-registry`, and `socket2` from its lockfile.
- **Client Chrono use:** CLI, graphd, and LSP use Chrono values but do not serialize their own date types. Their direct dependencies no longer request Chrono's Serde feature; Core remains its legitimate owner for persisted domain data.

### Remaining boundary

Core's canonical formatter is the one unresolved dependency seam. Topiary is used only by the formatting adapter, but brings Tokio's runtime and macro crates through Core into every consumer. CLI and LSP need formatting; read-only graphd does not. This is now tracked as an explicit capability-boundary action rather than solved by casually moving code or disabling a required dependency. The end state must let graphd build without Topiary or Tokio while preserving one canonical formatter for clients that opt into it.
