#!/bin/bash

# Nerd Font icons (PlemolJP Console NF)
# BMP PUA icons use $'\xNN' UTF-8 byte sequences (bash 3.2 compatible)

export ICON_CLOCK=$'\xEF\x80\x97'              # U+F017
export ICON_BATTERY_FULL=$'\xEF\x89\x80'       # U+F240
export ICON_BATTERY_75=$'\xEF\x89\x81'         # U+F241
export ICON_BATTERY_50=$'\xEF\x89\x82'         # U+F242
export ICON_BATTERY_25=$'\xEF\x89\x83'         # U+F243
export ICON_BATTERY_0=$'\xEF\x89\x84'          # U+F244
export ICON_BATTERY_CHARGING=$'\xEF\x83\xA7'   # U+F0E7
export ICON_APP="󰣆"
export ICON_WIFI="󰤨"
export ICON_WIFI_3="󰤧"
export ICON_WIFI_2="󰤦"
export ICON_WIFI_1="󰤥"
export ICON_WIFI_OFF="󰤭"
export ICON_APPLE=$'\xEF\x85\xB9'              # U+F179 nf-fa-apple
export ICON_CPU=$'\xEF\x8B\x9B'              # U+F2DB nf-fa-microchip
export ICON_MEM="󰍛"
export ICON_BREW="󰏗"
export ICON_MEDIA="󰎆"
export ICON_SLACK=$'\xEF\x86\x98'              # U+F198 nf-fa-slack

# Workspace icons (AeroSpace)
export ICON_WS_C=$'\xEF\x89\xA8'              # U+F268 nf-fa-chrome
export ICON_WS_M=$'\xEF\x83\xA0'              # U+F0E0 nf-fa-envelope
export ICON_WS_S=$'\xEF\x86\x98'              # U+F198 nf-fa-slack
export ICON_WS_T=$'\xF3\xB0\xA1\x89'          # U+F0849 nf-md-account_group
export ICON_WS_A=$'\xEF\x84\xA0'              # U+F120 nf-fa-terminal
export ICON_WS_O=$'\xF3\xB0\xBA\xBF'          # U+F0EBF nf-md-notebook_outline

# Claude Code (custom ClaudeIcon.ttf, U+E900 — built from claude-icon.svg by fontforge)
export ICON_CLAUDE=$'\xEE\xA4\x80'              # U+E900
export FONT_CLAUDE_ICON="ClaudeIcon:Regular:18.0"
