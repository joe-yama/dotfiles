# Revset Language Quick Reference

Load this file when you need detailed revset syntax beyond what's in SKILL.md.

## Symbols

| Symbol | Meaning |
|--------|---------|
| `@` | Working copy commit in current workspace |
| `<workspace>@` | Working copy in another workspace |
| `<name>@<remote>` | Remote-tracking bookmark (e.g., `main@origin`) |
| Full/prefix commit ID | Unique prefix of commit or change ID |

**Resolution priority:** Tag → Bookmark → Git ref → Commit/Change ID

## Operators (high to low precedence)

| Operator | Meaning | Example |
|----------|---------|---------|
| `x-` | Parents of x | `@-` (parent of working copy) |
| `x+` | Children of x | `main+` |
| `x::y` | DAG range (x to y inclusive) | `trunk()::@` |
| `x..` | Descendants of x (exclusive) | `trunk()..` |
| `..x` | Ancestors of x (exclusive) | `..@` |
| `~x` | Not x | `~trunk()` |
| `x & y` | Intersection | `mutable() & bookmarks()` |
| `x ~ y` | Difference (x but not y) | `all() ~ immutable_heads()` |
| `x \| y` | Union | `@\|main` |

**Note:** `x::y` == `ancestors(y) & descendants(x)`

## Navigation Functions

| Function | Description |
|----------|-------------|
| `parents(x)` | Direct parents |
| `children(x)` | Direct children |
| `ancestors(x)` | All ancestors (transitive parents) |
| `descendants(x)` | All descendants (transitive children) |
| `first_parent(x)` | First parent only (follows mainline) |
| `first_ancestors(x)` | Ancestors via first parent only |
| `connected(x)` | Commits reachable between any two commits in x |
| `heads(x)` | Commits in x with no children in x |
| `roots(x)` | Commits in x with no parents in x |

## Reference Functions

| Function | Description |
|----------|-------------|
| `bookmarks([pattern])` | All local bookmark heads (or matching pattern) |
| `remote_bookmarks([name], [remote])` | Remote bookmark heads |
| `tags([pattern])` | Tag targets |
| `trunk()` | Default remote's main bookmark (alias) |
| `immutable_heads()` | `trunk() \| tags() \| untracked_remote_bookmarks()` |
| `mutable()` | All commits NOT in `immutable_heads()::` |
| `visible_heads()` | Heads of visible commits |
| `root()` | Root commit |
| `all()` | All visible commits |
| `none()` | Empty set |

## Filter Functions

| Function | Description |
|----------|-------------|
| `description(pattern)` | Full description matches pattern |
| `subject(pattern)` | First line of description matches |
| `author(pattern)` | Author name or email matches |
| `committer(pattern)` | Committer name or email matches |
| `author_date(pattern)` | Author date matches |
| `committer_date(pattern)` | Committer date matches |
| `files(expression)` | Commits touching matching files |
| `empty()` | Commits with no file changes |
| `merges()` | Merge commits (2+ parents) |
| `conflicts()` | Commits with conflicts |
| `divergent()` | Change IDs with multiple visible commits |

## Pattern Types (for description, author, files, etc.)

| Pattern | Syntax | Example |
|---------|--------|---------|
| Substring | `"text"` or `substring:"text"` | `description("fix")` |
| Exact | `exact:"text"` | `author(exact:"alice@example.com")` |
| Glob | `glob:"pattern"` | `files(glob:"src/*.rs")` |
| Regex | `regex:"pattern"` | `description(regex:"^feat:")` |
| Case-insensitive | append `-i` | `description(regex-i:"fix")` |

## Date Patterns

```
author_date(after:"2024-01-01")
author_date(before:"2024-02-01T12:00:00")
author_date(after:"1 week ago")
author_date(after:"yesterday")
```

## Utility Functions

| Function | Description |
|----------|-------------|
| `latest(x, [count])` | Most recent N commits from x (default 1) |
| `fork_point(x)` | Common ancestor of commits in x |
| `exactly(x, count)` | Error if x doesn't contain exactly N commits |
| `at_operation(op, x)` | Evaluate x at past operation state |

## Common Patterns

```bash
# Everything I've changed (not yet in main)
jj log -r 'trunk()..@'

# All my local changes
jj log -r 'mutable()'

# Commits with conflicts
jj log -r 'conflicts()'

# Commits touching a specific file
jj log -r 'files("src/main.rs")'

# Recent commits by me
jj log -r 'author("myname") & latest(all(), 20)'

# All bookmark heads
jj log -r 'bookmarks()'

# Commits between two bookmarks
jj log -r 'feature-a..feature-b'

# Find divergent changes (needs cleanup)
jj log -r 'divergent()'
```
