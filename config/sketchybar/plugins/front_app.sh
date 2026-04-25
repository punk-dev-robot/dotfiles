#!/bin/sh

if [ "$SENDER" = "front_app_switched" ]; then
  if [ -n "$INFO" ]; then
    sketchybar --set "$NAME" label="$INFO"
  else
    sketchybar --set "$NAME" label="Finder"
  fi
fi
