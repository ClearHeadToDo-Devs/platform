---
id: d410e3af-6608-4f7f-9688-9bded137fd9f
objectives: [query-interface, data-integration]
state: Active
---
# Query System

SPARQL is the one query language. The query system's job is to make SPARQL composable and output-aware without hiding it.

## Design Decisions

**All query files are valid SPARQL.**
No fragments, no injection, no magic transformation. Every `.sparql` file runs as-is.
Tooling (syntax highlighting, linters, external validators) always sees a complete query.

**Response types define the output contract.**
A response type (`index`, `calendar`, `table`) declares the columns its
consumer requires. The CLI validates query output against the contract and
errors clearly if columns are missing — it does not attempt to fix or compose.

**Directory placement routes output to the right renderer.**
Where a file lives determines how its output is consumed, not how the query
is built:

```
queries/
  my-adhoc.sparql          # freeform — table output, no contract
  index/
    high-priority.sparql   # full valid SPARQL that returns index columns
  calendar/
    this-week.sparql       # full valid SPARQL that returns calendar columns
```

**The intended workflow is: experiment then save.**
`clearhead query "SELECT ..."` or `clearhead query --where "..."` to explore.
When the query works, save it to the appropriate subdirectory.
`clearhead query index high-priority` runs the saved query with index framing.

**Bare `clearhead query` remains freeform.**
`clearhead query "SELECT ..."` runs a full query, table output.
`clearhead query --where "..."` wraps the clause in `SELECT * WHERE { GRAPH ?g { } }` —
returns whatever variables you bind, no contract on names. Exploration sugar.
No typed `--where` injection — if you need a filtered index query, write the full
query and save it. Typed subcommands have no `--where` flag.
