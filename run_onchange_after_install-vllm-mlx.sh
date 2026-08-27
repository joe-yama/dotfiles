#!/usr/bin/env bash
set -euo pipefail

# vllm-mlx: Apple Silicon向けOpenAI/Anthropic互換MLX推論サーバー。
# llama-swap のバックエンドとして ~/.local/bin/vllm-mlx を使う。
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"

if ! command -v uv >/dev/null 2>&1; then
  echo "uv not found — skip vllm-mlx install"
  exit 0
fi

uv tool install --upgrade vllm-mlx
