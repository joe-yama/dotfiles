#!/bin/bash

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

FONT="PlemolJP Console NF"
FOCUSED=$(aerospace list-workspaces --focused 2>/dev/null)
ACTIVE_WORKSPACES=$(aerospace list-workspaces --monitor all --empty no 2>/dev/null)

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

# Ensure items exist for all active workspaces (dynamic creation)
for ws in $ACTIVE_WORKSPACES; do
  if ! sketchybar --query "space.$ws" >/dev/null 2>&1; then
    WS_ICON=$(workspace_icon "$ws")
    sketchybar --add item "space.$ws" left \
      --set "space.$ws" \
        icon="$WS_ICON" \
        icon.font="$FONT:Bold:18.0" \
        icon.color=$OVERLAY1 \
        icon.y_offset=0 \
        icon.padding_left=6 \
        icon.padding_right=6 \
        padding_left=2 \
        padding_right=2 \
        label.drawing=off \
        background.drawing=off \
        click_script="aerospace workspace $ws" \
        script="$CONFIG_DIR/plugins/space.sh" \
      --subscribe "space.$ws" aerospace_workspace_change
  fi
done

# Sort active workspaces lexicographically and reorder space items
SORTED=$(echo "$ACTIVE_WORKSPACES" | sort)
REORDER_ARGS=""
for ws in $SORTED; do
  REORDER_ARGS="$REORDER_ARGS space.$ws"
done
if [ -n "$REORDER_ARGS" ]; then
  sketchybar --reorder front_app $REORDER_ARGS media
fi

# Update all space.* items
for ws in $ACTIVE_WORKSPACES; do
  if [ "$ws" = "$FOCUSED" ]; then
    sketchybar --set "space.$ws" \
      drawing=on \
      icon.color=$BLUE \
      icon.font="$FONT:Bold:19.0"
  else
    sketchybar --set "space.$ws" \
      drawing=on \
      icon.color=$OVERLAY1 \
      icon.font="$FONT:Bold:18.0"
  fi
done

# Hide items for workspaces that are no longer active
EXISTING=$(sketchybar --query bar 2>/dev/null | grep -o '"space\.[^"]*"' | tr -d '"' | grep -v 'space\.watcher')
for item in $EXISTING; do
  sid="${item##space.}"
  if ! echo "$ACTIVE_WORKSPACES" | grep -qx "$sid"; then
    sketchybar --set "$item" drawing=off
  fi
done
