#!/usr/bin/env bash
set -euo pipefail

# mlx-serve (ddalcu、Zig+Metal のネイティブ LLM サーバー) の公式リリースバイナリを
# ~/.local/opt/mlx-serve に配置する。llama.cpp と同じ方式 (build/version を dotfiles で固定)。
#
# 2026-09-05 の実機 A/B で Qwen3.8-Flash-Next の decode が llama.cpp の約 2 倍
# (short 70 vs 34 tok/s、24k 後 58 vs 26 tok/s) だったため、llama-swap の両エントリ
# (本命 / 無検閲) を mlx-serve に切り替えた。詳細: docs/mlxserve-ab-20260905.md
#
# Homebrew formula (ddalcu/mlx-serve tap) は同じ tarball を入れて install_name_tool で
# rpath を書き換えるだけ。tarball の配置 (mlx-serve-macos-arm64/{mlx-serve,lib/}) を
# 崩さなければ @executable_path/lib のまま動くので、formula を経由せず直接展開する。
#
# 更新手順: MLX_SERVE_VERSION と MLX_SERVE_SHA256 を書き換える (sha256 は
#           https://raw.githubusercontent.com/ddalcu/mlx-serve/main/Formula/mlx-serve.rb に載る)
#           → chezmoi apply (この script が再実行される)
#           → launchctl kickstart -k gui/$UID/local.llama-swap
# llama-swap は ~/.config/llama-swap/config.yaml の macro `mlx_serve` で
# ~/.local/opt/mlx-serve/current/mlx-serve-macos-arm64/mlx-serve を参照する。
#
# モデルは ~/.mlx-serve/models/<org>/<repo>/ に置く (`mlx-serve pull <org/repo>` か手動)。
# ⚠️ `mlx-serve pull` は既存ディレクトリの欠落シャードを検出しないので、手動取得したときは
#    HF API (?blobs=true) の siblings サイズと全ファイルを照合すること。
MLX_SERVE_VERSION="26.9.1"
MLX_SERVE_SHA256="b9bb5178ac2dcfbfa232ffa1e6ce77e87a6408a540cbdaabb66d101d667590b0"

PREFIX="$HOME/.local/opt/mlx-serve"
DEST="$PREFIX/mlx-serve-$MLX_SERVE_VERSION"
BIN="$DEST/mlx-serve-macos-arm64/mlx-serve"
ARCHIVE="mlx-serve-bin-macos-arm64.tar.gz"
URL="https://github.com/ddalcu/mlx-serve/releases/download/v$MLX_SERVE_VERSION/$ARCHIVE"

if [ -x "$BIN" ]; then
  echo "mlx-serve $MLX_SERVE_VERSION already installed at $DEST"
else
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  echo "Downloading $URL"
  curl -fsSL -o "$tmp/$ARCHIVE" "$URL"
  echo "$MLX_SERVE_SHA256  $tmp/$ARCHIVE" | shasum -a 256 -c -
  mkdir -p "$DEST"
  # tarball のトップディレクトリは mlx-serve-macos-arm64/ (中に mlx-serve と lib/)
  tar xzf "$tmp/$ARCHIVE" -C "$DEST"
  test -x "$BIN"
fi

ln -sfn "mlx-serve-$MLX_SERVE_VERSION" "$PREFIX/current"
"$PREFIX/current/mlx-serve-macos-arm64/mlx-serve" --version

# 旧 version は残す (戻し用)。手で消す: rm -rf ~/.local/opt/mlx-serve/mlx-serve-<旧>
