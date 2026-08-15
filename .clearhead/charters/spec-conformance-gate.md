---
id: 01a002d1-352f-78f2-8120-039b48d51a69
alias: spec-conformance-gate
parent: platform
objectives:
  - trustworthy-evolution
---
# Specifications Executable Gate

The closed [[executable-assurance]] charter built `scripts/validate-pinned`, which runs every submodule's pre-push gate against the exact pinned composition — but it ends with a placeholder: `specifications has no executable repository gate`. Specifications is the only submodule without one, and it is the load-bearing contract two implementations (Core in Rust, the nvim pure-Lua slice per [[clearhead-client-coupling-via-spec]]) must agree with. This charter gives `specifications/` a real gate and wires it into `validate-pinned`, then closes.

## What is actually missing (investigated 2026-08-14)

Most conformance tooling already exists — this is smaller than it first looked:

- **Roundtrip** is `clearhead format file` (parse → canonical text; compare to source).
- **Diagnostics** is `clearhead lint file`, which already emits codes with `line:col` (e.g. `:16:1: WARN: ... [W002]`).
- **Schema shape** is a plain JSON-Schema validation of the static `examples/` against `schemas/*.schema.json` — an external validator in the gate script, no Core change.

The one genuine Core gap: **there is no parse-to-schema-JSON entrypoint.** `export` only emits iCalendar plans; `OutputMode` is `Table`/`JsonLd`/`Ids`; and Core's `Action` has no serde mapping to the `sample.json` shape (`doDate`/`completedDate`). So `schemas/actions.schema.json` + `sample.json` describe a serialization **no code emits** — a declared contract without an emitter.

## Discovered drift (the gate justifying itself)

`examples/actions/conformance_test.actions` names its cases `(E012 error)` / `(E013 nudge)`, but `clearhead lint file` emits **`W002` / `W003` warnings**. The oracle-in-prose already disagrees with the implementation, and it is not yet knowable from here whether `linting.md` blesses the E-codes (linter under-implements) or the fixture is stale. **Reconcile this against `specifications/linting.md` before any oracle is authored** — building expected-outputs on unreconciled codes is building on sand.

## Outcomes

1. `specifications/` owns an executable gate (`.githooks/pre-push`) invoked by `validate-pinned` as an eighth `run_gate`, replacing the placeholder echo.
2. The `.actions` example corpus is checked by the gate at the tiers the existing CLI already supports: roundtrip (`format`) and diagnostics (`lint`), plus JSON-Schema validation of the static examples.
3. Diagnostic codes are reconciled between the fixtures, the linter, and `linting.md`, with one canonical source.
4. The conformance corpus is restructured so each scenario is testable as a unit.

## Fixed scope

- `examples/conformance/{parse,diagnostics,archive}/`, one scenario + one oracle per fixture, directory = assertion type. Splitting `conformance_test.actions` is mandatory: it mixes valid parses with error cases, so no single expected-output is expressible over it.
- Oracles are **hand-authored from the spec, never dumped from Core** — a generated `expected.json` makes Core the answer key and inverts the spec→implementation dependency. Diagnostics oracle pins **code + node span, not message text** (wording churns).
- The schema-shaped `expected.json` structural tier is **deferred, not required**: it depends on the missing Core emitter (recorded below). Roundtrip + diagnostics + schema-validation are sufficient for a first honest gate.

## Sidequest recorded (blocks only the structural tier)

Core needs a parse-to-schema-JSON entrypoint that serializes an `ActionList` to the `actions.schema.json` shape (or the shape must be declared unsupported and `sample.json`/the schema retired). Until then the structural `expected.json` comparison cannot run. Promote this from deferred to active only if roundtrip + diagnostics prove too weak to catch a real composition defect.

## Non-goals

- A schema-JSON emitter for its own sake, absent a conformance consumer that needs it.
- Centralizing the corpus in the platform repo — the gate is spec-owned so both implementations kneel to it.
- Pinning human-readable diagnostic message text.

## Done gate

- `validate-pinned` runs a real `specifications` gate instead of the placeholder;
- the example corpus passes roundtrip + diagnostics + schema validation, restructured per scenario;
- the E-vs-W code drift is reconciled to one canonical source;
- the parse-to-schema-JSON gap is recorded with an explicit promotion trigger.
