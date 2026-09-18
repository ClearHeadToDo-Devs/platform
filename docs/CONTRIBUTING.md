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
