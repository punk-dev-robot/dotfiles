#!/bin/sh

if [ "$SENDER" = "volume_change" ] && [ -n "$INFO" ]; then
  VOLUME="$INFO"
else
  VOLUME=$(osascript -e 'output volume of (get volume settings)')
fi

case "$VOLUME" in
  [7-9][0-9]|100) ICON="󰕾" ;;
  [4-6][0-9]) ICON="󰖀" ;;
  [1-3][0-9]|[1-9]) ICON="󰕿" ;;
  *) ICON="󰝟" ;;
esac

sketchybar --set "$NAME" icon="$ICON" label="$VOLUME%"
