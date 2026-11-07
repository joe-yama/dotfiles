#!/usr/bin/env bash
set -euo pipefail

# Hermes Agent (Nous Research) の導入。2026-11-08 に uv tool (PyPI) から移行。
# - PyPI の hermes-agent は 0.19.0 で更新停止。上流の配布は install.sh のみで、
#   本体は ~/.hermes/hermes-agent (git checkout、stable channel)、Python は PM が
#   pin した 3.14 を使う。バージョンは git tag から読むので uv tool install git+... は不可。
# - 追加 pip は PM extras でのみ入れる (tools/lazy_deps.py は廃止、素の pip/uv は禁止)。
#   discord: Discord gateway / ddgs: キー不要の web 検索 / edge-tts: TTS
# - holographic (memory.provider) と rtk-rewrite は本体同梱から外れカタログの
#   community プラグインになった。rtk-rewrite は brew の rtk を PATH から使う。
# 初回導入だけここで行う。以降の更新は `hermes update` (stable channel)。
# 全処理は冪等。
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH"

HERMES_BOOTSTRAP_REF=v0.23.0
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"

# 旧方式 (uv tool) からの移行。残っていると ~/.local/bin/hermes が衝突する。
if command -v uv >/dev/null 2>&1 && uv tool list 2>/dev/null | grep -q '^hermes-agent '; then
  uv tool uninstall hermes-agent
fi

# .git だけだと clone 後の段階で失敗した install を検出できない。install.sh は
# 最終段で .hermes-bootstrap-complete を書き、再実行は repair として働く。
if [ ! -f "$HERMES_HOME/hermes-agent/.hermes-bootstrap-complete" ]; then
  curl -fsSL "https://raw.githubusercontent.com/NousResearch/hermes-agent/${HERMES_BOOTSTRAP_REF}/scripts/install.sh" \
    | bash -s -- --non-interactive --channel stable --skip-browser --skip-computer-use
fi

for extra in discord ddgs edge-tts; do
  hermes pm install --extra "$extra"
done

# chezmoi は config.yaml を先に書くので、holographic は plugins.enabled に載った状態で
# install される (= 稼働中プラグインの置き換え扱い)。その場合は Python 依存
# (numpy 等) の同意確認が出て、非 TTY では拒否になり exit 1 → --yes-deps で答える。
for plugin in holographic rtk-rewrite; do
  if [ ! -d "$HERMES_HOME/plugins/$plugin" ]; then
    hermes plugins install "$plugin" --yes-deps
  fi
done

# --non-interactive は install.sh の gateway 段を飛ばすので、新しいマシンでは
# Discord gateway の LaunchAgent が無い。登録は手動 (Discord トークンの .env が前提)。
if ! launchctl print "gui/$(id -u)/ai.hermes.gateway" >/dev/null 2>&1; then
  echo "hermes: gateway 未登録 — 'hermes gateway install --start-now --start-on-login' を実行すること"
fi
