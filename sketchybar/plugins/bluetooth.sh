#!/bin/sh

# Bluetooth status plugin. Shows icon based on power + connected device count.
# Uses `blueutil` if available (brew install blueutil); falls back to `system_profiler`.

if command -v blueutil >/dev/null 2>&1; then
  POWER=$(blueutil -p)
  if [ "$POWER" = "1" ]; then
    CONNECTED=$(blueutil --connected | wc -l | tr -d ' ')
    if [ "$CONNECTED" -gt 0 ]; then
      ICON="󰂱"
    else
      ICON="󰂯"
    fi
  else
    ICON="󰂲"
  fi
else
  STATE=$(system_profiler SPBluetoothDataType 2>/dev/null | awk -F': ' '/State:/ {print $2; exit}')
  if [ "$STATE" = "On" ]; then
    ICON="󰂯"
  else
    ICON="󰂲"
  fi
fi

sketchybar --set "$NAME" icon="$ICON" label.drawing=off
