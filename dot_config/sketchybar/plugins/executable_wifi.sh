#!/bin/bash

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

# Check connection via IP address (avoids SSID <redacted> issue)
IP_ADDR=$(ipconfig getifaddr en0 2>/dev/null)

get_rssi() {
  swift -e 'import CoreWLAN; if let i = CWWiFiClient.shared().interface() { print(i.rssiValue()) }' 2>/dev/null
}

rssi_to_icon() {
  local rssi="$1"
  if [ "$rssi" -ge -50 ] 2>/dev/null; then
    echo "$ICON_WIFI"
  elif [ "$rssi" -ge -65 ] 2>/dev/null; then
    echo "$ICON_WIFI_3"
  elif [ "$rssi" -ge -75 ] 2>/dev/null; then
    echo "$ICON_WIFI_2"
  else
    echo "$ICON_WIFI_1"
  fi
}

if [ -z "$IP_ADDR" ]; then
  sketchybar --set "$NAME" icon="$ICON_WIFI_OFF" icon.color=$OVERLAY0
else
  RSSI=$(get_rssi)
  WIFI_ICON=$(rssi_to_icon "$RSSI")
  sketchybar --set "$NAME" icon="$WIFI_ICON" icon.color=$SAPPHIRE
fi
