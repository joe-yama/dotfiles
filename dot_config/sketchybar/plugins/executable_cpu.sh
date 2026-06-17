#!/bin/bash

source "$CONFIG_DIR/colors.sh"

CORE_COUNT=$(sysctl -n machdep.cpu.thread_count 2>/dev/null || echo 1)

# ps -A: sum all process CPU%, divide by thread count for normalized usage
TOTAL_CPU=$(ps -A -o %cpu | awk '{s+=$1} END {printf "%.0f", s}')
CPU_USAGE=$(( ${TOTAL_CPU:-0} / CORE_COUNT ))
# Clamp to 0-100
[ "$CPU_USAGE" -gt 100 ] && CPU_USAGE=100
[ "$CPU_USAGE" -lt 0 ] && CPU_USAGE=0

# Threshold colors
if [ "$CPU_USAGE" -gt 90 ]; then
  COLOR=$RED
elif [ "$CPU_USAGE" -gt 80 ]; then
  COLOR=$PEACH
elif [ "$CPU_USAGE" -gt 60 ]; then
  COLOR=$YELLOW
else
  COLOR=$TEAL
fi

NORMALIZED=$(awk "BEGIN {printf \"%.2f\", $CPU_USAGE / 100}")
sketchybar --set "$NAME" icon.color="$COLOR" label="${CPU_USAGE}%" \
           --push cpu.graph "$NORMALIZED" \
           --set cpu.graph graph.color="$COLOR"
