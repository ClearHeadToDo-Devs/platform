---
alias: semantic-token-augmentation
state: New
description: LSP semantic tokens that augment tree-sitter with meaning the grammar can't compute — overdue dates, dangling references, blocked actions — projecting the linter's analysis into ambient colour rather than re-emitting syntax
---

# Semantic Token Augmentation

Tree-sitter and LSP semantic tokens answer two different questions. The
grammar answers *"what is this token?"* — fast, local, syntactic: this is a
`datetime`, that is a `link`. Semantic tokens answer *"what does this token
mean right now?"* — context the grammar cannot compute: whether that datetime
is **overdue**, whether a predecessor UUID **resolves to a real action**,
whether this action is **blocked** by an incomplete dependency. They are meant
to stack, not compete — the LSP overlay tinting on top of the grammar's base
colour, which is exactly why semantic tokens sit at priority 125 above
tree-sitter's 100.

## The evidence so far

We arrived here by removing the anti-pattern. `compute_semantic_tokens` used
to emit a token for every `id`, `priority`, `name`, `description`, `story`,
`context`, and date — all of it re-stating what the grammar already
highlights. Being redundant it was worse than useless: at priority 125 it
clobbered finer grammar highlights, most visibly repainting links nested
inside `name`/`description` as plain strings. It now emits nothing and
tree-sitter owns highlighting.

The meaning worth surfacing is already being computed:

- the LSP's **inlay hints** already classify dates as due-today / overdue /
  future (`test_inlay_hints_due_*`) — the temporal computation exists
- the **linter / diagnostics** channel already computes findings like a
  missing UUID or an unresolvable reference

## The bet: one analysis, two projections

Diagnostics and semantic tokens are two projections of the same computed
meaning. A dangling predecessor is a *diagnostic* (a squiggle you hover to
read) — and it could equally be a *token modifier* that tints the reference
red inline, ambient, no hover required. Compute the meaning once in the
resolved `DomainModel`, project it into both channels. The highlighting then
**reinforces the linter**: precise findings in diagnostics, ambient awareness
in colour, always in agreement because they share a source. This is the
platform's "interfaces as projections" value applied to the editor surface.

Concrete first modifiers, each carrying meaning the grammar structurally
cannot see:

- dates → `overdue` / `due-today` (reuse the inlay-hint computation)
- predecessor / dependency references → `unresolved` (dangling)
- actions → `blocked` (an incomplete dependency exists)

## The hard requirement: augment, never re-emit

The failure mode is the one we just deleted. Non-negotiable from the first
spike:

- **no token that merely restates syntax** — if tree-sitter already knows it
  from the grammar, the LSP must not emit it. Tokens carry computed meaning or
  they don't exist.
- meaning layers via **modifiers** (`@lsp.typemod.*`) over the grammar's base
  colour, it does not replace it — links and prose keep their tree-sitter
  highlight.
- the computation lives in **core**, over the resolved `DomainModel`, not the
  syntax `Tree`; diagnostics and tokens both consume it so they cannot drift.
- the `clearhead.nvim` side maps the `@lsp.typemod.*` groups (and owns any
  priority tuning / `LspTokenUpdate` logic) — the server ships the meaning,
  the client ships the colour.

Seed reading: swarn's semantic-highlighting guide, which named the
augment-don't-duplicate distinction for us —
`https://gist.github.com/swarn/fb37d9eefe1bc616c2a7e476c0bc0316`.

## Promotion trigger

The linter grows a second finding that wants **inline** presence, not just a
hover — the moment "I want to *see* the dangling references without reading
each diagnostic" is felt in real use. One modifier proven end-to-end
(`overdue`, since its computation already exists) is enough to convert the
bet; the rest follow the same groove.

## First actions on promotion

1. lift the date-status computation out of the inlay-hint provider into a
   shared function in core over the `DomainModel`, so hints and tokens share
   one source of truth
2. redefine the semantic-tokens legend around modifiers (`overdue`,
   `unresolved`, `blocked`) instead of the old syntactic types; drop the inert
   type list in `handlers.rs`
3. re-implement `compute_semantic_tokens` over the resolved model, emitting
   only modifier-bearing tokens — prove it with `overdue` first
4. add the `@lsp.typemod.*` mappings in `clearhead.nvim` and confirm the tint
   layers over tree-sitter (links survive) with `:Inspect`
5. wire the next finding (`unresolved`) through the *same* core analysis the
   diagnostic uses, demonstrating the one-analysis-two-projections shape
