#!/bin/bash

sketchybar --add item clock.date right \
  --set clock.date \
    icon.drawing=off \
    label.font="$FONT:Regular:15.0" \
    label.color=$OVERLAY1 \
    label.padding_left=0 \
    padding_left=0

sketchybar --add item clock right \
  --set clock \
    icon="$ICON_CLOCK" \
    icon.color=$LAVENDER \
    label.font="$FONT:Bold:17.0" \
    label.color=$TEXT \
    label.padding_right=4 \
    click_script="open -a Calendar" \
    update_freq=1 \
    script="$CONFIG_DIR/plugins/clock.sh"
