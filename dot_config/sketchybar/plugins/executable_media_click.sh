#!/bin/bash

for app in Spotify Music; do
  if pgrep -xq "$app"; then
    open -a "$app"
    exit 0
  fi
done
open -a Music
