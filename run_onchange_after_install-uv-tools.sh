#!/usr/bin/env bash
set -euo pipefail

# uv管理のPythonツール群:
# - vllm-mlx: Apple Silicon向けOpenAI/Anthropic互換MLX推論サーバー
#   (llama-swap のバックエンド、~/.local/bin/vllm-mlx)
# Hermes Agent は 2026-11-08 に install.sh 方式へ移行した
# (run_onchange_after_install-hermes.sh)。ここで uv tool として入れ直すと
# ~/.local/bin/hermes を旧 PyPI 版 (0.19.0) で上書きするので戻さないこと。
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"

if ! command -v uv >/dev/null 2>&1; then
  echo "uv not found — skip uv tools install"
  exit 0
fi

uv tool install --upgrade vllm-mlx
