---
paths:
  - "dot_zshrc"
  - "dot_zshenv"
  - "dot_zprofile"
---

# ZSH Configuration

## Config
- `dot_zshrc` — Oh-My-Zsh base (robbyrussell theme)

## Rules
- Oh-My-Zsh runs `compinit` in `oh-my-zsh.sh` — do NOT call `compinit` again in `dot_zshrc`
- fpath additions must come BEFORE `source $ZSH/oh-my-zsh.sh` (so Oh-My-Zsh compinit picks them up)
- `ZSH_DISABLE_COMPFIX=true` skips compaudit for faster startup

## Pitfalls
- `alias "cmd sub"="..."` (space in alias name) does NOT work in zsh — use a function wrapper for subcommand aliases
- worktrunk: `wt config shell init zsh` defines a `wt()` shell function — wrap it via `functions[__orig]="$functions[wt]"`, then redefine `wt()`

## Patterns
- pyenv: lazy init pattern (shims PATH set immediately, `eval` deferred to first invocation via function wrapper)
- mise: eager activation (`eval "$(mise activate zsh)"` — NOT lazy, chpwd 自動切替フックのため)。Java/JDK (Temurin) を管理。Python は引き続き pyenv が担当。グローバル設定は `dot_config/mise/config.toml`
- jj completion: cached at `~/.cache/jj/completion.zsh` (regenerated only on version change)

## Debugging (user reference)
- Startup speed: `for i in 1 2 3 4 5; do /usr/bin/time zsh -i -c exit 2>&1; done`
- Profiling: `zsh -c 'zmodload zsh/zprof; source ~/.zshrc; zprof'`
