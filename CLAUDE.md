# Dotfiles Repository (chezmoi-managed)

## VCS

- Use `jj`, NOT `git` for all VCS operations (jj/git colocated repo)
- `jj split` is interactive-only — use `jj new` + `jj restore --from <change>` instead
- `JJ_EDITOR=true jj squash` to suppress editor
- `git-secrets` hooks active — commits scanned for AWS/GitHub PAT patterns

## chezmoi Workflow

- **Edit source files in this repo ONLY** — never edit targets (`~/.config/...` etc.)
- After changes: `chezmoi apply <target>...` — 対象ファイルを明示する
- `chezmoi apply` に `--force` をつけない — 差分がある場合は `chezmoi diff <target>` で差分を確認し、ユーザーに採用する側を確認してからソースまたはターゲットを修正して差分を解消すること
- `chezmoi verify` (exit 0 = synced) for fast validation
- Naming: `dot_` = dotfile, `private_` = 0700/0600, `executable_` = 0755, `.tmpl` = template
- `executable_` prefix is REQUIRED for scripts — `chmod +x` alone won't survive `chezmoi apply`
- `private_` on a directory does NOT set files inside to 0600 — add `private_` prefix to each file too
- `chezmoi apply` は 1Password を呼ばない — identity 値は `.chezmoi.toml.tmpl` の `[data]` に焼いてある
- `.chezmoi.toml.tmpl` を変更したら `chezmoi init` が必要 (apply では反映されない) — ここでのみ `op` が走る
- `prompt = false` なので未サインイン時はハングせず即エラー — `op signin` してから再実行する
- `~/.hermes/.env` だけは apply 時に `op` を1回呼ぶ (引数なしの `chezmoi verify`/`diff`/`apply` も同様)
- Brewfile: third-party tap formulas need full path (`brew "k1LoW/tap/mo"`, not `brew "mo"`)

## Secrets — NEVER commit

- `.tmpl` templates: `{{ onepasswordRead "op://vault/item/field" }}` — vault/item must match exactly
- `dot_claude/dot_env`: plain file (NOT template) with native `op://` references。
  `~/.zshrc` の `_op_env_refresh` が `op inject` でこれを解決し `$TMPDIR/claude-mcp-env` (0600, TTL 8h) にキャッシュする。
  `claude` は zsh 関数でラップされており、起動時にキャッシュを更新して環境変数として MCP サーバーに継承させる
- identity (git/jj の name・email・signingkey) は `.chezmoi.toml.tmpl` の `[data.identity.*]` 経由。
  参照側は `{{ .identity.work.email }}` のように書く — テンプレートで `onepasswordRead` を直接呼ばない
