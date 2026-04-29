#!/usr/bin/env bash
#
# Manual resync of sketchybar state:
#   - Re-reads every workspace's windows and rebuilds the app-icon strip on each pill
#   - Forces every item that can update to re-run its script
#   - Flashes the refresh button briefly so you know it fired

source "$CONFIG_DIR/colors.sh"

# Visual "pressed" feedback
sketchybar --set "$NAME" icon.color="$HOT_PINK" background.color="$HOT_PURPLE"

# Rebuild app-icon labels for workspaces 1-8
for sid in $(aerospace list-workspaces --all --empty no); do
  if ! [[ "$sid" =~ ^[0-9]+$ ]]; then continue; fi
  if [ "$sid" -gt 8 ]; then continue; fi

  apps=$(aerospace list-windows --workspace "$sid" | awk -F'|' '{gsub(/^ *| *$/, "", $2); print $2}')

  icon_strip=" "
  if [ -n "$apps" ]; then
    while read -r app; do
      [ -z "$app" ] && continue
      icon_strip+=" $("$CONFIG_DIR/plugins/icon_map_fn.sh" "$app")"
    done <<<"$apps"
  fi
  sketchybar --set "space.$sid" label="$icon_strip" drawing=on
done

# Clear drawing on empty workspaces too
for sid in 1 2 3 4 5 6 7 8; do
  if ! aerospace list-workspaces --all --empty no | grep -qx "$sid"; then
    sketchybar --set "space.$sid" label=""
  fi
done

# Trigger the aerospace event so each pill's script runs (updates active state + notification border)
sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$(aerospace list-workspaces --focused)"

# Reconfigure monitor layout (detects plugged/unplugged monitors)
"$HOME/.local/bin/aerospace-monitor-layout" >/dev/null 2>&1 || true

# Nudge every status item on the right side to refresh
sketchybar --update

# Restore the refresh button styling after a beat
sleep 0.25
sketchybar --set "$NAME" icon.color="$WHITE" background.color="$ITEM_BG_COLOR"
