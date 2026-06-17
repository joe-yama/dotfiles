#!/bin/bash

source "$CONFIG_DIR/colors.sh"

NOW_PLAYING=$(osascript -l JavaScript -e '
  var output = "";
  var apps = ["Music", "Spotify"];
  for (var i = 0; i < apps.length; i++) {
    var app = Application(apps[i]);
    try {
      if (app.running()) {
        var state = app.playerState();
        if (state === "playing" || state === "kPSP") {
          var track = app.currentTrack;
          output = track.artist() + " — " + track.name();
          break;
        }
      }
    } catch(e) {}
  }
  output;
' 2>/dev/null)

if [ -n "$NOW_PLAYING" ]; then
  sketchybar --set "$NAME" drawing=on label="$NOW_PLAYING"
else
  sketchybar --set "$NAME" drawing=off
fi
