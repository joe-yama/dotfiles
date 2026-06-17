---
paths:
  - "private_dot_ssh/**"
  - "dot_gitconfig"
  - "dot_gitconfig-personal.tmpl"
---

# Multi-GitHub Account Setup

## SSH Host Aliases
- `private_dot_ssh/private_config.d/github.conf`
- Work: `github.com`, Personal: `github-personal`

## 1Password SSH Agent
- `IdentityFile` points to `.pub` hint file, `IdentitiesOnly yes` required
- Public keys must exist at `~/.ssh/*.pub` — 1Password Agent needs them as hints

## Git Config
- `dot_gitconfig`: `includeIf gitdir:` for directory-based identity switching
- `dot_gitconfig-personal.tmpl`: `url.insteadOf` for automatic SSH host rewriting
