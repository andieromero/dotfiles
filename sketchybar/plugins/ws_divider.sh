#!/usr/bin/env bash
# ws_divider.sh: Show vertical divider between workspace 4 and 5
# only when there are 2+ monitors (main | secondary split).

monitor_count=$(aerospace list-monitors --count 2>/dev/null || echo 1)

if (( monitor_count > 1 )); then
  sketchybar --set "$NAME" drawing=on
else
  sketchybar --set "$NAME" drawing=off
fi
