---
id: 01a0f48f-3fd6-70c5-84c3-18f297a41250
alias: ground-the-ontology
parent: platform
state: Active
---
# Ground the Ontology

Ground ClearHead's entities in what actually exists in the work (objectives, plans, steps, records of what happened), first in plain words and then aligned with BFO and CCO. Spec and implementation follow from the grounded model, never the reverse.

Started 2026-09-30 as "plans all the way down", from a conversation about recording agent attempts. That first proposal began from file formats and asked which CCO class each fit; the human rejected it as the wrong direction. The domain note is [the ontology's V5 design](../../ontology/V5_DESIGN.md); this charter holds only the sequence.

## Done when

- The domain note answers the human's competency questions in plain words and its open threads are settled.
- The domain is aligned with BFO and CCO, with each departure from CCO stated and justified.
- How the spec represents it is decided, and the work that follows is planned as its own charter.
- `ontology/V5_DESIGN.md` is distilled: settled choices in `ontology/docs/DECISIONS.md`, the CCO mapping as an evergreen reference doc, no open threads left in it.

## Sequence

Competency questions, then the domain in plain words, then alignment with BFO and CCO, then the decision on representation. Nothing below the ontology is planned until the alignment holds.

## Log

- 2026-09-30 — Created New, on purpose: nothing is worked until the human has read the design note cold and answered its open questions.
- 2026-09-30 — Renamed from plans-all-the-way-down. The first proposal was withdrawn as implementation-first; the note was rewritten from the human's competency questions; the ontology, spec, Core and naming actions were cancelled in favour of one representation decision.
- 2026-10-01 — Domain grounded on standard terms only (CCO v2.2 + IAO action specification); all eight competency questions answer under the ROBOT gate. Ontology Decisions 1-6, platform Decision 42; ontology d141a85. Left: distill V5_DESIGN.md, then decide spec representation.
- 2026-10-01 — Charter Active. V5_DESIGN.md distilled into ontology docs/domain.md and retired; README and agent guides describe V5 (ontology b7c438a). Representation decision queued for the human with a recommendation (V5 directly), plus two related choices: what plus-tags mean, and the root objective. Found: Core, the CLI and the for-human query still use v4; the ROBOT gate does not check competency answers; the move action would have carried v4 meaning into the spec, so it now waits on the decision.
