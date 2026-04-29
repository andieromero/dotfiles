#!/usr/bin/env bash
# monitor_layout.sh: Sketchybar pill showing current monitor layout.
# Shows "󰍹 1" (single) or "󰍹 1+1" (dual) with secondary monitor name on hover.
# Click to reconfigure AeroSpace workspace-to-monitor assignment.

source "$CONFIG_DIR/colors.sh"

monitor_count=$(aerospace list-monitors --count 2>/dev/null || echo 1)

if (( monitor_count <= 1 )); then
  icon="󰍹"
  label="1"
  tooltip="Single monitor — all workspaces on main"
else
  # Get secondary monitor name
  secondary=""
  while IFS= read -r line; do
    mid="${line%% *}"
    mname="${line#* }"
    if [[ "$mid" != "1" ]]; then
      secondary="$mname"
      break
    fi
  done < <(aerospace list-monitors --format '%{monitor-id} %{monitor-name}' 2>/dev/null)
  icon="󰍹"
  label="1+1"
  tooltip="Main → ws 1-4 | ${secondary:-secondary} → ws 5-8"
fi

sketchybar --set "$NAME" icon="$icon" label="$label"
sketchybar --set monitor_layout.tt label="$tooltip"
