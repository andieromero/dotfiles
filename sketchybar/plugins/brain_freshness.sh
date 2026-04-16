#!/bin/sh

# TWIN OS brain freshness.
# Main: age of brain-health/progress.md.
# Hover: exact timestamp + last H2 heading from the file.

PROGRESS="$HOME/Flowen/twin-andie/brain-health/progress.md"

if [ "$SENDER" = "mouse.entered" ]; then
  sketchybar --set "$NAME" popup.drawing=on
  exit 0
elif [ "$SENDER" = "mouse.exited" ] || [ "$SENDER" = "mouse.exited.global" ]; then
  sketchybar --set "$NAME" popup.drawing=off
  exit 0
fi

if [ ! -f "$PROGRESS" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

NOW=$(date +%s)
MOD=$(stat -f %m "$PROGRESS")
DIFF=$(( NOW - MOD ))
HOURS=$(( DIFF / 3600 ))

if [ "$HOURS" -lt 1 ]; then LABEL="$(( DIFF / 60 ))m"
elif [ "$HOURS" -lt 24 ]; then LABEL="${HOURS}h"
else LABEL="$(( HOURS / 24 ))d"
fi

if [ "$HOURS" -lt 6 ]; then COLOR=0xff80e27e
elif [ "$HOURS" -lt 24 ]; then COLOR=0xfff5d76e
else COLOR=0xffff5f87
fi

# Dynamic label: "andie twins", "casey twins", etc.
# Name derivation order:
#   1. $TWIN_NAME override (set in zshrc if you want to force a value)
#   2. Directory name after "twin-" in $HOME/Flowen/twin-*/
#   3. Fallback to $USER
if [ -n "$TWIN_NAME" ]; then
  NAME_PART="$TWIN_NAME"
else
  TWIN_DIR=$(ls -1d "$HOME/Flowen/twin-"*/ 2>/dev/null | head -1)
  if [ -n "$TWIN_DIR" ]; then
    NAME_PART=$(basename "$TWIN_DIR" | sed 's/^twin-//')
  else
    NAME_PART="$USER"
  fi
fi
FIRST_NAME=$(printf '%s' "$NAME_PART" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
sketchybar --set "$NAME" drawing=on icon="󰧑" icon.color="$COLOR" label="${FIRST_NAME} twins ${LABEL}"

STAMP=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$PROGRESS")
LAST_SECTION=$(grep -m1 '^## ' "$PROGRESS" 2>/dev/null | sed 's/^## //' | head -c 60)
sketchybar --set "$NAME.tt" label="Last update: $STAMP · section: $LAST_SECTION"
