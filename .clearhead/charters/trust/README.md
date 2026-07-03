---
alias: trust
state: New
description: The boring machinery that makes files-as-truth survivable for a decade — round-trip invariants, undo, workspace fsck, and the standing decisions (versioning, timezones, concurrency, benchmarks, CI) that must be made once and recorded
---

# Trust

The platform's pitch is not features — it is *"this data will still be yours,
intact, in twenty years."* The capability charters (queries, views, federation,
agents) all assume that promise; nothing currently enforces it. This charter is
the enforcement: the safety net around the write path that [[core-seam]]
repairs, and the standing decisions that keep the promise load-bearing as the
system evolves.

The organizing observation from the 2026-07 review: every gap found — the
formatter silently dropping context tags, mutations bypassing the durability
layer, fuzzy matching completing the wrong action, syntax errors making a
charter's actions invisible — is a **trust gap**, not a capability gap. And
files-as-truth makes most of the remedies unusually cheap: git is a free time
machine, a grammar is a free fuzz target, plaintext is a free audit surface.

## The three build items

1. **Round-trip property tests** — every mutation command is read → parse →
   mutate → format → write, so `parse(format(x)) == x` and formatter
   idempotency are the platform's real safety contract. Snapshot tests check
   known examples; only generated inputs catch the unknown ones. The multi-tag
   data-loss bug (found by dogfooding, 2026-07-02) is the class of bug this
   converts from "hope" to "CI-enforced invariant."
2. **Undo** — destructive commands rewrite truth immediately, and the resolver
   bug proved fuzzy matching can pick the wrong target. Wrong action + no undo
   is the trust-destroying event. Leverage git: snapshot before mutation,
   `clearhead undo` restores. Databases have to build time machines; files get
   one free.
3. **`clearhead doctor`** — the workspace has grown cross-file invariants that
   nothing checks holistically: sidecar ↔ actions coherence, duplicate UUIDs
   (copy-pasted lines), dangling parents/predecessors, orphaned `.ics`, stale
   `.pending` journals, alias collisions, unparseable files silently dropping
   out of loads. A read-only fsck is the transparency value applied to the
   system itself.

## The standing decisions

Five decisions that need to be *made once and recorded*, not built:

- **format versioning** — the files intend to outlive the tooling; what reads
  a 2025 file in 2031, and what compatibility does the spec promise?
- **timezone discipline** — `chrono::Local` everywhere is now intersecting
  RRULE expansion and ICS; the DST/travel bug farm needs one deliberate rule
  before the calendar work bakes in an accident.
- **same-machine concurrency** — the conflict hit weekly is not device sync,
  it is nvim holding a stale buffer while the CLI mutates underneath; the
  advisory lock has no editor party to it.
- **performance trigger** — every query cold-builds the full graph; fine
  today, a cliff later. No benches exist in either crate, so the daemon
  decision currently has no data. Benchmark first; let the numbers promote
  the LSP-as-resident-daemon shift.
- **integration CI** — the platform repo's only workflow deploys the
  vocabulary site; nothing runs the full stack (grammar → core → CLI → nvim)
  against the pinned submodule SHAs, so the repo *records* integration
  without *verifying* it.

## Done when

1. The round-trip property suite runs in CI for core and would have caught
   the multi-tag bug (regression case included in the generator's coverage).
2. `clearhead undo` restores the workspace after any single mutating command.
3. `clearhead doctor` exists, is read-only, and reports every invariant named
   above with scripting-friendly exit codes.
4. All five standing decisions have DECISIONS.md entries — decided is the
   deliverable; implementation may spawn its own work.
