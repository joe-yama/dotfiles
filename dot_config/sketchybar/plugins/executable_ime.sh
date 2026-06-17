#!/bin/bash

source "$CONFIG_DIR/colors.sh"

INPUT_SOURCE=$(defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources 2>/dev/null | grep -o '"KeyboardLayout Name" = "[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$INPUT_SOURCE" ]; then
  INPUT_SOURCE=$(defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources 2>/dev/null | grep -o '"Input Mode" = "[^"]*"' | head -1 | cut -d'"' -f4)
fi

case "$INPUT_SOURCE" in
  *Japanese*|*Hiragana*|*Katakana*)
    sketchybar --set "$NAME" label="あ" label.color=$MAUVE
    ;;
  *)
    sketchybar --set "$NAME" label="A" label.color=$SUBTEXT0
    ;;
esac
