---
type: Runbook
title: Platform Development
description: The day-to-day git workflow for developing across the platform's submodules — submodules plus worktrees.
status: stable
generated: { by: human:dab, at: 2026-04-15 }
sources:
  - id: submodules
    resource: SUBMODULES.md
    title: Managing Git Submodules in the Platform Repo
  - id: worktrees
    resource: WORKTREES.md
    title: Git Worktree Workflow
---

# Platform Development
Over the months ive developed a small but interesting loop that relies on a few advanced git features.
- [submodules](./SUBMODULES.md)
- [worktrees](./WORKTREES.md)

Be sure to review those to see the actual workflow required.

now let it be noted these are necessary for wide, multi-project updates but it is very possible to push changes to the individual projects and should be done that way when possible still this helps to handle changes that need to moved acrossed the projects

## Basic Workflow

1. decide on your changes 

## Where knowledge lives

Every kind of knowledge has exactly one home. Copying it into a second place is
how drift starts — one 2026-09-18 decision ended up written into an action, a
charter log, `DECISIONS.md`, a runbook and a memory file, and the copies had
already begun to disagree. The rule:

| Knowledge | Lives in | Not in |
| --- | --- | --- |
| Platform decisions | `DECISIONS.md` | actions, logs, runbooks |
| Project decisions | that repo's `docs/DECISIONS.md` | the platform's `DECISIONS.md` |
| Task state | ClearHead actions | docs |
| Dated run findings | the charter's `## Log` | `DECISIONS.md`, actions |
| Durable repo facts | `docs/` | actions, logs |

Consequences worth stating plainly:

- **Ask whether it should outlive the work.** Charters, actions and their logs are working memory: useful while the work runs, and archived when it ends. Anything meant to outlive the work (a decision, a durable fact, a design that others will build on) goes in `docs/`, which is evergreen. A design note written during a charter is distilled into decisions and reference docs before the charter closes.
- **A decision lives in the smallest repo that must change to honor it.** If
  only one repo's code is bound by it, it goes in that repo's
  `docs/DECISIONS.md`. The platform's [`DECISIONS.md`](DECISIONS.md) keeps what
  binds more than one repo: the specification, repo topology, shared tooling.
- **Repos follow the platform, never the reverse.** A repo's docs may cite the
  platform's; the platform's docs (decisions, runbooks, anything else) never
  cite a repo's decisions. A platform doc that needs to is mixing levels: split
  it, keeping the cross-repo part in the platform and moving the repo-specific
  part into that repo's own docs.
- **Decisions live only in a `DECISIONS.md`.** An action *links* to
  a decision (by number or path) and holds the task state; it does not restate
  the decision text. A charter log entry names the decision and the commit in
  one line — it never recaps the analysis.
- **Charter logs hold dated findings, not decisions.** A finding is what a run
  observed; a decision is a choice that outlives the run. If a finding turns out
  to be a decision, put the decision in `DECISIONS.md` and leave the log line
  pointing at it.
