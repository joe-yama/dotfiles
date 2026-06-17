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
- `.tmpl` files call 1Password — run `op signin` first or chezmoi hangs
- Brewfile: third-party tap formulas need full path (`brew "k1LoW/tap/mo"`, not `brew "mo"`)

## Secrets — NEVER commit

- `.tmpl` templates: `{{ onepasswordRead "op://vault/item/field" }}` — vault/item must match exactly
- `dot_claude/dot_env`: plain file (NOT template) with native `op://` references

## Claude Code Settings (`dot_claude/private_settings.json`)

- `DISABLE_TELEMETRY`, `DISABLE_ERROR_REPORTING`, `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` は GrowthBook フィーチャーフラグ取得をブロックする — これらを設定すると Auto Mode や Opus 1M など GrowthBook 管理の機能が利用不可になる
- Auto Mode が「not available on your plan」になる場合、まず `~/.claude.json` の `cachedGrowthBookFeatures.tengu_auto_mode_config` を確認 — `"enabled": "disabled"` かつ上記 env var がある場合は env var が原因
- env var 削除後は `rm ~/.claude.json` でキャッシュクリア + CLI 再起動が必要
- 関連 Issue: anthropics/claude-code#34178, anthropics/claude-code#38450

## Tool-Specific Rules

- `.claude/rules/` にツール固有の規約を配置（`paths` スコープで該当ファイル編集時に自動読み込み）
- `~/.config/nvim/` is a separate repo — NOT managed here
