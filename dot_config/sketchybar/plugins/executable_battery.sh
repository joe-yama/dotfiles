#!/bin/bash

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

PERCENTAGE=$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)
PERCENTAGE=${PERCENTAGE:-0}
CHARGING=$(pmset -g batt | grep 'AC Power')

if [ -n "$CHARGING" ]; then
  ICON="$ICON_BATTERY_CHARGING"
  COLOR=$GREEN
elif [ "$PERCENTAGE" -gt 75 ]; then
  ICON="$ICON_BATTERY_FULL"
  COLOR=$GREEN
elif [ "$PERCENTAGE" -gt 50 ]; then
  ICON="$ICON_BATTERY_75"
  COLOR=$YELLOW
elif [ "$PERCENTAGE" -gt 25 ]; then
  ICON="$ICON_BATTERY_50"
  COLOR=$PEACH
else
  ICON="$ICON_BATTERY_0"
  COLOR=$RED
fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="${PERCENTAGE}%"
