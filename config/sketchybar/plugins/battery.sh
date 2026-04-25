#!/bin/sh

BATTERY_INFO=$(pmset -g batt)
PERCENT=$(printf '%s\n' "$BATTERY_INFO" | grep -Eo '[0-9]+%' | tr -d '%')

if printf '%s\n' "$BATTERY_INFO" | grep -q 'AC Power'; then
  ICON="󰂄"
elif [ "$PERCENT" -ge 90 ]; then
  ICON="󰁹"
elif [ "$PERCENT" -ge 60 ]; then
  ICON="󰂀"
elif [ "$PERCENT" -ge 30 ]; then
  ICON="󰁽"
else
  ICON="󰂃"
fi

sketchybar --set "$NAME" icon="$ICON" label="$PERCENT%"
