#!/bin/bash

sketchybar --add item brew right \
  --set brew \
    icon="$ICON_BREW" \
    icon.color=$GREEN \
    click_script="open -a Terminal" \
    drawing=off \
    label.drawing=off \
    update_freq=3600 \
    script="$CONFIG_DIR/plugins/brew.sh"
