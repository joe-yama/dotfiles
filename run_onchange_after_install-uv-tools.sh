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
# Discord ゲートウェイの依存 (discord.py[voice]/brotlicffi/aiohttp) と edge-tts は
# hermes が実行時に lazy install するもので、hermes-agent 本体の依存ではない。
# `uv tool install --upgrade` は venv を作り直すので --with で明示しないと消える
# (2026-09-03 に踏んだ)。pin は hermes 同梱の tools/lazy_deps.py の
# platform.discord / tts.edge と同じ値。hermes 側が pin を上げたら実行時に
# 自動で入れ直すので、ここが古くても壊れはしない。
# rtk-hermes: bundled ではない pip 配布プラグイン (entry point `rtk-rewrite`)。
#   terminal 出力を rtk で圧縮する。config.yaml の plugins.enabled と Brewfile の
#   `brew "rtk"` が対になる。
# ddgs: bundled `web-ddgs` バックエンドの optional dep。import できれば
#   キー不要の DuckDuckGo 検索が自動で有効になる。
uv tool install --upgrade --python 3.12 hermes-agent \
  --with 'discord.py[voice]==2.7.1' \
  --with 'brotlicffi==1.2.0.1' \
  --with 'aiohttp==3.14.1' \
  --with 'edge-tts==7.2.7' \
  --with 'rtk-hermes' \
  --with 'ddgs'
