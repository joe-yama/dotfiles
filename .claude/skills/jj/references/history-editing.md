# History Editing Reference

Load this file for advanced history editing: split, squash, rebase, absorb, and conflict resolution.

## Key Insight

Unlike git, history editing in jj is **safe and non-destructive**: the original commits remain accessible via `jj op log` until garbage collected. Change IDs remain stable across rewrites.

## squash — Fold into Parent

```bash
jj squash                            # Squash @ into its parent
jj squash -r <change>               # Squash specific change into its parent
jj squash <files>                   # Squash only specific files from @ into parent
jj squash --interactive             # Select hunks interactively
```

Use when: Current change is a fixup for the parent, WIP commits, clean up before push.

## split — Divide One Change

```bash
jj split                            # Interactive hunk selection to split @
jj split <files>                    # Split by files: first part gets listed files
jj split -r <change>               # Split a specific change
```

After split, you'll have two changes where there was one. The first gets the files you selected; the second gets the rest.

## absorb — Distribute Changes into Ancestors

```bash
jj absorb                           # Auto-distribute @ changes into appropriate ancestors
jj absorb <files>                   # Absorb only specific files
```

**How it works:** For each changed line in `@`, `jj absorb` finds the most recent ancestor that last touched that line and squashes the change there. Remaining unabsorbable changes stay in `@`.

Use when: You have fixup changes that each belong in different ancestors.

## rebase — Move Changes

### Rebase working copy onto new base
```bash
jj rebase -d main@origin             # Rebase @ onto latest main
jj rebase -d <change-id>             # Rebase @ onto specific change
```

### Rebase a specific change
```bash
jj rebase -r <change> -d <dest>     # Move single change (children stay)
```

### Rebase a branch (change + all descendants)
```bash
jj rebase -b <bookmark> -d <dest>   # Rebase entire bookmark branch
jj rebase -s <change> -d <dest>     # Rebase change and all its descendants
```

### Rebase flags
| Flag | Meaning |
|------|---------|
| `-r` | Rebase only this revision (leave children behind) |
| `-s` | Rebase this revision and all descendants |
| `-b` | Rebase the entire branch for this bookmark |
| `-d` | Destination (new parent) |

## describe — Edit Commit Message

```bash
jj describe                          # Edit @ message in $EDITOR
jj describe -m "new message"        # Set @ message directly
jj describe -r <change>             # Edit specific change's message
```

## abandon — Delete a Change

```bash
jj abandon                           # Abandon @, move to parent
jj abandon <change>                  # Abandon specific change
jj abandon <change1> <change2>       # Abandon multiple
```

**Warning:** Abandoning is safe (op log preserves it), but confirm before abandoning changes with useful work.

## diffedit — Edit Changes Interactively

```bash
jj diffedit                          # Edit @ contents in diff editor
jj diffedit -r <change>             # Edit specific change
```

Opens a diff editor to add/remove/modify file changes within a commit.

## restore — Restore File Contents

```bash
jj restore <files>                   # Restore files in @ to parent's state
jj restore --from <change> <files>  # Restore files from specific change
jj restore --to <change> <files>    # Restore files in specific change
```

## Conflict Resolution

### Detecting Conflicts
```bash
jj log -r 'conflicts()'             # Show all conflicted changes
jj status                           # Shows if @ has conflicts
```

### Resolving
```bash
jj resolve                          # Launch merge tool for @ conflicts
jj resolve --list                   # List unresolved conflicts
jj resolve <file>                   # Resolve specific file
```

### Manual Resolution
Edit files directly — conflict markers look like:
```
<<<<<<< Conflict 1 of 1
+++++++ Contents of side #1
content from one side
------- Contents of base
original content
+++++++ Contents of side #2
content from other side
>>>>>>> Conflict 1 of 1
```

After editing, `jj status` should show no more conflicts.

### Abandoning a Conflicted Merge
If a rebase creates unwanted conflicts:
```bash
jj undo                              # Undo the rebase
```

## Typical Multi-Change Cleanup Workflow

Before pushing a feature branch:

```bash
# See what you have
jj log -r 'trunk()..@'

# Absorb WIP fixes into their natural parents
jj absorb

# Split an overly large change
jj edit <large-change>
jj split

# Clean up commit messages
jj describe -r <change> -m "better message"

# Rebase onto latest main
jj rebase -d trunk()

# Push
jj git push --bookmark feature-x
```

## Operation Log (undo history)

```bash
jj op log                            # Show all operations
jj op show <op-id>                   # Show what an operation changed
jj undo                              # Undo last operation
jj op restore <op-id>               # Restore to exact state at operation
```

Operations are indexed from newest. `jj undo` is equivalent to `jj op restore @-` on the operation log.
