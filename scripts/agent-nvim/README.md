# Shared agent Neovim

`server` manages one headless Neovim per Git worktree. The socket name is keyed
by the worktree's canonical path, so all agents in that worktree share the same
language-server cache without touching a human editor.

```sh
scripts/agent-nvim/server start     # start, open a Rust file, wait for rust_analyzer
scripts/agent-nvim/server status    # target, PID, whole process-tree memory, LSP count
scripts/agent-nvim/server target    # socket path only, for MCP connection config
scripts/agent-nvim/server stop
```

Each command accepts an optional worktree path after the verb. `start` uses the
user's normal Neovim configuration, marks the instance with
`vim.g.clearhead_agent_nvim_read_only`, and prints the socket as `target:`.
Read-only is an agent policy: use references, definitions, symbols, hover, and
`exec_lua`; never use rename, code actions that apply edits, formatting, or
`lsp_apply_edit` against this shared process.

State lives under `$XDG_RUNTIME_DIR/clearhead-agent-nvim` (or `/tmp` when no
runtime directory is defined). `status` sums Neovim and all descendant LSP
processes, rather than reporting only the editor parent. `stop` asks Neovim to
quit, then terminates it if necessary.

A 2026-09-22 platform-worktree check measured five warm compact outline requests
at 6–8 ms each over the local socket. The running Neovim, rust-analyzer, and
other configured LSP descendants used about 1.16 GiB together. These are local
observations, not performance guarantees; use `status` for the current process.

Run the isolated lifecycle test with:

```sh
scripts/agent-nvim/test-server.sh
```

## Compact views

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
