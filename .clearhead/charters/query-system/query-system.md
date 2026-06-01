---
id: d410e3af-6608-4f7f-9688-9bded137fd9f
alias: query-system
state: Active
---
# Query System

SPARQL is the one query language. The query system's job is to make SPARQL
composable and output-aware without hiding it.

## Design Decisions

**All query files are valid SPARQL.**
No fragments, no injection, no magic transformation. Every `.sparql` file
runs as-is. Tooling (syntax highlighting, linters, external validators) always
sees a complete query.

**Response types define the output contract.**
A response type (`qflist`, `calendar`, `table`) declares the columns its
consumer requires. The CLI validates query output against the contract and
errors clearly if columns are missing — it does not attempt to fix or compose.

**Directory placement routes output to the right renderer.**
Where a file lives determines how its output is consumed, not how the query
is built:

```
queries/
  my-adhoc.sparql          # freeform — table output, no contract
  qflist/
    high-priority.sparql   # full valid SPARQL that returns qflist columns
  calendar/
    this-week.sparql       # full valid SPARQL that returns calendar columns
```

**The intended workflow is: experiment then save.**
`clearhead query "SELECT ..."` to try a query at the command line.
When it works, save it to the appropriate subdirectory.
`clearhead query qflist high-priority` runs the saved query with qflist rendering.
`clearhead query qflist --where "..."` is the only injection path — ephemeral,
inline only, never saved to a file.

**Bare `clearhead query` remains freeform.**
`clearhead query "SELECT ..."` and `clearhead query --where "..."` unchanged.
No type system is imposed on ad-hoc queries.
