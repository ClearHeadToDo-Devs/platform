---
alias: templates
---
# Templates

## What

A first-class primitive for reusable `.actions` fragments. Templates are plain `.actions` files stored in a `templates/` folder within any charter scope. They can be instantiated on-demand or on a recurring schedule.

## Why

Two problems converged on the same solution:

**Recurring acts with structure** — a weekly review isn't a single act, it's a procedure: ordered steps, done together. `.ics` handles recurrence timing but has no concept of hierarchy. Without templates, you either flatten the procedure into one vague act ("do weekly review") or list each step as its own independent recurring event — both are wrong.

**On-demand procedures** — new project scaffolding, onboarding checklists, periodic deep-dives. These share a known shape but need customization per instance. There was no home for this pattern.

The unifying insight: both cases need *reusable structure*. Templates are that structure. The format is already `.actions` — no new parser, no new concepts for the user.

## How

### Template files

Templates live in `templates/` within any charter scope:

```
.clearhead/templates/weekly-review.actions
.clearhead/templates/new-project.actions
build_clearhead/templates/release-checklist.actions
```

A template is a plain `.actions` fragment — a set of acts, possibly hierarchical, with no required metadata. Variables (title substitution, dates) are out of scope for now.

### Recurring instantiation via `.ics`

Schedules are defined as `.ics` files. A VEVENT references a template by name via a convention in the DESCRIPTION field — the first line starts with `template: ` followed by the template name:

```
BEGIN:VEVENT
SUMMARY:Weekly Review
RRULE:FREQ=WEEKLY;BYDAY=SU
DTSTART:20260427T100000
DESCRIPTION:template: weekly-review
END:VEVENT
```

This works with standard calendar apps (Google Calendar, Outlook, Apple Calendar) — users put `template: weekly-review` as the first line of the event notes. Any text after the first line becomes the plan description.

`expand acts` reads the schedule, determines which instances are due within the configured horizon (default: 14 days), and generates acts into the relevant `.actions` file. If a template is referenced, the generated act gets the template's children pre-populated.

Schedules will be on a per-charter basis, so they will look for `<charter>.ics` at the same scope as the usual `<charter>.actions` file. This allows different charters to have different schedules while still being able to be combined when necessary.

### On-demand instantiation

```
apply template weekly-review
apply template new-project --charter my-project
```

Generates acts into the current or specified charter's `.actions` file. User then edits/customizes from there.

### Charter scaffolding

```
new charter my-project --template software-project
```

Creates the charter `.md` and `.actions` files pre-populated from the template. Separate from act-level templates but uses the same `templates/` folder convention.

## implications
### Ontology
this means that the actions file will primarily represent PLANNED ACTS from now on, whereas the schedules (ics files) will represent PLANS (which makes sense in a way) while each of the instances defined by that are from planned acts

this will have wide reaching but important implications as it is a shift in both mindset and structure but gets us closer to pawning off the real work to the tools that did the work:
- scheduling goes to calendars
- queries come from graph engines
- all we made ourselves is the DSL for the planned acts which makes more sense from the naming perspective as well!
### Linking
how are we going to easily update the structure of the generated acts now? before we knew the parent had a uuid and the acts would have child uuids but now we will either need a uuid for the vevents that are now plans, or we need to go ahead and just have the actions be independent but we definately want some concept of knowing what schedule one is attached to atleast from the data layer

specifically, rather than using the uuid v7 from the actions files like we are doing we will instead use the vevent uid to deterministically figure out what acts are connected to what schedules.

meanwhile, new, on-demand acts will still use uuid v7 but will have a null vevent uid which is how we can differentiate between the two in the data layer. this also means that we can easily update the structure of the generated acts by just looking up the vevent uid and then updating all acts with that vevent uid as well.

Boundary note: keep this as an integration mapping detail, not a core ontology commitment. In core semantics, prefer neutral fields like `externalScheduleId` and `externalOccurrenceKey`, then map those to VEVENT UID/instance identity at the ICS adapter layer.

## Scope

**In scope:**
- Template files as plain `.actions` fragments
- `expand acts` consuming `.ics` schedules with optional template references
- `apply template` CLI command for on-demand use
- Template resolution: charter-local first, then platform root

**Out of scope (for now):**
- Variable substitution in templates
- Template versioning or inheritance
- GUI/LSP for template authoring
- Anything that requires a new file format
