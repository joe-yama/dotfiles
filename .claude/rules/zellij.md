---
paths:
  - "dot_config/zellij/**"
---

# Zellij

## Config Structure
- Config: `dot_config/zellij/config.kdl`
- Layouts: `dot_config/zellij/layouts/` (`default.kdl`, `dev.kdl`, `quad.kdl`)

## Rules
- v0.44.0+: mode/direction names must be lowercase (`"normal"`, `"left"`)
- Plugins: pre-download to `~/.config/zellij/plugins/`, use `file:` references (Zellij HTTP client doesn't support proxies)
- `run_onchange_zellij-plugins.sh` handles plugin downloads; when updating a URL, delete the old `.wasm` first

## IME

- v0.44.0 以前: カーソル非表示時にホストターミナルへ CUP シーケンスを送信しないため、IME 未確定文字が正しい位置に表示されない
- v0.44.1+ (PR #4951): 修正済み — `brew install --HEAD zellij` でインストール中。安定版リリース後に通常版へ戻すこと
