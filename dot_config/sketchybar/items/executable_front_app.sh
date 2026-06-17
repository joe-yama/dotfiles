#!/bin/bash

sketchybar --add item front_app left \
  --set front_app \
    icon.drawing=off \
    label.font="$FONT:Bold:17.0" \
    label.max_chars=24 \
    label.padding_left=8 \
    label.padding_right=8 \
    background.drawing=off \
    script="$CONFIG_DIR/plugins/front_app.sh" \
  --subscribe front_app front_app_switched
