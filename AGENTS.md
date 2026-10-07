# Context
This is a higher order repo with several other repositories as git submodules

for a large intro please see [the README](./README.md) 

If you are just rearing to go, then go ahead and assume that we have the text 

Otherwise the other context stands, we are here for quality not quantity, so take your time, read the docs and specifications, dont be afraid to ask questions, make suggestions, and even make mistakes.

Together, i know we can create something that neither could do alone, but as the system grows, it is important that clear communication guides our way forward and that we are implementing changes at the various levels they may be needed.

## Next Actions
In each repo is a `.clearhead/` directory per the [workspace spec](./specifications/workspace.md) which houses the `next.actions` file for that project atleast so you should check there first as this is where much of the knowledge of what is done and what still needs to be done is

## Where agent knowledge lives
[Where knowledge lives](./docs/CONTRIBUTING.md#where-knowledge-lives) covers the homes shared with humans. On top of it, for agents:

| Knowledge | Lives in | Not in |
| --- | --- | --- |
| What only one harness needs | that harness's memory | the repo |

- **Memory holds only what is not derivable from the repo.** If `rg` can find it, memory should not duplicate it.
- **Promotion is explicit.** Harness memory and ClearHead are separate stores and nothing syncs them. A finding becomes project knowledge only when promoted to a `clearhead jot` (a dated charter finding) or `clearhead add action` (task state).
