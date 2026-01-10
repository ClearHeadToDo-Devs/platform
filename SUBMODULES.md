# Managing Git Submodules in the Platform Repo

This repository uses git submodules to bring together all ClearHead projects into one unified workspace. This guide will help you work with them effectively.

## What Are Submodules?

Think of submodules as **bookmarks**. The platform repo doesn't contain the actual code from `clearhead-cli`, `ontology`, etc. Instead, it records:
- Which repositories to include
- Which specific commit from each repository to use

This means each submodule is its own full git repository, and the platform repo just coordinates them.

## Initial Setup

### Cloning This Repo (First Time)

When you clone the platform repo, you need to initialize the submodules:

```bash
git clone https://github.com/ClearHeadToDo-Devs/platform.git
cd platform
git submodule update --init --recursive
```

Or do it all in one command:

```bash
git clone --recurse-submodules https://github.com/ClearHeadToDo-Devs/platform.git
```

## Day-to-Day Workflows

### 1. Pulling Latest Platform Changes

When someone updates the platform repo (including submodule references):

```bash
git pull
git submodule update --init --recursive
```

**Why both commands?** `git pull` gets the platform repo changes, but doesn't automatically update the submodules. The second command syncs the submodules to match the recorded commits.

### 2. Updating All Submodules to Latest Versions

To pull the latest changes from all submodule repos:

```bash
git submodule update --remote --merge
```

This updates each submodule to the latest commit on its default branch. After this, you'll see changes in the platform repo because the submodule commit references changed:

```bash
git status  # shows modified submodules
git add .
git commit -m "Update submodules to latest versions"
git push
```

### 3. Updating a Single Submodule

To update just one submodule:

```bash
git submodule update --remote --merge clearhead-cli
git add clearhead-cli
git commit -m "Update clearhead-cli to latest"
git push
```

### 4. Working Inside a Submodule

**Important:** When you `cd` into a submodule directory, you're entering a completely separate git repository.

```bash
cd clearhead-cli

# By default, submodules are in "detached HEAD" state
# Always check out a branch before making changes:
git checkout main  # or master, depending on the repo

# Work normally
git pull
# make your changes...
git add .
git commit -m "Add new feature"
git push

# Now update the parent repo to reference this new commit:
cd ..
git add clearhead-cli
git commit -m "Update clearhead-cli to include new feature"
git push
```

### 5. Checking Submodule Status

To see which commits each submodule is currently pointing to:

```bash
git submodule status
```

Output explanation:
- No prefix: submodule is at the recorded commit
- `+` prefix: submodule has newer commits than recorded (you should probably commit this in the parent)
- `-` prefix: submodule is not initialized yet
- `U` prefix: submodule has merge conflicts

## Common Pitfalls & How to Avoid Them

### Pitfall 1: "Detached HEAD" State

**Problem:** You make changes in a submodule but it's in detached HEAD state, then lose your work.

**Solution:** Always `git checkout main` (or `master`) before making changes in a submodule.

### Pitfall 2: Forgetting to Push Submodule Changes

**Problem:** You commit changes in a submodule and update the parent repo, but forget to push the submodule itself. Others can't pull your changes.

**Solution:** Always push the submodule first, then the parent:

```bash
cd clearhead-cli
git push  # push submodule changes
cd ..
git push  # push parent repo
```

### Pitfall 3: Accidentally Committing Unintended Submodule Changes

**Problem:** You pull latest in a submodule for testing, then accidentally commit that reference change in the parent repo.

**Solution:** Use `git submodule status` and `git diff` to check before committing:

```bash
git submodule status  # see what changed
git diff clearhead-cli  # see the commit difference
```

### Pitfall 4: Merge Conflicts in Submodule References

**Problem:** Two people update the same submodule to different commits, causing conflicts.

**Solution:**
```bash
cd <submodule-name>
git checkout main
git pull
cd ..
git add <submodule-name>
git commit -m "Resolve submodule conflict"
```

## Advanced Operations

### Creating a New Branch Across All Submodules

Useful when implementing a feature that spans multiple projects:

```bash
# In each submodule:
git submodule foreach 'git checkout -b feature-name'
```

### Running a Command in All Submodules

```bash
git submodule foreach 'git pull'
git submodule foreach 'git status'
```

### Checking Out a Specific Historic State

To checkout the platform repo at a specific point in time (with all correct submodule versions):

```bash
git checkout <commit-hash>
git submodule update --init --recursive
```

### Removing a Submodule

If you ever need to remove a submodule:

```bash
# 1. Remove from .gitmodules
git config -f .gitmodules --remove-section submodule.<name>

# 2. Remove from .git/config
git config -f .git/config --remove-section submodule.<name>

# 3. Remove from index
git rm --cached <path>

# 4. Remove directory
rm -rf <path>

# 5. Commit
git commit -m "Remove <name> submodule"
```

## Quick Reference

| Task | Command |
|------|---------|
| Clone with submodules | `git clone --recurse-submodules <url>` |
| Initialize submodules after clone | `git submodule update --init --recursive` |
| Update all submodules to latest | `git submodule update --remote --merge` |
| Check submodule status | `git submodule status` |
| Run command in all submodules | `git submodule foreach '<command>'` |
| Checkout branch in submodule | `cd <submodule> && git checkout <branch>` |

## Integration with ClearHead Workflow

Since you're using the `next.actions` file format throughout these projects, here's a recommended workflow:

1. **View all tasks across projects:**
   ```bash
   # From platform root, find all action files:
   find . -name "*.actions" -o -name "next.actions"
   ```

2. **Work on a task in a submodule:**
   - `cd` into the submodule
   - Check out a branch: `git checkout main`
   - Update the local `next.actions` file
   - Make your code changes
   - Commit and push in the submodule
   - Return to platform root and commit the submodule reference

3. **Keep everything in sync:**
   - Regularly run `git submodule update --remote --merge` to stay current
   - Use `git submodule foreach 'git status'` to check if any submodule has uncommitted work

## Need Help?

If you get into a weird state:

1. Check what's going on: `git submodule status`
2. See if any submodule has uncommitted changes: `git submodule foreach 'git status'`
3. Reset to a known good state: `git submodule update --init --recursive --force`

Remember: The platform repo is just coordinating the submodules. Each submodule is independent, and you can always `cd` into them and use normal git commands.
