#!/bin/sh

SPACE_ID=${NAME#space.}
FOCUSED=$(/opt/homebrew/bin/aerospace list-workspaces --focused 2>/dev/null)
VISIBLE=$(/opt/homebrew/bin/aerospace list-workspaces --monitor focused 2>/dev/null)

case "$VISIBLE" in
  *"$SPACE_ID"*) IS_VISIBLE=1 ;;
  *) IS_VISIBLE=0 ;;
esac

if [ "$FOCUSED" = "$SPACE_ID" ]; then
  sketchybar --set "$NAME" \
    label.color=0xff11111b \
    background.color=0xffcba6f7
elif [ "$IS_VISIBLE" = "1" ]; then
  sketchybar --set "$NAME" \
    label.color=0xffcdd6f4 \
    background.color=0xff45475a
else
  sketchybar --set "$NAME" \
    label.color=0xffa6adc8 \
    background.color=0xff313244
fi
