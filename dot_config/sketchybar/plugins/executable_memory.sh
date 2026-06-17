#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# memory_pressure provides system-wide free percentage
MEM_FREE=$(memory_pressure 2>/dev/null | grep 'System-wide memory free percentage:' | awk '{gsub(/%/,""); print $5}')
if [ -n "$MEM_FREE" ]; then
  MEM_USAGE=$((100 - MEM_FREE))
else
  # Fallback to sysctl
  MEM_PRESSURE=$(sysctl -n kern.memorystatus_level 2>/dev/null)
  MEM_USAGE=$((100 - ${MEM_PRESSURE:-100}))
fi
[ "$MEM_USAGE" -lt 0 ] && MEM_USAGE=0
[ "$MEM_USAGE" -gt 100 ] && MEM_USAGE=100

# Threshold colors
if [ "$MEM_USAGE" -gt 90 ]; then
  COLOR=$RED
elif [ "$MEM_USAGE" -gt 80 ]; then
  COLOR=$PEACH
elif [ "$MEM_USAGE" -gt 60 ]; then
  COLOR=$YELLOW
else
  COLOR=$LAVENDER
fi

NORMALIZED=$(awk "BEGIN {printf \"%.2f\", $MEM_USAGE / 100}")
sketchybar --set "$NAME" icon.color="$COLOR" label="${MEM_USAGE}%" \
           --push memory.graph "$NORMALIZED" \
           --set memory.graph graph.color="$COLOR"
