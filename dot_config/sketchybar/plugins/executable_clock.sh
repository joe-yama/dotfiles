#!/bin/bash

sketchybar --set clock label="$(LC_TIME=en_US.UTF-8 date '+%-I:%M %p')" \
           --set clock.date label="$(LC_TIME=en_US.UTF-8 date '+%a %b %-d')"
