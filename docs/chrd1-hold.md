# Run chrd1 is held: =chst-reader

**What it is.** Run chrd1 (workflow review-cycle, agent run 20261107-180153) did `=chst-reader`, the first of the
three runs that replaced chst1: the named-template reader now returns the parser's own record of which steps had a
written `#uuid`, and `habit-id-missing` covers template steps. Nothing has landed.

**Where it stands.** Its bounded loop ended after three reviews at "land after fixes", so the stop rule holds it for
you (workflows README, Deciding). Unlike chst1, it converged:

- The code has not changed since review 1, and all three reviews found it sound and in scope. The 6 named tests pass.
- Review 1's one should-fix (the CLI reader tests were never run red) was resolved in round 2 by a recorded red run of
  the Core lint tests at the test-only commit. The reader tests could not have compiled before the fix.
- What is left is bookkeeping, not a shared cause: the red-run record went into a new Core doc
  (`clearhead-core/docs/habit-template-ids-red-evidence.md`) instead of the action's completion note, and the
  completion note is still missing.
- The third finding (doctor drops line numbers and severities for template-file lint findings) predates this branch.
  I filed it as `=template-lint-findings`.

**What's left before landing.** Move the red-run record into `=chst-reader`'s completion note, drop the Core doc, and
run `scripts/gate.sh` in a writable checkout. No reviewer has seen the gate pass; only the worker's commit says it did.

**One thing you might weigh.** Every `templates/*.actions` step without an id now warns in `doctor`, not only templates
a Habit names. That is how I read linting.md ("missing ... template-step ids ... are reported"). It costs nothing
today: none of your workspaces has a templates folder.

**The choice.**

- **Push back once** with the two bookkeeping edits. It costs one fix and one review (about $0.40 for the review), and
  everything that lands has been reviewed. This is my recommendation.
- **Override and land**, then I make the edits in a follow-up Core commit. No spend, but the doc goes into Core's
  history and comes straight back out, and the follow-up is not reviewed.
- **Stop.** I see no reason to.
