#!/bin/bash

sketchybar --add item battery right \
  --set battery \
    icon="$ICON_BATTERY_FULL" \
    icon.color=$GREEN \
    click_script="open 'x-apple.systempreferences:com.apple.battery-settings'" \
    update_freq=120 \
    script="$CONFIG_DIR/plugins/battery.sh" \
  --subscribe battery power_source_change system_woke
