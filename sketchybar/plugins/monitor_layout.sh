#!/usr/bin/env bash
# monitor_layout.sh: Sketchybar pill showing current monitor layout.
# Shows "󰍹 1" (single) or "󰍹 1+1" (dual) with secondary monitor name on hover.
# Click to reconfigure AeroSpace workspace-to-monitor assignment.
#
# On macOS display_change events, also re-applies the AeroSpace layout
# automatically. The layout script self-heals if AeroSpace's daemon died on
# hotplug, so this is the auto-recovery path for plug/unplug.

source "$CONFIG_DIR/colors.sh"

# --- Auto re-apply AeroSpace layout on macOS display change ---
if [[ "${SENDER:-}" == "display_change" ]]; then
  "$HOME/.local/bin/aerospace-monitor-layout" >/dev/null 2>&1 &
fi

monitor_count=$(aerospace list-monitors --count 2>/dev/null || echo 1)

if (( monitor_count <= 1 )); then
  icon="󰍹"
  label="1"
  tooltip="Single monitor — all workspaces on main"
else
  # Get secondary monitor name. macOS-main has appkit-nsscreen-screens-id == 1;
  # the "secondary" pill label refers to the *external* (non-main) display.
  # %{monitor-id} is just AeroSpace's index (1,2,...) and is NOT a reliable
  # way to identify the macOS main display.
  secondary=""
  while IFS=$'\t' read -r appkit_id mname; do
    if [[ "$appkit_id" != "1" ]]; then
      secondary="$mname"
      break
    fi
  done < <(aerospace list-monitors --format '%{monitor-appkit-nsscreen-screens-id}	%{monitor-name}' 2>/dev/null)
  icon="󰍹"
  label="$monitor_count"
  tooltip="${secondary:-secondary} → ws 1-4 | main → ws 5-8"
fi

sketchybar --set "$NAME" icon="$icon" label="$label"
sketchybar --set monitor_layout.tt label="$tooltip"
