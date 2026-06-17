#!/bin/bash

sketchybar --add event aerospace_workspace_change

WORKSPACES=$(aerospace list-workspaces --monitor all --empty no 2>/dev/null)

workspace_icon() {
  case "$1" in
    C) echo "$ICON_WS_C" ;;
    M) echo "$ICON_WS_M" ;;
    S) echo "$ICON_WS_S" ;;
    T) echo "$ICON_WS_T" ;;
    A) echo "$ICON_WS_A" ;;
    O) echo "$ICON_WS_O" ;;
    *) echo "$1" ;;
  esac
}

for sid in $WORKSPACES; do
  WS_ICON=$(workspace_icon "$sid")
  sketchybar --add item space.$sid left \
    --set space.$sid \
      icon="$WS_ICON" \
      icon.font="PlemolJP Console NF:Bold:18.0" \
      icon.color=$OVERLAY1 \
      icon.y_offset=0 \
      icon.padding_left=6 \
      icon.padding_right=6 \
      padding_left=2 \
      padding_right=2 \
      label.drawing=off \
      background.drawing=off \
      click_script="aerospace workspace $sid" \
      script="$CONFIG_DIR/plugins/space.sh" \
    --subscribe space.$sid aerospace_workspace_change
done

# Hidden watcher item: ensures the plugin runs on workspace change
# even when no space items were created (e.g. AeroSpace not yet running)
sketchybar --add item space.watcher left \
  --set space.watcher \
    drawing=off \
    width=0 \
    script="$CONFIG_DIR/plugins/space.sh" \
  --subscribe space.watcher aerospace_workspace_change
