---
description: Use when working with Jujutsu VCS (jj), including jj status, jj log, jj describe, jj new, jj bookmark, jj git push/fetch, jj rebase, jj squash, jj split, jj absorb, jj undo, jj op log, or when a repository has a .jj/ directory. Do not use for pure git commands (git add, git commit) or gh CLI operations.
metadata:
    github-path: skills/jj
    github-ref: refs/heads/main
    github-repo: https://github.com/edgesd/skills
    github-tree-sha: 42fb071c25625e8994a36504bdbc507e14668da0
name: jj
---
# Jujutsu VCS (jj)

## Mental Model — 5 Differences from Git

| Concept | Git | jj |
|---------|-----|-----|
| Staging | `git add` → index → commit | No staging. Working copy IS a commit (auto-updated) |
| Current state | HEAD + dirty working tree | `@` — the working copy commit (always clean conceptually) |
| Branch identity | Branch = mutable pointer | Change ID — stable across rewrites. Commit ID changes on edit |
| Merge conflicts | Blocked until resolved | First-class: conflicts stored, work continues |
| Undo | Complex (`reflog`) | `jj undo` / `jj op log` — full operation history |

**Key insight:** Every file save auto-amends `@`. There is no "uncommitted work" — only the working copy commit.

## Core Rules

**Detect jj repo:** `.jj/` directory exists (colocated repos also have `.git/`)

**Command patterns:**
- Use `jj` commands, NOT `git` commands for VCS operations
- Exception: `gh` CLI for GitHub PR/issue operations is fine
- Colocated repo: `jj` and `git` are in sync; prefer `jj` for all history operations
- Never run `git commit` — use `jj describe` + `jj new`
- Never run `git checkout` — use `jj edit <change>` or `jj new <rev>`

**Before any destructive operation** (abandon, rebase onto different base): confirm with user.

## Quick Command Reference

### Status & Inspection

| Task | Command |
|------|---------|
| Show working copy status | `jj status` or `jj st` |
| Show commit graph | `jj log` |
| Show compact log | `jj log -r 'mutable()'` |
| Show diff of working copy | `jj diff` |
| Show diff of specific change | `jj diff -r <change>` |
| Show specific file diff | `jj diff <file>` |

### Creating & Editing Changes

| Task | Command |
|------|---------|
| Start new change (like `git checkout -b`) | `jj new` |
| New change on top of specific rev | `jj new <rev>` |
| Set commit message | `jj describe -m "message"` |
| Edit an existing change | `jj edit <change>` |
| Amend working copy message | `jj describe` (opens editor) |

### Bookmarks (= Git Branches)

| Task | Command |
|------|---------|
| List bookmarks | `jj bookmark list` |
| Create bookmark at `@` | `jj bookmark create <name>` |
| Create bookmark at rev | `jj bookmark create <name> -r <rev>` |
| Move bookmark to rev | `jj bookmark move <name> -r <rev>` |
| Delete bookmark | `jj bookmark delete <name>` |

### Git Interop

| Task | Command |
|------|---------|
| Fetch from remote | `jj git fetch` |
| Push bookmark | `jj git push --bookmark <name>` |
| Push all bookmarks | `jj git push --all` |
| Auto-push with generated name | `jj git push --change @-` |
| Sync colocated git | Automatic on every jj command |

### History Editing

| Task | Command |
|------|---------|
| Squash into parent | `jj squash` |
| Squash specific files | `jj squash <files>` |
| Split working copy | `jj split` |
| Absorb into ancestors | `jj absorb` |
| Rebase onto new parent | `jj rebase -d <dest>` |
| Rebase entire branch | `jj rebase -b <bookmark> -d <dest>` |

### Undo & Recovery

| Task | Command |
|------|---------|
| Undo last operation | `jj undo` |
| Show operation history | `jj op log` |
| Restore to past operation | `jj op restore <op-id>` |
| Show abandoned commits | `jj log -r 'hidden()'` |

## Workflows

### Feature Development

```
jj git fetch                           # Get latest remote changes
jj new main@origin                     # Start from latest main
jj describe -m "feat: add feature X"  # Set commit message
# ... make changes (auto-amends @) ...
jj bookmark create feature-x          # Create bookmark
jj git push --bookmark feature-x      # Push to remote
```

### PR/Review Cycle (incorporate review feedback)

```
jj git fetch                           # Get updated remote
jj edit <change-id>                    # Switch to the change to edit
# ... make review changes ...
jj describe -m "feat: updated message" # Update message if needed
jj rebase -d main@origin               # Rebase onto latest main
jj git push --bookmark feature-x      # Force-push (jj handles it)
```

### Conflict Resolution

```
jj log -r 'conflicts()'               # Find conflicted changes
jj edit <conflicted-change>           # Switch to it
jj resolve                            # Launch merge tool (or edit manually)
# After manual resolve, mark resolved:
jj resolve --list                     # Verify no more conflicts
```

### Undo / Recovery

```
jj op log                             # Show operation history
jj undo                               # Undo last operation
jj op restore <op-id>                 # Restore to specific point
```

## Revset Essentials

Revsets select commits. Use with `-r` flag: `jj log -r '<revset>'`

| Revset | Meaning |
|--------|---------|
| `@` | Working copy commit |
| `@-` | Parent of working copy |
| `trunk()` | Remote main branch (main/master) |
| `main@origin` | Remote tracking bookmark |
| `mutable()` | All non-immutable commits |
| `conflicts()` | Commits with conflicts |
| `bookmarks()` | All bookmark heads |
| `ancestors(@)` | All ancestors of `@` |
| `trunk()..@` | Commits between trunk and `@` |
| `description("fix")` | Commits containing "fix" in description |
| `author("alice")` | Commits by alice |

**Operators:** `x-` (parent), `x+` (child), `x::y` (range), `~x` (not x), `x & y` (and), `x | y` (or)

For advanced revset syntax: see `references/revsets-quick-reference.md`

## Important Notes

**Colocated repos:** Both `.jj/` and `.git/` exist. `jj` operations automatically sync `.git/`. Use `jj` for VCS work; only use raw `git` for operations jj doesn't support (e.g., signing configs).

**Empty working copy:** When `jj status` shows "The working copy is clean" — this is normal. `@` is an empty commit ready for new work.

**Immutable commits:** `trunk()` and tags are immutable by default. Use `jj rebase` to move changes; never try to edit them directly.

**Divergent changes:** If a Change ID has multiple commits (divergent), use `jj abandon` on unwanted copies.

**Colocated git interop details:** see `references/git-interop.md`
**Advanced history editing:** see `references/history-editing.md`
**Config and aliases:** see `references/config-and-aliases.md`
