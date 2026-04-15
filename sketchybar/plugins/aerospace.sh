#!/usr/bin/env bash
#
# Fires on aerospace_workspace_change for each workspace pill.
# $1 is the workspace id (passed via script="...aerospace.sh $sid")
# $FOCUSED_WORKSPACE is injected by aerospace via exec-on-workspace-change.

source "$CONFIG_DIR/colors.sh"

SID="$1"

# -- Highlight active workspace in hot pink --
if [ "$SID" = "$FOCUSED_WORKSPACE" ]; then
  sketchybar --set "$NAME" \
    background.color="$HOT_PINK" \
    background.border_color="$HOT_PURPLE" \
    background.border_width=2 \
    icon.color="$WHITE" \
    label.shadow.drawing=on \
    icon.shadow.drawing=on
else
  sketchybar --set "$NAME" \
    background.color="$ITEM_BG_COLOR" \
    background.border_width=0 \
    icon.color="$WHITE" \
    label.shadow.drawing=off \
    icon.shadow.drawing=off
fi

# -- Notification indicator --
# Check if any app in this workspace has a Dock badge (unread messages, etc.)
# Reads the macOS Dock's AXStatusLabel attribute for each app's tile.
apps_in_ws=$(aerospace list-windows --workspace "$SID" 2>/dev/null | awk -F'|' '{gsub(/^ *| *$/, "", $2); print $2}')

has_notif=false
while IFS= read -r app; do
  [ -z "$app" ] && continue
  # Query the app's Dock badge. Any non-empty result means there's a count.
  badge=$(osascript -e "tell application \"System Events\" to tell process \"Dock\" to get value of attribute \"AXStatusLabel\" of UI element \"$app\" of list 1" 2>/dev/null)
  if [ -n "$badge" ] && [ "$badge" != "missing value" ]; then
    has_notif=true
    break
  fi
done <<<"$apps_in_ws"

if [ "$has_notif" = "true" ]; then
  # Pulse the border in notification color when there are unread notifications
  sketchybar --set "$NAME" \
    background.border_color="$NOTIF_COLOR" \
    background.border_width=3
fi
