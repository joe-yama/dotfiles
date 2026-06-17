#!/bin/bash

sketchybar --add event ime_changed "AppleSelectedInputSourcesChangedNotification" \
  --add item ime right \
  --set ime \
    icon.drawing=off \
    label.font="$FONT:Bold:17.0" \
    label.color=$MAUVE \
    label.width=28 \
    label.align=center \
    label.padding_left=0 \
    label.padding_right=0 \
    click_script="open 'x-apple.systempreferences:com.apple.Keyboard-Settings.extension'" \
    script="$CONFIG_DIR/plugins/ime.sh" \
  --subscribe ime ime_changed system_woke
