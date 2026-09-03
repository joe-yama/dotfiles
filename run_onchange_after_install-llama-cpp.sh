#!/usr/bin/env bash
set -euo pipefail

# llama.cpp 公式ビルド (macOS arm64 / Metal 有効) を ~/.local/opt/llama.cpp に配置する。
#
# Homebrew の llama.cpp formula は -DLLAMA_USE_SYSTEM_GGML=ON で別 formula `ggml`
# に依存しており ("ggml を同梱する PR は全部却下" と formula に明記)、ggml formula
# (stable 0.22.0 / HEAD も ggml リポジトリの同期待ち) が llama.cpp master に追い付く
# まで `brew install --HEAD llama.cpp` はビルドできない (2026-09-03 に
# `ggml_flash_attn_ext_set_n_kv_max` 未定義で失敗)。公式リリースは build ごとに
# バイナリを配布しているので、それを取って build 番号を dotfiles で固定する。
#
# 更新手順: LLAMA_CPP_BUILD を書き換える → chezmoi apply (この script が再実行される)
#           → launchctl kickstart -k gui/$UID/local.llama-swap
# llama-swap は ~/.config/llama-swap/config.yaml の macro `llama_server` で
# ~/.local/opt/llama.cpp/current/llama-server を参照する。
#
# 必要 build: b10767+ (qwen4exp 修正 #27941 / #28123 / #28023 を含む。2026-09-01)
LLAMA_CPP_BUILD="b10769"

PREFIX="$HOME/.local/opt/llama.cpp"
DEST="$PREFIX/llama-$LLAMA_CPP_BUILD"
ARCHIVE="llama-$LLAMA_CPP_BUILD-bin-macos-arm64.tar.gz"
URL="https://github.com/ggml-org/llama.cpp/releases/download/$LLAMA_CPP_BUILD/$ARCHIVE"

if [ -x "$DEST/llama-server" ]; then
  echo "llama.cpp $LLAMA_CPP_BUILD already installed at $DEST"
else
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  echo "Downloading $URL"
  curl -fsSL -o "$tmp/$ARCHIVE" "$URL"
  mkdir -p "$PREFIX"
  # tarball のトップディレクトリが llama-<build>/ なので PREFIX 直下に展開すると DEST になる
  tar xzf "$tmp/$ARCHIVE" -C "$PREFIX"
  test -x "$DEST/llama-server"
fi

ln -sfn "llama-$LLAMA_CPP_BUILD" "$PREFIX/current"
"$PREFIX/current/llama-server" --version

# 旧 build は残す (戻し用)。手で消す: rm -rf ~/.local/opt/llama.cpp/llama-b<旧>
