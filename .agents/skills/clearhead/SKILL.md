---
name: clearhead
description: Clearhead workspace navigation and task management. Use when working with `.actions` files, `.clearhead/` directories, `next.actions` files, charter or objective files, the `clearhead` CLI, or when asked about project status, next steps, todos, or any work items. Clearhead is a plaintext-first project management system built around actions (.actions DSL), charters (.md), plans (.ics vdir), and objectives (.md).
---
# ClearHead Skill

One of the exciting parts of the clearhead platform is that we try to make things easy to capture and update, whether through CLI commands, the LSP, or raw edits to the files.

However, some ways are better than others, so the order of preference is:

1. CLI commands
2. LSP hooks
3. Hand edits to files

That is to say, while we prefer things higher on the list, lower items are valid too.

The platform lives at `~/Products/platform` (chezmoi clones it there); paths below assume that.

## CLI commands

The `clearhead` CLI should be on PATH. If it isn't (some sandboxes), say so, and fall back to a hand edit followed by a check (see below).

Start with `clearhead orient`: one bounded snapshot of active charters, the unscheduled queue, blockers and recent completions. `clearhead read charters` and `clearhead read actions` list the full structure, and `clearhead --help` lists every command.

The verbs you'll use most, all of which escape, stamp ids and keep the sidecars right for you:

- `clearhead add action "<name>" --alias <alias> --description "<why and what done means>" -p <1-9>`
- `clearhead update action <alias> --state in-progress` (or `--description`, `--priority`, ...)
- `clearhead complete action <alias>`, `clearhead cancel action <alias>`
- `clearhead jot "<finding>"` for a timestamped note in a charter's log
- `clearhead query named <query>` for saved queries, such as `for-human`

## LSP

We also have an LSP server. It's primarily intended for humans, but where the neovim MCP server is available you can use it too, and it does the plumbing for you when you edit the various item types.

## Hand-Edits

We don't disallow editing the files by hand; that's a core benefit. But it means more fiddling, because you become responsible for the data model: the sidecar data, and things like the UUID that the CLI and LSP add automatically. Work smarter, not harder.

### Risks of Hand Edits

We have a strong process for what should happen when actions are created, updated or closed, and it's built into the other tools. When you hand edit, the data model can drift.

Two traps in the `.actions` format:

- **One syntax error quarantines the whole file.** Every action in it disappears from reads and queries until it's fixed, not just the broken line. Common causes: a description missing its closing `$`, or an unescaped `:` in a name (write `\:`).
- **So after any hand edit, run `clearhead doctor`** and read its report. It exits non-zero on warnings as well as violations, so check for `0 violation(s)` rather than its exit code.

## Specifications

For questions on the workspace, file formats and the data model, review the specs in `~/Products/platform/specifications` (published at clearhead.dev).

## The views

We use views to surface our work through both the CLI and the nvim plugin. `unscheduled` and `weekly` are the ones to start from:

`clearhead query index unscheduled`

This gives you your NEXT ACTIONS: if nothing else, you can look and start running the work in order of priority.

### The workflow

Unless told otherwise, use the views to answer "what should I be doing next?"

Then the workflow:

1. check the view
2. pick an action to focus on
3. implement changes
4. update the actions/charters (using the CLI!)
5. commit changes (if in a git repo)
6. push changes, when you have credentials (a sandboxed run has none: it commits and never pushes; see `~/Products/platform/docs/overnight-runbook.md`)
7. go back to the beginning!

This is our tight loop, where we stay self-sufficient without needing to review the list all day. In an ideal world, the entire workflow happens through the CLI.

Note how the loop continues: as you complete actions, the view may reveal NEW actions or shifts in priority, so re-run it every time you complete an action or charter rather than working through the whole list at once.
