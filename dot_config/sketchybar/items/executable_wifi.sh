#!/bin/bash

sketchybar --add item wifi right \
  --set wifi \
    icon="$ICON_WIFI" \
    icon.color=$SAPPHIRE \
    label.drawing=off \
    click_script="open 'x-apple.systempreferences:com.apple.wifi-settings-extension'" \
    update_freq=10 \
    script="$CONFIG_DIR/plugins/wifi.sh" \
  --subscribe wifi wifi_change system_woke
