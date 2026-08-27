#!/usr/bin/env bash
set -euo pipefail

# uv管理のPythonツール群:
# - vllm-mlx: Apple Silicon向けOpenAI/Anthropic互換MLX推論サーバー
#   (llama-swap のバックエンド、~/.local/bin/vllm-mlx)
# - hermes-agent: Nous Research の Hermes Agent CLI。
#   Python <3.14 必須 (brew版は3.14ビルドで ThreadPoolExecutor 非互換クラッシュ)
#   のため uv で 3.12 を固定して導入する
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"

if ! command -v uv >/dev/null 2>&1; then
  echo "uv not found — skip uv tools install"
  exit 0
fi

uv tool install --upgrade vllm-mlx
uv tool install --upgrade --python 3.12 hermes-agent
