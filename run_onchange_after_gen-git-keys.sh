#!/usr/bin/env bash
set -euo pipefail

# Git が使う SSH 鍵 (署名用・認証用) をディスク上に用意する。
#
# どちらも以前は 1Password Agent を経由していたが、Agent は鍵を使うたびに
# GUI の承認ダイアログを出すため、非対話で動く Agent の作業が止まる。
# 署名 (op-ssh-sign) と認証 (ssh agent) の両方を専用鍵に切り替えて
# 1Password Agent を完全にバイパスしている。
#
# dot_gitconfig で commit.gpgsign = true なので、署名鍵が無いと git commit が
# 必ず失敗する。認証鍵が無ければ push/fetch ができない。
# 新しいマシンでも apply の時点で生成しておく。
#
# 生成される鍵は chezmoi/Git の管理外 (マシンごとに別物)。
# 新しいマシンでは GitHub の該当アカウントへの登録が必要 —
# 署名鍵は Signing key、認証鍵は Authentication key として登録する。

generate() {
  local path="$1"
  local kind="$2"

  if [[ -f "$path" ]]; then
    return 0
  fi

  ssh-keygen -t ed25519 -N '' -C "$(basename "$path")@$(hostname -s)" -f "$path" >/dev/null
  chmod 600 "$path"
  chmod 644 "$path.pub"

  echo "generated $path"
  echo "  GitHub の該当アカウントに **$kind** として登録してください:"
  echo "  $(cat "$path.pub")"
}

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# 署名鍵 — user.signingkey から参照する
generate "$HOME/.ssh/git-signing-work"     "Signing key"         # ~/.gitconfig.local    (会社 identity)
generate "$HOME/.ssh/git-signing-personal" "Signing key"         # ~/.gitconfig-personal (個人 identity)

# 認証鍵 — ~/.ssh/config.d/github.conf の IdentityFile から参照する
generate "$HOME/.ssh/git-auth-work"        "Authentication key"  # Host github.com
generate "$HOME/.ssh/git-auth-personal"    "Authentication key"  # Host github-personal
