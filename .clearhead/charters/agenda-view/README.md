---
alias: agenda-view
state: Active
description: Cross-cutting agenda view spanning core query logic, CLI commands, and Neovim virtual buffer with change routing
---

# Agenda View

A named-query agenda system that surfaces the right actions at the right time.
Built-in opinionated views encode a sensible default process — users get daily
and weekly perspectives without having to invent their own query language.

## The Core Idea

Each agenda is a named SPARQL query against the workspace graph. The query *is*
the wisdom — transparent, inspectable, overridable. The plugin renders results as
a virtual `ft=actions` buffer so all existing keybindings and LSP features work.
State mutations route back to source files via UUID.

## Built-in Views

**daily** — what to do today
  - open/in-progress, no open predecessors
  - due date <= today OR do date <= today
  - sorted by priority, then due date

**weekly** — what's on the horizon
  - open/in-progress/blocked, no strict date filter
  - due or do date within 7 days, or undated
  - sorted by due date, then priority

## Layers

- **core** — named agenda queries alongside `run_workspace_sql_query`
- **cli** — `clearhead query agenda [daily|weekly]` command
- **lsp** — decide: new LSP command vs plugin calls CLI directly
- **nvim** — virtual buffer + change routing via UUID
