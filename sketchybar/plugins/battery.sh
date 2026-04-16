#!/bin/bash
# Battery pill. Nerd Font FA glyphs built from UTF-8 byte escapes because
# macOS /bin/bash 3.2 doesn't expand $'\uHHHH'.

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

[ -z "$PERCENTAGE" ] && exit 0

BOLT=$(printf '\xEF\x83\xA7')   # U+F0E7 fa-bolt
case "${PERCENTAGE}" in
  9[0-9]|100) LEVEL=$(printf '\xEF\x89\x80') ;;  # U+F240 full
  [6-8][0-9]) LEVEL=$(printf '\xEF\x89\x81') ;;  # U+F241 3/4
  [3-5][0-9]) LEVEL=$(printf '\xEF\x89\x82') ;;  # U+F242 half
  [1-2][0-9]) LEVEL=$(printf '\xEF\x89\x83') ;;  # U+F243 1/4
  *)          LEVEL=$(printf '\xEF\x89\x84') ;;  # U+F244 empty
esac

if [[ -n "$CHARGING" ]]; then
  ICON="${LEVEL}${BOLT}"
else
  ICON="$LEVEL"
fi

sketchybar --set "$NAME" icon="$ICON" label="${PERCENTAGE}%"
