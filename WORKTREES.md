# Git Worktree Workflow

This is the practical workflow for working in this repo with multiple parallel branches/worktrees.

## Mental Model
- Keep one base checkout on `main` as your sync point.
- Create one branch + one sibling worktree per task.
- Do conflict resolution in a dedicated integration branch/worktree before merging to `main`.

## Day-to-Day (Single Task)
From the base checkout:

```bash
git switch main
git pull --ff-only
git worktree add -b feat/my-change ../platform-feat-my-change main
```

This creates:
- branch: `feat/my-change`
- sibling directory: `../platform-feat-my-change`

Do all work in that sibling directory.

After merge:

```bash
git worktree remove ../platform-feat-my-change
git branch -d feat/my-change
git worktree prune
```

## Parallel Worktrees (3-4 Agents)
When several branches are active, use an integration lane.

### 1) Keep a dedicated integration worktree
From the base checkout:

```bash
git switch main
git pull --ff-only
git worktree add -b int/batch-YYYY-MM-DD ../platform-int-batch main
```

### 2) Merge feature branches in intentional order
In `../platform-int-batch`:

```bash
git merge --no-ff feat/foundation
git merge --no-ff feat/api
git merge --no-ff feat/ui
```

Recommended order:
- foundational schema/refactor branches first
- behavior/API branches second
- UI/content branches last

### 3) Resolve conflicts once, run full verification once
- Resolve merge conflicts in integration branch.
- Run full tests/checks in integration branch.
- If clean, merge integration branch to `main`.

This avoids repeated conflict churn across multiple PRs.

## Commands You Will Actually Use

### See all worktrees
```bash
git worktree list
```

### Create a branch + worktree from main
```bash
git worktree add -b feat/some-task ../platform-feat-some-task main
```

### Remove a finished worktree
```bash
git worktree remove ../platform-feat-some-task
git worktree prune
```

### Enable remembered conflict resolutions (highly recommended)
```bash
git config --global rerere.enabled true
```

`rerere` helps when similar conflicts repeat across rebases/merges.

## Guardrails
- Do not check out the same branch in multiple worktrees at once.
- Keep the base checkout clean and on `main`.
- Keep branch scope tight (one concern per branch).
- Avoid force-push during integration unless absolutely necessary.
- If rebasing feature branches, use `git range-diff` to verify you did not lose meaningful changes.

## Branch Lifecycle (Important)
Default to ephemeral branches.

- Create a fresh branch for each feature/fix.
- Merge it, then delete branch + remove worktree.
- Do not reuse old feature branches for new unrelated work.
- Keep long-lived branches only when your release model requires them (for example `release/*`).

Why:
- cleaner diffs and PR reviews
- less accidental carry-over work
- simpler history and safer parallel development

After merges, cleanup looks like this:

```bash
git switch main
git pull --ff-only
git fetch --prune
git branch --merged | grep -vE '(^\*|main|master|develop)' | xargs -r git branch -d
git worktree prune
```

## Suggested Naming
- Worktrees: `../platform-<type>-<topic>`
  - example: `../platform-feat-export-calendar`
  - example: `../platform-fix-ref-resolver`
  - example: `../platform-int-batch-2026-04-12`
- Branches: `<type>/<topic>`
  - example: `feat/export-calendar`
  - example: `fix/ref-resolver`
  - example: `int/batch-2026-04-12`

## Quick Recipe
1. Update base checkout on `main`.
2. Spawn task worktree with `git worktree add -b ...`.
3. Let each agent work in its own worktree.
4. Integrate all active branches in `int/...` worktree.
5. Resolve conflicts + run checks in integration worktree.
6. Merge integration branch to `main`.
7. Delete merged branches/worktrees.
