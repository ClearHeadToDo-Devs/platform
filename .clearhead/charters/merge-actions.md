---
id: 01a21520-fe44-7d81-a0f7-35f16fda8a7d
alias: merge-actions
parent: platform
state: Active
---
# Merge .actions files semantically

Git merges `.actions` files line by line, so two people (or a person and an agent) editing the same charter collide on lines that mean different things, and a clean line merge can still break the tree. This charter makes git merge them by action UUID instead: a pure three-way merge in Core, a grammar that keeps a conflicted file readable, and a git merge driver that ties them together.

## Decisions so far (Darrion, 2026-11-25)

- **Match git.** A conflict keeps ours as the placeholder (git's `%A`); the driver exits nonzero so the merge stops.
- **Conflicts:** the same field changed differently, edit versus delete (including adding a child under an action the other side deleted), both sides adding one UUID differently, both sides reordering the same siblings differently, and moves that together form a parent cycle.
- **Not conflicts:** an open child added under a parent the other side completed (the spec allows it; W002 reports it).
- **Templates are workspace-level** (settled alongside; not this charter's work).
- **Conflicted files carry git's own markers** (`<<<<<<<`, `|||||||`, `=======`, `>>>>>>>`), and the grammar learns them, without breaking any valid file.

## Grammar prototype findings (2026-11-25)

A scratch grammar with the four marker lines as extras, and description text at higher lexical precedence, parsed all 254 valid `.actions` files under `~/Products` to identical trees, kept marker-like description lines (a Markdown `=======` heading underline) as description text, and parsed real conflicts at root and child depth with no errors. Nesting is at most five `>`, so the seven-character markers cannot collide.

It did shift tree-sitter's error recovery on two invalid fixtures (E004, E005): a recovering parse of `[ ] Root` / `>>[ ] Skipped` now puts Skipped under Root. Both still have a syntax error, so workspace loads quarantine them and writes refuse them; only best-effort recovered reads (recover-mode reads, LSP, doctor) see the shape. `test_unsupported_grammar_rules` asserted the recovered shape, so it now asserts the syntax error instead.

## Done when

`git merge` of two branches that both edited one `.actions` file resolves non-conflicting edits by UUID with nothing lost or duplicated, and stops with readable markers that every ClearHead reader understands when they conflict.
