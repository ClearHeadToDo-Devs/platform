---
id: 01a0f48f-3fd6-70c5-84c3-18f297a41250
alias: plans-all-the-way-down
parent: platform
state: New
---
# Plans All the Way Down

Realign ClearHead's entities with the Common Core Ontologies: objectives, plans at every scale, and recurring plans, with what actually happened recorded as acts by whoever acted.

Started 2026-09-30, from a conversation about recording agent attempts: reading CUBRC's CCO modeling guide against the current CCO showed that our vocabulary narrows `cco:Plan` to recurrence, keeps `actions:Action` beside Plan instead of as one, and runs charter states as a second state machine. The full analysis, the proposed mapping and the open questions are in [the ontology's V5 design proposal](../../ontology/V5_DESIGN.md); this charter holds only the sequence.

## Done when

- The ontology, the spec (released as v0.2.0) and Core all speak the v5 model: every action and charter is a Plan, one status scale covers both, and the recurring plan has its decided name.
- Existing workspaces migrate without losing identity or history, and doctor explains any old state field it meets.
- File formats are unchanged unless an open question decides otherwise.

## Sequence

Meaning first, names last: settle the questions, then ontology, spec, Core and CLI, and only then decide whether user-facing words change. Each layer lands and is checked before the next starts.

## Log

- 2026-09-30 — Created New, on purpose: nothing is worked until the human has read the design note cold and answered its open questions.
