---
name: clearhead
description: Clearhead workspace navigation and task management. Use when working with `.actions` files, `.clearhead/` directories, `next.actions` files, charter or objective files, the `clearhead` CLI, or when asked about project status, next steps, todos, or any work items. Clearhead is a plaintext-first project management system built around actions (.actions DSL), charters (.md), plans (.ics vdir), and objectives (.md).
---

# Clearhead Skill

## Orient First

Before touching anything, run these four commands:

```bash
find . -maxdepth 4 -name ".clearhead" -type d   # locate all workspace roots
cat .clearhead/charters/next.actions             # read the root charter open actions
ls .clearhead/charters/                          # discover all charters
which clearhead                                  # check CLI availability
```

`next.actions` at the root of `charters/` is always the entry point for a workspace.

## Conceptual Model

| Object | File type | Location | Purpose |
|---|---|---|---|
| **Objective** | `.md` | `objectives/` | The *why* — desired outcomes |
| **Charter** | `.md` or dir | `charters/` | Domain of concern, groups actions |
| **Action** | `.actions` | `charters/` | Atomic executable work item |
| **Plan** | `.ics` (vdir) | `plans/` | Recurring schedule — generates actions |

Plans are **schedule-only**. They live in `.ics` files and produce actions via `clearhead expand`. Never put scheduling or recurrence logic in `.actions` files.

## Workspace Scope

```
Project:  <nearest ancestor>/.clearhead/      ← walks up to filesystem root
Global:   ~/.local/share/clearhead/           ← XDG_DATA_HOME
Config:   ~/.config/clearhead/config.json
```

Project scope takes priority. Both scopes have the same internal layout.

## Finding the Right Docs

Each tool documents itself in its native format — go to the source:

**CLI usage and commands**
```bash
clearhead --help                  # top-level overview
clearhead <verb> --help           # e.g. clearhead add --help
man clearhead                     # full man page (once generated)
```

**Action file format and workspace layout** (paths relative to platform repo root)
```
specifications/action_file_format.md    ← DSL syntax, all fields, examples
specifications/naming_conventions.md    ← workspace structure, charter hierarchy
specifications/configuration.md         ← XDG paths, config.json format
```

**Library API (clearhead-core)**
```bash
cd clearhead-core && cargo doc --open   # rustdoc for all public types
```

**Building the CLI from source** (when not installed)
```bash
cd clearhead-cli && cargo build
./target/debug/clearhead --help
```

**Neovim plugin**
```vim
:help clearhead                         " vimdoc (once written)
```

## Using the CLI

Prefer the CLI for all mutations — it handles UUIDs, file placement, and format normalization.

```bash
clearhead read actions                          # all open actions
clearhead read actions --charter <name>         # scoped to one charter
clearhead read charters                         # all charters, hierarchical
clearhead add action "<name>" --charter <name>  # add action (CLI assigns UUID)
clearhead update action <ref> --state in-progress
clearhead complete action <ref>                 # handles .completed.actions move
clearhead cancel action <ref>
clearhead normalize actions <file>              # batch-assign missing UUIDs
clearhead lint actions <file>                   # validate after hand-editing
clearhead debug                                 # show resolved config and paths
```

When the CLI is unavailable, read `specifications/action_file_format.md` before editing `.actions` files by hand.

## Generating a UUID (when editing by hand)

```bash
python3 -c "import uuid; print(uuid.uuid7())"  # UUIDv7 preferred
uuidgen                                         # UUIDv4 acceptable fallback
```

Every new action needs a `#uuid`. Without one, cross-references and CRDT sync break.

## What NOT to Do

- ❌ **No RRULE in `.actions` files** — recurrence belongs in `.ics` plans only
- ❌ **Don't manually move items to `.completed.actions`** — use `clearhead complete action`; the file move is a side effect of a state transition
- ❌ **Don't hand-edit `archive.ttl`** — written only by `clearhead archive`
- ❌ **Don't skip `#uuid` on new actions** — required for cross-references and sync
- ❌ **Don't use `parent:` frontmatter in charter files** when directory placement already expresses hierarchy
