#!/bin/bash

# Main CPU item (icon + label, always on bar)
sketchybar --add item cpu right \
  --set cpu \
    icon="$ICON_CPU" \
    icon.color=$TEAL \
    label="--%" \
    label.width=44 \
    label.align=right \
    click_script="$CONFIG_DIR/plugins/cpu_click.sh" \
    update_freq=3 \
    popup.align=right \
    popup.y_offset=4 \
    popup.horizontal=off \
    popup.background.color=$ISLAND_BG \
    popup.background.corner_radius=10 \
    popup.background.border_width=1 \
    popup.background.border_color=$ISLAND_BORDER \
    popup.background.padding_left=10 \
    popup.background.padding_right=10 \
    script="$CONFIG_DIR/plugins/cpu.sh"

# CPU graph lives inside the popup (not on the bar)
sketchybar --add graph cpu.graph popup.cpu 160 \
  --set cpu.graph \
    graph.color=$TEAL \
    graph.fill_color=0x5594e2d5 \
    graph.line_width=1.5 \
    background.height=60 \
    background.color=$SURFACE0 \
    background.corner_radius=6 \
    background.drawing=on \
    background.padding_left=8 \
    background.padding_right=8 \
    label.drawing=off \
    icon.drawing=off \
    padding_left=4 \
    padding_right=4 \
    update_freq=0
