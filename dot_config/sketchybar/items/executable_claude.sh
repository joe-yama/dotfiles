#!/usr/bin/env bash

sketchybar --add item claude right \
  --set claude \
    icon="$ICON_CLAUDE" \
    icon.font="ClaudeIcon:Regular:18.0" \
    icon.color=$SURFACE2 \
    icon.padding_left=6 \
    icon.padding_right=4 \
    label="--M" \
    label.font="$FONT:Bold:17.0" \
    label.color=$LABEL_DEFAULT \
    update_freq=60 \
    popup.align=right \
    popup.y_offset=4 \
    popup.horizontal=off \
    popup.background.color=$ISLAND_BG \
    popup.background.corner_radius=10 \
    popup.background.border_width=1 \
    popup.background.border_color=$ISLAND_BORDER \
    popup.background.padding_left=10 \
    popup.background.padding_right=10 \
    click_script="$CONFIG_DIR/plugins/claude_click.sh" \
    script="$CONFIG_DIR/plugins/claude.sh"

for entry in \
  "remaining:Remaining" \
  "input:Input" \
  "output:Output" \
  "cache:Cache R/W" \
  "cost:Cost USD" \
  "burn:Burn Rate" \
  "models:Models"
do
  KEY="${entry%%:*}"
  LBL="${entry#*:}"
  sketchybar --add item "claude.popup.$KEY" popup.claude \
    --set "claude.popup.$KEY" \
      icon="$LBL" \
      icon.color=$SUBTEXT1 \
      icon.font="$FONT:Regular:14.0" \
      icon.padding_left=8 \
      icon.padding_right=12 \
      label="-" \
      label.color=$TEXT \
      label.font="$FONT:Regular:14.0" \
      label.padding_right=12 \
      background.drawing=off
done
