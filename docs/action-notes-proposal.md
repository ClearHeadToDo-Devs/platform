---
type: Proposal
title: Notes on Actions, Kept in the Charter's Sidecar
description: Draft for =action-notes. Dated notes appended to an action as data in its charter's JSON sidecar, so the description stays one unified text; and whether the charter log moves there too. Checked against specification v0.5.0 and Core bd66ca5 (v0.4.0 and 9 commits).
status: answered
date: 2026-11-06
sources:
  - DECISIONS.md
  - ../specifications/workspace.md
  - ../specifications/charters.md
  - ../specifications/ontology.md
  - ../specifications/schemas/charter_metadata.schema.json
  - ../clearhead-core/crates/clearhead-core/src/workspace/sidecar.rs
  - ../clearhead-core/crates/clearhead-core/src/workspace/store/doctor.rs
---

# Notes on actions, kept in the charter's sidecar

Drafted by the steward for Darrion's approval. Nothing here changes the specification until Darrion answers
[the questions](#questions) and approves; the specification change then follows in one reviewed cycle.

## Why

An action's description is meant to say what and why. In practice it also collects history: the facilitator counted
49 of 282 open descriptions across the repos carrying dated UPDATE, AMENDED or ANSWERED additions, about a quarter of
all description text (2026-11-06). Writers also hit a wall: run chst1's worker could not record its commits on an
action that was already closed, because editing the line is a mutation and a closed action refuses it.

Darrion, 2026-11-06: notes go in the charter's JSON sidecar, so they are easy to find and append to. That extends
the sidecar [Decision 24](DECISIONS.md#decision-24-json-sidecar) introduced and `workspace.md` already places
(`charters/.<charter>.json`, the root's `charters/.next.json`); no new file.

## The proposal

1. **A note is `{at, by, text}`.** `at` is an ISO 8601 date-time with its UTC offset, as charter log entries are
   (`charters.md`, Log). `by` names the writer in the convention the docs' front matter uses: `human:Darrion`,
   `agent:<role>` (`agent:clearhead-steward`, `agent:facilitator`). `text` is plain text.
2. **Notes are keyed by the entity's UUID** and kept in the sidecar of the charter whose file holds the line. The
   shape is [question 1](#questions).
3. **Appending is not a mutation of the action.** It works on any state, closed and archived included, and never
   touches the `.actions` line, so it cannot fail with already-closed and cannot disturb the description.
4. **Notes survive moves, and are never tidied away.** Core already reads the union of every sidecar keyed by UUID,
   so an entry reaches its action wherever the line now lives (`sidecar.rs`, `hydrate_actions_map`). What would lose
   notes today is `doctor --fix`: it prunes an entry whose action is not in that sidecar's own charter
   (`sidecar-orphan`, `PruneSidecarEntry`), which is exactly a moved action. The specification will say: an entry
   whose action lives in another charter is relocated to that charter's sidecar, not pruned; an entry with notes
   whose action exists nowhere is reported and kept.
5. **An append never loses another.** Sidecars are written by atomic replace, but read-modify-write is unlocked, so
   two writers appending at once can drop one note. The specification will require appends to be serialized (a lock
   or compare-and-retry); the mechanism is Core's.
6. **Notes are in the graph.** Each note is a blank node (Decision 49) on its entity: `app:note [ rdf:value "…";
   dcterms:created "…"^^xsd:dateTime; dcterms:creator "…" ]`. The terms are a sketch for `ontology.md`'s review.
7. **Reading them.** `clearhead show` lists an action's notes, newest last; the LSP offers them on hover; the
   editors bind a key to show or add one. Appending is one CLI verb, [question 3](#questions).
8. **Existing descriptions are not migrated automatically.** Dated additions can be split out by hand, or by a
   one-off script Darrion reviews, when it is worth it.

## What it costs

- **Notes leave the text.** Decision 24 made the sidecar a hidden file for data "we dont want to bother the humans
  with", while notes are written for people to read. In a plain editor or on GitHub, an action's notes are not
  visible next to it; seeing them takes the CLI, the LSP or the editor plugins. That is the price of keeping the
  description whole.
- **Merges.** Two branches appending to the same action conflict at the end of its array. Editing the description
  on two branches conflicts today too, so this is not worse; how often it happens is unmeasured.
- **Every reader and writer of the sidecar learns one more key**, and the schema, doctor, archive (which already
  moves the sidecar whole) and the graph each change once.

## Questions

⏸ Decision, for Darrion:

1. **Shape.** Notes under each entry, `actions.<uuid>.notes: [...]`, beside `created` and `plan`; or one top-level
   map, `notes.<uuid>: [...]`, keyed by any entity's id: an action, a Habit or the charter itself?
2. **The charter log.** Should the charter's `## Log` move into the sidecar as notes on the charter, now, later, or
   not at all? Today it is Markdown anyone can read on GitHub; in the sidecar it is data `jot` appends to.
3. **The verb.** Extend `clearhead jot` (`jot --action <id> <text>` beside today's `--charter`), or add a
   `clearhead note` verb?
4. **Corrections.** Are notes append-only through the tools, so a correction is a new note, or can the tools edit
   and delete them?

## The steward's leanings

Read after answering, to compare.

1. The top-level `notes` map: one shape for every entity, and the charter log needs no second format if it moves.
2. Later, as its own step: land action notes first, then move the log once the hover and hotkeys make it as easy to
   read as the Markdown. Moving it now hides the log before there is a way to see it.
3. Extend `jot`: it is already the append verb, and one verb is easier to remember than two.
4. Append-only through the tools; the JSON stays hand-editable for the rare real mistake.

## Answers

Darrion, 2026-11-09, in facilitator chat:

1. **Shape:** the top-level `notes.<uuid>` map, for any entity. "Standard procedure is to have uniform logging
   structure."
2. **The charter log:** moves to the sidecar as notes on the charter, and this work goes first in priority
   (`=logs-in-sidecar`). Sequencing, treated as how by the facilitator: `show` and the editor hover display sidecar
   notes before any `## Log` is migrated.
3. **The verb:** no new verb. `jot` appends to the sidecar log instead of the Markdown `## Log`, and takes any
   entity's id: a charter, an action or a Habit.
4. **Corrections:** our tools treat notes as an append-only log, and each note is fixed to the instant it was
   written. The JSON can still be edited by hand, and readers must accept that rather than refuse it.
