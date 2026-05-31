---
id: d410e3af-6608-4f7f-9688-9bded137fd9f
alias: query-system
state: Active
---
# Query System

SPARQL is the one query language. The query system's job is to make SPARQL
composable and output-aware without hiding it.

## Design Decisions

**Two kinds of queries: full and fragment.**
A full query owns its SELECT and WHERE — it is SPARQL. A fragment owns only a
WHERE body; the system wraps it in a fixed SELECT shell appropriate to the
response type. Fragments are simpler to write and enforce the output contract.

**Response types define the SELECT contract.**
A response type (`qflist`, `calendar`, `table`) declares the columns its
consumer requires. The CLI knows the SELECT shell for each type. Users write
WHERE fragments — filtering logic only — without knowing the projection.

**Frontmatter makes query files self-describing.**
Named query files (`.sparql`) may carry a `# ---` YAML header:

```sparql
# ---
# type: qflist
# kind: where-fragment
# description: High priority open actions
# ---
?act actions:hasPriority actions:High .
```

`type` maps to a response type. `kind` is `full-query` (default, current
behavior) or `where-fragment`. Files without frontmatter are treated as
`kind: full-query` with no type — preserving backwards compatibility.

**WHERE injection is scoped inside `GRAPH ?g {}`.**
The fixed SELECT shell for each response type already contains the `GRAPH ?g {}`
block. Injected WHERE fragments are inserted inside that block, so they see the
same named graph bindings (workspace node, source location triples) as the
base pattern.

**Bare `clearhead query` remains freeform.**
`clearhead query "SELECT ..."` and `clearhead query --where "..."` are
unchanged. No type system is imposed on ad-hoc queries.

**Typed subcommands are the composable path.**
`clearhead query qflist` runs the `qflist` type with its default WHERE.
`clearhead query qflist --where "..."` injects an extra constraint.
`clearhead query qflist my-filter` resolves `my-filter` as a named WHERE
fragment of type `qflist` and runs it.
