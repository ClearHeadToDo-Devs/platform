---
alias: caldav-integration
state: Active
description: Two applications (ClearHead and a CalDAV server) sharing one plan directory and syncing through the files themselves — no integration layer, coordination through data
---

# CalDAV Integration

Implements [decision 31](../../../DECISIONS.md). Builds on [[write-durability]],
which gives us the atomic single-file write and the staged A+B commit seam this
charter relies on.

## The shape

A new config key, `plan_path`, names one directory where all plans (`.ics`
files) live. A CalDAV server — radicale, in practice — points at that same
directory. Now two programs share a directory and neither needs to know the
other exists:

- The **server owns the calendar**: display, editing UI, the CalDAV protocol,
  and the `.ics` files once they exist. We do not eat that complexity.
- **ClearHead owns the actions**: it writes a plan's `.ics` when the underlying
  action changes, and reads `.ics` back to propagate calendar-side edits into
  actions.

The coordination mechanism is **the shared data, not a shared protocol**. We do
not model the server's internals or its failure modes — that way lies an
unbounded integration layer. We agree on one contract: the vdir `.ics` files on
disk. Two consequences:

- **Read `.ics` only.** A CalDAV server keeps its own sidecar state next to the
  files (radicale writes its own `.json`). That is the server's implementation
  detail, tied to *its* identity model, and we must never read it in — only the
  `.ics` is the shared contract.
- **Once a plan's `.ics` exists, the server owns the file.** We overwrite it
  only when our action actually changed, and we never delete a file that is
  present. Idempotent regeneration only removes `.ics` files that are *absent*
  from the model — never ones already on disk. This is what makes the sharing
  bidirectional with no integration layer.

## Syncing state (the three-way table)

Edits can originate on either side, and we want to honor both without knowing
*when* anything changed. We get that with a stored merge base. Two copies of
the action's dates at last sync hold it:

- `scheduled_at_sync` — copy of `scheduled_at`
- `due_date_sync` — copy of `due_date`

These are **sidecar** fields (`.<charter>.json`, `ActMeta`), not DSL — they
sit next to `source_vevent`, the other half of the CalDAV linkage. The merge
base is machine-owned bookkeeping: a user editing it would corrupt the sync,
so it never enters the human-edited `.actions` file. They default to absent
(`None`), which reads as "never synced" — until the first reconcile establishes
a merge base, "B is unset" and "no `.ics` exists" travel together.

That gives three observable values per date:

- **A** — the action's current date
- **B** — the sync-copy (the merge base)
- **C** — the date in the `.ics`

Comparing each against B tells us who moved, with no timestamps:

| A vs B  | B | C vs B  | result          |
|---------|---|---------|-----------------|
| same    | — | same    | no-op           |
| changed | — | same    | write C and B   |
| same    | — | changed | write A and B   |
| changed | — | changed | conflict — *unless A == C* (see below) |
| removed | — | same    | remove C and B  |
| same    | — | removed | remove A and B  |
| removed | — | changed | conflict-merge  |
| changed | — | removed | conflict-merge  |

When both sides moved to the **same** value, that is a clean convergence, not a
conflict — the two edits agree, so there is nothing to merge. We write no
payload and only restamp the stale merge base to the agreed value. So
`changed/changed` is a conflict precisely when **A ≠ C** (the same rule a 3-way
text merge follows).

When reconcile lands a result, A, B, and C must end up agreeing — but they do
not all live on one filesystem. The `.ics` (C) sits under `plan_path`, which can
point at another mount or another machine entirely (that decoupling is the whole
point). So a single atomic write across the payload and the merge base is *not*
something we can promise. We get durability a different way:

- **Calendar wins (`write A and B`):** `.actions` and the sidecar both live in
  the charter root — same filesystem — so these two genuinely ride one atomic
  batch. `.ics` is untouched.
- **Action wins (`write C and B`):** we write the `.ics` **first**, then stamp B.
  The order is load-bearing. If we crash in between, the next run sees A and C
  agreeing while B lags — a `changed/changed & A == C` case, which reconcile
  resolves as a clean **convergence** that simply restamps B. The work
  self-heals. (Stamp B first and a crash would instead look like the calendar
  moved, silently reverting the action's edit — so never that order.)

This is why `Converged` exists: it is not only "two identical edits aren't a
conflict", it is the recovery mechanism for an interrupted push. We lean on an
**idempotent, convergent** reconcile rather than distributed atomicity — we do
not own the calendar's filesystem, so we do not pretend to commit across it.

**B drifting is a bug, not an edit.** B is *our* copy; it should only ever move
when reconcile moves it. If a run finds B changed or removed on its own,
something corrupted the merge base — log it loudly and surface guidance rather
than treating it as a normal change.

## Conflict-merge

The four conflict rows mean both sides moved and we cannot pick safely. The
tools surface the conflict and let the user decide — never silently choose:

- **both changed:** which source wins.
- **one removed, one changed:** whether the removal or the edit is the intent.

## Wiring (how `plan_path` threads in)

This splits cleanly into two slices so the plumbing never arrives before the
fluid that flows through it:

- **Slice 1 — the config key.** Add `plan_path` to `config.schema.json`,
  `configuration.md`, the core `WorkspaceConfig` struct, and the CLI's config
  loading. The field exists, loads, and round-trips. *Nothing reads it yet* —
  and that is honest, because the action that reads it is the next slice.
- **Slice 2 — make reads honor it.** `plan_path` overrides exactly one thing:
  `plans_root` (where `.ics` files live). `charter_root` is untouched, and
  `save_domain_model` is untouched (it writes `.actions`, never `.ics`).
  So this is a *read/write-of-`.ics`* change with a deliberately small surface.

  The override is applied **where config is actually known**, not smeared
  through the layout resolver. The caller graph forced this: config enters core
  at exactly one place (`load_workspaces`), the `.ics` read is a single funnel
  (`load_domain_model` → `Workspace::load` → `load_workspace` →
  `collect_plan_files`), and `resolve_workspace_layout` has ten callers of which
  only two touch plans. Threading the override into the resolver would make
  seven config-blind callers pass `None` and centralize nothing. So instead:
  - `resolve_workspace_layout` is **left untouched** — it remains the pure
    default resolver.
  - `collect_plan_files_in(plans_root, project_root_charter)` is the new
    `pub(crate)` leaf that reads the directory it is handed. `collect_plan_files`
    and a public `collect_plan_files_with_plans(root, plan_override)` delegate to
    it; the funnel applies `plan_override.unwrap_or(layout.plans_root)` once.
  - The override rides a narrow `_with_plans` family —
    `load_domain_model_with_plans` / `Workspace::load_with_plans` /
    `load_workspace_with_plans` / `collect_plan_files_with_plans`. The plain
    functions delegate with `None`, so archive, manifest, graph, the save tests
    and the LSP keep their signatures and their default behavior — no boilerplate.
  - `load_workspaces` applies `config.plan_path` to the **primary** workspace
    only (additional workspaces own their own config).
  - The CLI contains it all in `CommandContext`: `plan_override()` resolves
    `plan_path` once (shell-expanded, like `additional_workspaces`), and
    `load_model()` / `load_charters()` / `collect_plan_files()` / `plans_root()`
    route through it. Command call sites that loaded the primary via
    `&ctx.data_dir` now call those helpers and stay oblivious to where plans live.

## Scope boundary

This charter does not build a calendar UI, speak CalDAV, or manage recurrence
display — the server owns all of that. It builds the shared directory, the
read-only `.ics` discipline, the merge-base properties, and the reconcile table.
