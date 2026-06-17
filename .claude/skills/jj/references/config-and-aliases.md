# Config and Aliases Reference

Load this file when setting up jj configuration, aliases, or tool integrations.

## Config File Locations

| Scope | Path | Purpose |
|-------|------|---------|
| User (global) | `~/.config/jj/config.toml` | Personal defaults |
| Repo | `.jj/repo/config.toml` | Per-repo settings |
| Workspace | `.jj/config.toml` | Per-workspace settings |

Edit with: `jj config edit --user` or `jj config edit --repo`

## Essential User Config

```toml
[user]
name = "Your Name"
email = "you@example.com"

[ui]
default-command = "log"              # Run jj log when just typing jj
editor = "nvim"                      # For jj describe, jj split, etc.
diff-editor = "vimdiff"              # For jj diffedit, jj split interactive

[git]
fetch = "origin"                     # Default remote for jj git fetch
push = "origin"                      # Default remote for jj git push

[merge-tools.vimdiff]
program = "vimdiff"
```

## Fork Setup

```toml
[git]
fetch = "upstream"                   # Fetch from upstream (original repo)
push = "origin"                      # Push to your fork
```

## Aliases

Define aliases in `[aliases]` section:

```toml
[aliases]
# Short forms
st = ["status"]
lg = ["log", "-r", "mutable()"]     # Show only my changes
ll = ["log", "--limit", "10"]       # Recent 10
br = ["bookmark", "list"]

# Common workflows
new-feature = ["new", "trunk()"]    # Start new feature from trunk
sync = ["git", "fetch"]             # Quick fetch

# Show conflicts
conflicts = ["log", "-r", "conflicts()"]
```

Usage: `jj lg` → runs `jj log -r mutable()`

## Log Templates

Customize `jj log` output:

```toml
[templates]
log = '''
separate(" ",
  format_short_change_id_with_hidden_and_divergent_info(self),
  bookmarks,
  tags,
  if(conflict, label("conflict", "conflict")),
  description.first_line(),
)
'''
```

## Colors

```toml
[colors]
"working_copy" = { bold = true, fg = "green" }
"conflict" = { fg = "red", bold = true }
```

## Common Operations via Config

### Auto-sign commits (GPG)

```toml
[signing]
sign-all = false
backend = "gpg"
key = "YOUR_GPG_KEY_ID"
```

### Configure merge tool

```toml
[merge-tools.meld]
program = "meld"
merge-args = ["$left", "$base", "$right", "-o", "$output"]

[merge-tools.vscode]
program = "code"
merge-args = ["--wait", "--merge", "$left", "$right", "$base", "$output"]
```

Set active: `jj config set --user ui.merge-editor "meld"`

## Viewing Config

```bash
jj config list                        # Show all effective config
jj config list --user                 # User config only
jj config list --repo                 # Repo config only
jj config get ui.editor               # Get specific value
jj config set --user ui.editor "vim"  # Set value
```

## Useful Shell Aliases (add to ~/.zshrc or ~/.bashrc)

```bash
alias jjl="jj log -r 'mutable()'"
alias jjs="jj status"
alias jjd="jj diff"
alias jjf="jj git fetch"
alias jjp="jj git push"
```

## Integration with git Tools

Since colocated repos have `.git/`, most git tools work:

- **lazygit**: Works for read-only inspection; avoid making commits/branches from it
- **GitLens (VSCode)**: Works for history viewing
- **git blame, git log**: Fine for inspection
- **GitHub Desktop**: Avoid — will create git commits directly

**Safe to use:** Any tool that only reads `.git/`
**Avoid:** Tools that write to `.git/` (commit, branch, merge)

## jj init Options

```bash
jj git init                          # New repo with git backend
jj git init --colocate               # Colocated (creates both .jj/ and .git/)
jj git clone <url>                   # Clone remote repo
jj git clone --colocate <url>        # Clone as colocated
```
