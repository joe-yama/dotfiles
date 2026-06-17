---
paths:
  - "dot_config/sketchybar/**"
---

# SketchyBar

## Config Structure
- Main: `dot_config/sketchybar/executable_sketchybarrc`
- Items: `dot_config/sketchybar/items/`
- Plugins: `dot_config/sketchybar/plugins/`

## Rules
- All scripts need `executable_` prefix — sketchybar calls them via `sh`
- Reload after changes: `brew services restart sketchybar`

## AeroSpace Integration
- `exec-on-workspace-change` triggers `aerospace_workspace_change` event

## Theme: Catppuccin Mocha
- Colors: `executable_colors.sh`, Icons: `executable_icons.sh`
- Color format: 0xAARRGGBB

## Nerd Font Icons
- BMP PUA icons (U+E000-F8FF) are destroyed by Write/Edit tools
- Encode as UTF-8 byte sequences: `$'\xEF\x89\x80'`
- Do NOT use `$'\uXXXX'` — unsupported on macOS /bin/bash 3.2

## Bracket Pattern
- `bracket` groups items with a shared background (island design)
- Dynamic show/hide items: plugin must also toggle `background.drawing` on the bracket
- 1つの label 内で部分的にスタイル (色・フォント) を変えられない — 別アイテム + bracket でグループ化する

## Visual Height (bar color is transparent)
- `BAR_COLOR=0x00000000` — バー自体は透明なので `height` を変えても見た目は変わらない
- 見た目の高さは各 bracket/item の `background.height` が決める
- バーの高さ変更時は以下を **すべて** 連動して更新すること:
  1. `executable_sketchybarrc`: `height`, `notch_display_height`
  2. `executable_sketchybarrc`: 全 island bracket の `background.height`
  3. `items/executable_cpu.sh`, `items/executable_memory.sh`: グラフの `background.height`
  4. `plugins/executable_space.sh`: アクティブスペース・bracket 再構築の `background.height`
  5. `dot_config/aerospace/aerospace.toml`: per-monitor 構文で設定
     - 外部ディスプレイ: `outer.top` = height + y_offset
     - 内蔵ノッチディスプレイ: `outer.top` = notch_display_height + y_offset - notch_height(38)
     - 構文: `outer.top = [{ monitor."built-in" = <内蔵値> }, <外部値>]`
     - `monitor."built-in"` は regex (case-insensitive) で内蔵ノッチディスプレイ名に一致
     - `monitor.main` は使わない: clamshell で main=外部になり内蔵用 gap が外部に誤適用される
