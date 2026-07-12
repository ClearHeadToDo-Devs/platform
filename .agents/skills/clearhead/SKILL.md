---
name: clearhead
description: Clearhead workspace navigation and task management. Use when working with `.actions` files, `.clearhead/` directories, `next.actions` files, charter or objective files, the `clearhead` CLI, or when asked about project status, next steps, todos, or any work items. Clearhead is a plaintext-first project management system built around actions (.actions DSL), charters (.md), plans (.ics vdir), and objectives (.md).
---
# ClearHead Skill

One of the exciting part of the clearhead platform is we are trying to make things easy to capture and update whether that be through cli commands, lsp, or even raw-edits to the files.

However, some formats are better than others so the order of preference is:
1. CLI commands
2. LSP Hooks
3. Hand edits to files.

that is to say, while we prefer things higher on the list, lower items are valid too

## CLI commands

you can assume that the `clearhead` cli command is available and that you are in the proper directory for the work.

run an initial check with `clearhead read charters` to see the full list of charters and `clearhead read actions` for further structure individual actions

`clearhead --help` gives the full list of commands
## LSP 

We also have an LSP server and while this is primarily intended for humans, you can also use this through the neovim MCP server which will automatically do the required plumbing when you edit the various item types and having their downstream implications known

## Hand-Edits

Finally we dont disallow you from editing the files by hand, that is a core benefit, however, care should be taken that this way involves significantly more fiddling because it means you are also responsible for maintaining the data model through things like giving the sidecar the proper data and adding things like the uuid which the cli and lsp do automatically for you so more like work smarter not harder

### Risks of Hand Edits
We have a strong process around what should happen when actions are created, updated, or closed and that work is built into the other tools for you automatically so when you hand edit you leave the option open for the data model to drift.

in an ideal world, we would have an easy way to sync new information and we largely do, still, it is easier for everyone if we are able to input data properly up-front rather than needing to fix it later

## Specifications

For questions on the workspace, file formats, and even data model please always review [the specs](./../../../specifications)


## The views

we use views to surface our work via both the cli and nvim plugin for your purpose you can work from
- unscheduled
- weekly

so something like `clearhead query index unscheduled`

this gives you your NEXT ACTIONS where if nothing else, you can look and start running the work in order of priority
