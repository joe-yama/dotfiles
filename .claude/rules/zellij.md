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

### IME ON でのモード内キー操作（config.kdl）

- 問題: IME ON だとモード内のベアキー（`n` 等）が未確定文字に食われ、Zellij ショートカットが効かない
- 対策: pane モードの各 bind に `Ctrl+<key>` 版を併記（例 `bind "n" "Ctrl n"`）。Ctrl 系は IME を素通りする
- 前提: `support_kitty_keyboard_protocol true`（`Ctrl+h`=BS/`Ctrl+j`=Enter 等の衝突を CSI-u で区別させるため）。無効化理由だった IME 描画バグは v0.44.1+ で解消済み
- 数字タブジャンプ（`1`〜`9`）は IME ON 非対応の穴として容認: bare=IME食う / Ctrl=protocol が数字を昇格せず届かない / Alt(+Shift)=AeroSpace が奪取。IME ON 時は `Ctrl+n`/`Ctrl+p` 循環で代替
- `Ctrl c` は pane 脱出（`shared_except`）に割当済みのため multitask(`c`) は bare のみ。IME ON の脱出は Esc で可
