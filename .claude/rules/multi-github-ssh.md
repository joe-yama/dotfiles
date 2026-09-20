---
paths:
  - "private_dot_ssh/**"
  - "dot_gitconfig"
  - "dot_gitconfig-personal.tmpl"
  - "dot_gitconfig.local.tmpl"
  - "run_onchange_after_gen-git-keys.sh"
---

# Multi-GitHub Account Setup

## SSH Host Aliases
- `private_dot_ssh/private_config.d/github.conf`
- Work: `github.com`, Personal: `github-personal`

## 1Password Agent は経由しない (署名・認証とも)
- 承認ダイアログで Agent の作業が止まるため、GitHub 向けは 1Password Agent を使わない
- `IdentityAgent none` を消さない — 消すと Agent に問い合わせが戻り承認待ちが復活する
- `gpg.ssh.program` に `op-ssh-sign` を復活させない — 同じ理由
- 1Password Agent 自体は他ホスト向けに生きている (`SSH_AUTH_SOCK` は変更しない)

## ディスク上の鍵
- `run_onchange_after_gen-git-keys.sh` が 4 本生成 (chezmoi/Git 管理外・マシンごと)
- 署名: `~/.ssh/git-signing-work` / `git-signing-personal` → `user.signingkey`
- 認証: `~/.ssh/git-auth-work` / `git-auth-personal` → `IdentityFile`
- 新しいマシンでは各鍵を対応アカウントに登録が必要
  — 署名鍵は **Signing key**、認証鍵は **Authentication key** (種別を間違えると push も署名検証も通らない)

## Git Config
- `dot_gitconfig`: `includeIf gitdir:` for directory-based identity switching
- `dot_gitconfig-personal.tmpl`: `url.insteadOf` for automatic SSH host rewriting
