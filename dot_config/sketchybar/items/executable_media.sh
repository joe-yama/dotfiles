#!/bin/bash

sketchybar --add item media q \
  --set media \
    icon="$ICON_MEDIA" \
    icon.color=$PINK \
    click_script="$CONFIG_DIR/plugins/media_click.sh" \
    label.max_chars=30 \
    scroll_texts=on \
    update_freq=5 \
    script="$CONFIG_DIR/plugins/media.sh"
