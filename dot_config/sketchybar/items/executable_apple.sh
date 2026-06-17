#!/bin/bash

sketchybar --add item apple left \
  --set apple \
    icon="$ICON_APPLE" \
    icon.color=$TEXT \
    icon.font="PlemolJP Console NF:Bold:22.0" \
    label.drawing=off \
    padding_right=6 \
    script="$CONFIG_DIR/plugins/apple.sh" \
    click_script="osascript -e 'tell application \"System Events\" to click menu bar item 1 of menu bar 1 of application process \"Finder\"'"
