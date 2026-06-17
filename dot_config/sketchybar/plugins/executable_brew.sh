#!/bin/bash

source "$CONFIG_DIR/colors.sh"

BREW_CMD="${BREW_CMD:-/opt/homebrew/bin/brew}"
if ! command -v "$BREW_CMD" >/dev/null 2>&1; then
  BREW_CMD="$(command -v brew 2>/dev/null || true)"
fi

if [ -n "$BREW_CMD" ]; then
  COUNT=$("$BREW_CMD" outdated --quiet 2>/dev/null | wc -l | tr -d ' ')
else
  COUNT=0
fi

if [ "$COUNT" -gt 0 ]; then
  sketchybar --set "$NAME" drawing=on icon.color=$YELLOW label="$COUNT" label.drawing=on
else
  sketchybar --set "$NAME" drawing=off
fi
