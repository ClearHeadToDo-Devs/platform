# Promoting an action to a subcharter

The decisions behind `=promote-action`, one at a time. Each one is answered in chat and recorded here.

## What it is

One verb turns an action that has grown into a project into a subcharter of the charter holding it. No spec defines promotion yet.

## Where it stands

Decided with Darrion on 2026-11-25 (notes on `=promote-action`, `docs/charter-defaults-proposal.md`):

- **Identity:** the charter keeps the action's UUID, as a kind change does ([process.md](../specifications/process.md#kind-changes-and-identity)). Existing waits on the action then name the charter.
- **Order of writes:** the charter is written first, then the line is removed. A UUID that is both an action and a charter is an unfinished promotion, and doctor reports it.
- **Scope:** any action, nested ones included; the parent just loses a child.
- **Placement:** the new charter is a child of the action's charter. A flat parent converts to directory form as part of the verb.
- **Mapping:** name to title, description to body, children to the charter's top-level actions with their ids kept. Other fields go to frontmatter under `actions.schema.json` names, kept even before they mean anything.
- **Inherited conditions:** the action's effective window and waits, its ancestors' included, go to `base`, so the children keep them.
- **State:** the new charter is `New`.
- **Alias:** the action's, or a generic `subcharter-NN` to rename later (`=rename-charter`).

Prerequisites: `base` landed (spec 2dfa4b1, Core 7b4835a). Waiting on a charter landed in the spec and in Core's resolver (Core 0715d14), but E009, W008 and W009 are missing from Core, and the index chain and graph dependencies drop charter targets.

## Questions

### 1. What happens to a `~` sequence the action leaves?

`~` on a parent makes its direct children sequential: each waits on the one before it. Example:

```actions
[ ] Move house ~
    > [ ] Pack
    > [ ] Renovate the new place
    > [ ] Unpack
```

Promoting "Renovate" removes its line. Under `~`, "Unpack" then waits on "Pack", no longer on the renovation.

| Option | Meaning | Cost |
| --- | --- | --- |
| **Write the wait** | The next sibling gains `<` naming the new charter, so it still waits on the work. | The verb edits a line it was not asked about, and the wait now ends only when the charter is explicitly `Closed`. |
| **Close the gap** | The sequence closes up; the next sibling waits on the one before. | Promotion silently changes when "Unpack" can start. |
| **Refuse** | An action inside a `~` sequence can't be promoted; the user breaks the sequence first. | Goes against "any action can be promoted", and the user does the first option by hand. |

Answer (Darrion, 2026-11-25): **write the wait**, once the graph and index carry waits on charters, so that the chain is proper. Promotion keeps every action's effective waits, as `base` keeps their windows.

### 1a. How far does `query index chain` walk into a charter? (prerequisite)

`chain` lists the open actions an action waits on, through `app:waitsOn+`. It drops charter targets, and a charter has no `app:waitsOn` of its own: its `base` waits sit on its top-level actions. With "Renovate" promoted and `base: {predecessors: [Pack]}`:

| Option | `chain Unpack` lists | Cost |
| --- | --- | --- |
| **The charter, then stop** | Renovate (charter) | Smallest change, but Pack, still open, drops out of the chain. |
| **The charter and its base waits** | Renovate (charter), Pack | Matches the chain before promotion. The walk steps from a charter to its `base` waits, which the graph only carries on its actions. |
| **The charter, its open actions and their waits** | Renovate (charter), its open actions, Pack | Shows the work left inside the charter, which the chain before promotion did not. But the charter ends only when explicitly closed, not when its actions do. |

Answer (Darrion, 2026-11-25): **a charter waits like an action does**. A charter has its own predecessors, each an action or a charter, and the walk goes through them as it goes through an action's. So the chain reaches Pack through the charter's own waits, and promotion maps an action's `<` to the same field on the charter.

### 1b. Do a charter's own predecessors replace `base.predecessors`?

Once a charter waits on things itself and its actions inherit those waits, as children inherit a parent action's `<`, both fields give its actions the same waits.

| Option | Meaning | Cost |
| --- | --- | --- |
| **Replace** | `predecessors` in charter frontmatter is the charter's own wait; its actions inherit it. `base` keeps only `dueDateTime`. | Partly reverses spec 2dfa4b1 and Core 7b4835a from today. Both are unreleased, and only the spec's own example uses `base`. |
| **Both** | The charter's own wait, and `base.predecessors` as well. | Two fields with the same effect on actions, which go on to differ only in what the charter node shows. |

Answer (Darrion, 2026-11-25): **both**, because they do different things: a charter's own `predecessors` are waits of that charter, and `base.predecessors` are waits of everything it holds, its sub-charters and their actions.

### 1c. What does a charter's own wait hold back?

An action's own `<` holds back the action and, through inheritance, its children. If a charter's own wait reached its actions, it would do what `base` does, so it doesn't reach them. What it does do is still open: does it only order the charter (chains and graphs walk through it, so whatever waits on the charter also waits on its predecessors), or does it also gate something about the charter itself, such as activation?

It also decides what promotion writes. An action's `<` both orders the action and holds back its children, so promotion may write the same reference to both fields.

Answer (Darrion, 2026-11-25): **it orders the charter, and activating it early is a lint, not a hard rule**. Whatever waits on the charter also waits on its predecessors, and an `Active` charter with an open predecessor is reported. So promotion writes an action's `<` to both fields: `predecessors` keeps the order, `base.predecessors` keeps its children waiting.

### 2. What happens to a `~` action's own sequence?

The 2026-11-25 decision makes sibling order the charter's own property, not a default. As frontmatter (`sequentialChildren: true`), it would mean nothing yet, so the children would lose their waits on each other.

### 3. Which actions can be promoted?

Open states (`[ ]`, `[-]`, `[=]`) all become `New`. Still open: closed actions (`[x]`, `[_]`), Habits, and a Habit's occurrences, whose ids are derived from a slot.

### 4. What happens to a scheduled action's plan?

A scheduled action realizes one VEVENT, `plans/<parent>/<uuid>.ics`, in its charter's collection. After promotion that UID names a charter, not a block.

## Already settled by precedent

- **Notes follow their entities.** The action's notes move to the new charter's sidecar under the same id, so its history becomes the charter's log. The children's notes move with them.
- **Spec home:** a Promotion section in `charters.md`, with `workspace.md` for the layout change and `process.md` linking identity to kind changes.
