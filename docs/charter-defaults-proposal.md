# Charter defaults

The decisions behind `=charter-defaults`, one at a time. Each one is answered in chat and recorded here.

## What it is

`defaults` in charter frontmatter ([charters.md](../specifications/charters.md#optional-frontmatter)) "gives settings to all descendants." Its keys are unspecified, and the schema accepts any map. Core parses it and puts it in the charter JSON, but nothing applies it.

## Where it stands

- **Real usage: none.** No charter under `~/Products` declares `defaults`. Only fixtures do: the spec sample has `contexts: [home]`, and Core's tests use `context: work` (singular). Nothing needs migrating.
- **What an action inherits from its ancestor actions today:** two things.
  - **Window** (`:`): effective, it opens at the latest lower bound and closes at the earliest deadline, so a child can only narrow it. It is never written down.
  - **Waits** (`<` and `~` siblings): `app:waitsOn` includes every ancestor's waits.
  - **Not inherited:** contexts, priority and everything else.
- **What promotion needs:** a promoted action's children become the charter's top-level actions. To keep their effective conditions, the charter has to pass down the window and the waits. A `~` parent's sibling order is the charter's own property, not a default (decided 2026-11-25: "a charter's own properties describe it; its defaults map carries what children inherit").

## Questions

### 1. What does a default mean?

When a descendant action has its own value for the same key:

| Option | Meaning | Cost |
| --- | --- | --- |
| **Fill-in** | It applies only when the action sets none. | A child with its own `:` escapes the charter's window, which it can't do under a parent action. Promotion would then change effective windows. |
| **Inherited condition** | It composes as an ancestor action's would: windows narrow, waits add up. | Contexts and priority have no composing meaning, so they would need their own rule or be left out. |
| **Per key** | Window and waits compose; other keys fill in. | Two rules to learn and to spec; each key says which one it follows. |

Answer (Darrion, 2026-11-25): **fill-in**. A default is for when a value is not set, and an action's own value overrules it. A behavior that composes instead gets its own key: `base` tags are appended to by an action's own tags, while `default` tags are replaced by them. These are two different uses of the same field.

Consequence for promotion: it writes the window and the waits as base (composing) values. Written as defaults, a child's own `:` would escape the window it used to narrow.

### 2. How is base written? (answered)

| Option | Example | Cost |
| --- | --- | --- |
| **Prefixed keys in `defaults`** | `defaults: {priority: 2, baseContexts: [home]}` | One map, but each base key is a renamed schema field, and the list of prefixed names has to be specified. |
| **A second map** | `defaults: {priority: 2}` and `base: {contexts: [home]}` | Two frontmatter keys. Both maps take `actions.schema.json` names unchanged, and the map, not the name, carries the rule. |

Answer (Darrion, 2026-11-25): **a second `base:` map**. It's easier to read, and "base" fits the window too, as long as the complexity does not grow.

### 3. When is a field "not set"? (answered)

An action's own field may be empty while it still inherits a value from an ancestor action, for example a window from its parent. Does a default fill a field that is empty as written, or only one that is still empty after inheritance? For priority, which nothing inherits, the two are the same.

Example: the charter has `defaults: {dueDateTime: 2026-12-05}`. Its action `[ ] Party :2026-12-10` sets a deadline, and the child `> [ ] Invites` has none written.

| Option | Invites' effective deadline | Cost |
| --- | --- | --- |
| **Empty as written** | 12-05: its own empty field takes the default, which then meets Party's 12-10 and wins as the earlier one. | The default reaches past an ancestor action that already set the value, and here it overrules Party. |
| **Empty after inheritance** | 12-10, inherited from Party; the default does not apply. | "Not set" means the effective value, so a reader must know what is inherited. Today that is only the window and the waits. |

Answer (Darrion, 2026-11-25): **empty after inheritance**. A default must never overrule an action that already has the value, inherited included; it is the other way around.

### 4. Which keys in the first increment? (answered)

| Option | Keys | Cost |
| --- | --- | --- |
| **Promotion's minimum** | `base`: `dueDateTime`, `predecessors` | Smallest, and it unblocks promotion. `defaults` is specified but takes no keys yet, so the existing `contexts` fixtures go unexplained. |
| **Minimum plus the fields in use** | That, plus `defaults`: `priority`, `contexts`; `base`: `contexts` | Covers promotion, the fixtures and the tags example. Five key meanings to spec and test. |
| **Any action field** | Every `actions.schema.json` field that is not identity or structure | Open-ended: each field needs a meaning in each map (what are base `priority` and base `@`?), which is the complexity growth to avoid. |

Answer (Darrion, 2026-11-25): **promotion's minimum**: `base` takes `dueDateTime` and `predecessors`. The rest of the system is built out from there.

### 5. How far does base reach? (answered)

| Option | Meaning | Cost |
| --- | --- | --- |
| **All descendants** | A charter's base applies to its own actions and to every sub-charter's, composing as ancestor actions do: windows only narrow, waits add up. A sub-charter cannot loosen its parent's base. | It matches what the spec already says and how actions inherit. The derivation walks the charter chain as well as the action chain. |
| **Own actions only** | A sub-charter's actions see only their own charter's base. | A simpler walk, but it breaks promotion: promoting an action out of a charter with a base window would drop that window from its children. |

Answer (Darrion, 2026-11-25): **all descendants**. The point is that a charter, like an action, can carry these conditions, and that gives nesting more leverage.

### 6. Does base reach a Habit's occurrences?

What `base` touches is decided by what is an Action (process.md Habits, ontology.md Habit terms):

- **Untouched:** Habit roots (`app:Habit`, not an Action), their inline template steps (template data), and `templates/*.actions` files. Templates stay inert.
- **Reached, and wanted:** a template applied on demand stamps ordinary Actions, so a template applied in a bounded charter is bounded. That is the leverage.
- **Reached, and the collision:** each occurrence is a materialized Action with its own window, offset from its slot. Under a charter with `base: {dueDateTime: 2026-12-20}`, every occurrence after 12-20 has an empty effective window, which is a violation, one per occurrence and growing with every slot. A base wait would hold every occurrence until it closes.

| Option | Meaning | Cost |
| --- | --- | --- |
| **Occurrences carry base** | As the draft reads: an occurrence is an Action like any other. | A Habit whose series outlives the window floods doctor with empty-window violations. It needs a rule that reports once, on the Habit. |
| **Occurrences are outside base** | base reaches every Action except a Habit's occurrences and their steps. | base is less powerful: a Habit in a bounded charter ignores the charter's window and waits. Reaching them later is an addition, not a break. |
| **base limits generation** | Slots outside the base window are not materialized. | Couples base to generation, against "every arrived slot materializes", which is the complexity growth to avoid. |

Answer (Darrion, 2026-11-25): **occurrences carry base, with a note**. A Habit that runs every week forever under a charter with an end is a signal: change the charter's border or end the recurrence. W016 reports it once, on the Habit, and covers the occurrences' empty windows in place of one E008 each.

### Already settled by precedent

- **Key names and value forms:** `actions.schema.json`'s (decided for promotion). A window is `dueDateTime: 2026-12-01/2026-12-20`, and waits are `predecessors: [c:groceries]`.
- **Never materialized:** like inherited windows, defaults are derived and never written into action lines ([action_file_format.md](../specifications/action_file_format.md#due-datetime-optional)).
