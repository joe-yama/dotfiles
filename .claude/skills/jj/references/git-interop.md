# Git Interop & Colocated Workflow

Load this file for details on colocated jj+git setups, remote operations, and GitHub/GitLab integration.

## Colocated Repository Setup

A **colocated** repo has both `.jj/` and `.git/`:

```bash
jj git init --colocate          # New repo
jj git init --colocate --git-repo=. # Convert existing git repo
```

**Key behavior:**
- Every `jj` command auto-updates `.git/` (HEAD, refs, object store)
- Git sees repo in detached HEAD state — this is normal
- `git log` and `git diff` work for read-only inspection
- Never run `git commit`, `git checkout`, `git branch` — use jj equivalents

## Remote Operations

### Fetch

```bash
jj git fetch                          # Fetch all remotes
jj git fetch --remote origin          # Fetch specific remote
jj git fetch --remote upstream        # Fetch upstream (fork setup)
```

After fetch, remote bookmarks are updated. Local tracked bookmarks advance automatically.

### Push

```bash
jj git push --bookmark main           # Push named bookmark
jj git push --all                     # Push all bookmarks
jj git push --change @-               # Auto-name and push (generates bookmark name from change ID)
jj git push --allow-new --bookmark feat  # Push new bookmark (first time)
```

**Force-push behavior:** jj automatically handles force-push when history is rewritten. No `--force` flag needed.

### Setting Up Fork Remotes

```toml
# ~/.config/jj/config.toml or repo .jj/repo/config.toml
[git]
fetch = "upstream"   # jj git fetch uses upstream
push = "origin"      # jj git push uses origin
```

Then:
```bash
jj git remote add upstream https://github.com/original/repo
jj git remote add origin https://github.com/yourfork/repo
jj git fetch                     # Fetches from upstream
jj git push --bookmark feature   # Pushes to origin
```

## GitHub Workflow

### Option 1: Named Bookmark

```bash
# Start feature
jj git fetch
jj new trunk()
jj describe -m "feat: add feature X"
# ... work ...
jj bookmark create feat-x -r @
jj git push --allow-new --bookmark feat-x

# Update PR (after review)
jj edit <change-id>
# ... update ...
jj rebase -d trunk()
jj git push --bookmark feat-x     # auto force-pushes
```

### Option 2: Auto-generated Bookmark

```bash
jj git push --change @-           # Creates bookmark like push-<change-id>
```

Useful for quick one-off pushes. Note: bookmark name includes change ID prefix.

### GitHub CLI Integration (use gh directly)

```bash
gh pr create --head feat-x --base main
gh pr view 123
gh pr merge 123
```

`gh` CLI works normally since colocated repos are valid git repos.

## Tracking Remote Bookmarks

```bash
jj bookmark track main@origin        # Start tracking (enables auto-advance on fetch)
jj bookmark untrack main@origin      # Stop tracking
jj bookmark list --tracked           # Show tracked bookmarks
```

Newly-fetched remote bookmarks show as `bookmark@remote`. After tracking, local `bookmark` auto-advances on `jj git fetch`.

## Conflict with Remote

When `jj git push` fails due to remote divergence:

```bash
jj git fetch                         # Get latest remote state
jj log -r 'conflicts()'             # Check for conflicts
jj rebase -d main@origin             # Rebase local changes onto latest
jj git push --bookmark feat          # Retry push
```

## Colocated Repo Caveats

1. **`.git/HEAD` in detached state** — Expected. Git tools may warn about this.
2. **`git status` shows untracked `.jj/`** — Add `.jj/` to `.gitignore` if needed (it's in jj's own gitignore by default).
3. **Git hooks** — `.git/hooks/` still fire on git operations; jj operations do NOT trigger git hooks.
4. **`git stash`** — Don't use. Use `jj new` to start a new change instead.
5. **Mixed jj+git users** — Team members using plain git can work normally; their pushes are visible after `jj git fetch`.

## GitLab Push Options

```bash
jj git push --allow-new \
  -o merge_request.create \
  -o merge_request.target=main \
  -o merge_request.title="feat: my feature" \
  --bookmark feat-x
```
