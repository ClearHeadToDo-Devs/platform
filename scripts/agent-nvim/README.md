# Compact agent LSP views

`compact.lua` turns Neovim LSP responses into bounded, read-oriented tables for
agents. It performs no edits. Every emitted line number is 1-based and can be
passed directly to a ranged source read.

Call the views through the Neovim MCP server's `exec_lua` tool:

```lua
local compact = dofile("scripts/agent-nvim/compact.lua")
return compact.outline(0)
```

The module exposes:

- `outline(bufnr?, timeout_ms?)` — top-level symbols and one child level as
  `{ kind, name, line, children? }`;
- `references(bufnr?, line, column, timeout_ms?)` — references grouped as
  `{ file, count, lines }`;
- `definition(bufnr?, line, column, timeout_ms?)` — definition targets as
  `{ file, line }`.

Input lines and columns are also 1-based. `bufnr` defaults to the current
buffer; use `0` explicitly in one-off calls.

Run the deterministic response-shaping tests with:

```sh
nvim --headless -u NONE -l scripts/agent-nvim/compact_test.lua
```
