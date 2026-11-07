# chrd1: technical recovery and landing record

## Current state (2026-11-07)

Workflow `chrd1`, agent run `20261107-180153`, implements `=chst-reader`. It is **landed and pushed**: Core `05d4bec`, platform `771daeb`; workflow `chrd1` succeeded. Root review/verdict notes are pushed. The steward owns this technical recovery under meta-analysis `workflows/README.md`, **Deciding**. No answer from Darrion is needed.

Read the actual sessions before continuing:

- Reviews `/2`, `/4`, `/6` found the reader implementation sound and in scope. `/6` accepted the retrospective Core red-run evidence; it requested moving that evidence into the action and removing the dated Core document. The pre-existing doctor source/severity defect has its own action, `=template-lint-findings`.
- A push-back already happened. Writer `/7` made no changes because updating the closed action was refused and its question about reopening timed out.
- Independent Claude review `/8` failed on capacity: **“You've hit your 5-hour limit · resets 10:10pm (UTC)”**, i.e. **22:10 UTC on November 7**. This is not a review approval.

## Verified recovery

The steward tested the writable run checkout directly:

```sh
cargo test --locked --workspace --test habit_template_ids
sh scripts/gate.sh
```

All **six** named tests passed, none filtered; the **complete gate exited 0**, including all workspace tests and three-zone slot tests. Doctor remains **0 violations / 13 existing warnings**.

Bookkeeping is now committed in the existing run, without changing production code:

- Core `0667ab9`: removes `docs/habit-template-ids-red-evidence.md`.
- Platform `8188835`: records the red/green evidence, implementation commits and gate result in `=chst-reader`. The steward explicitly reopened, updated and re-completed the action through the CLI; its note retains the original completion time and candidly records that the CLI reader tests were not originally run red.

## Independent review and export recovery

Native Claude capacity was not the only route. The sandbox shared OAuth store supports `github-copilot/claude-sonnet-5.5`; explicit `AGENT_PI_PROVIDER=github-copilot` dispatch completed independent reviews `/9` and `/11`, both **land**. No Gemini setup or new authentication was needed. The 22:11 UTC capacity fallback is unnecessary.

The first landing attempt correctly refused an untagged specification pin: task-only commit `ac3a369` followed the declared `v0.5.0`. Platform `4eb7992` restored the exact published tag on a named consumer integration branch, preserving specification main/draft history.

A second candidate was stopped after inspection found that harvest still selected writer `/7`'s old bundles: manually committed recovery was visible to review `/9` but absent from the writer export. GPT writer `/10` repaired this in the same run:

- Core **`d954a52`** replaces unpublished `0667ab9` with an appropriate `test(habits)` evidence-relocation commit; their trees are identical. Original test and implementation history is untouched.
- Platform **`b137a76`** records the complete evidence and superseded hashes, moves the Core pin, and retains exact specification `v0.5.0`.
- Full Core and platform gates passed. A stale shared-cache compile-time manifest path was cleared before the final Core run; no test or gate was weakened.
- Independent Copilot Claude review **`/11`** verified the final tree/hash/pins, ran the workspace tests, and returned **land** with no findings. Only the two known read-only `lint_cli` fixture writes failed in its read-only checkout.

## Next step

Completed: harvested writer `/10`, verified exact exported tips `d954a52` / `b137a76`, rebuilt the disposable failed candidate, and retried the existing workflow's `land` step. The unchanged **full platform gate passed**, including Core, grammar, parser-backed nvim (84 successes, zero pending), ontology, DSL/CLI/schema conformance and graph checks. Core's real host pre-push gate also passed. Newer approval/task records were retained. Core, platform and root review/verdict notes are pushed; no duplicate run or override was used.

Continue with the separately reviewed v0.6.0 adoption and lint-reporting increments.

In parallel, specification **v0.6.0** (`8461b8d`) is independently reviewed, tagged and pushed on main/release; all eight public schema URLs return their exact new IDs. The approved normative text and fixtures remain byte-identical to `139f0c9`. Platform remains on the declared v0.5.0 until separate reviewed adoption `=template-recurrence-pins`. `=template-lint-findings` precedes the new lint errors; `=lint-ancestor-dependency`, on-demand generation guards and native stamping remain separate small cycles.
