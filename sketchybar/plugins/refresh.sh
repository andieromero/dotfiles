#!/usr/bin/env bash
#
# Manual resync of sketchybar state:
#   - Reconfigures monitor layout (handles plugged/unplugged monitors)
#   - Recovers orphaned windows: any window NOT on workspaces 1-8 (e.g. ws 9
#     hidden scratch, or some broken state from monitor hotplug) gets moved
#     to workspace 1 so it reappears in sketchybar pills. User can manually
#     hyper-key-move from ws 1 after.
#   - Re-reads every workspace's windows and rebuilds the app-icon strip
#   - Forces every item that can update to re-run its script
#   - Flashes the refresh button briefly so you know it fired
#
# Why orphan recovery on refresh: connecting a new monitor or AeroSpace
# state confusion can dump windows onto workspace 9 (the hidden scratch),
# where they're invisible in sketchybar's 1-8 pills. The refresh button is
# the "make my windows visible again" escape hatch.

source "$CONFIG_DIR/colors.sh"

# Visual "pressed" feedback
sketchybar --set "$NAME" icon.color="$HOT_PINK" background.color="$HOT_PURPLE"

# Reconfigure monitor layout first — handles plugged/unplugged monitors before
# we enumerate windows. Soft path; if AeroSpace's daemon is dead, the script
# self-heals via its own restart logic.
"$HOME/.local/bin/aerospace-monitor-layout" >/dev/null 2>&1 || true

# Orphan recovery: any window not on ws 1-8 moves to ws 1.
# Catches: ws 9 (hidden scratch), out-of-range, empty workspace field.
moved=0
while IFS='|' read -r wid wspace _; do
  wspace="${wspace// /}"  # strip whitespace
  if ! [[ "$wspace" =~ ^[1-8]$ ]]; then
    if aerospace move-node-to-workspace --window-id "$wid" 1 2>/dev/null; then
      moved=$((moved + 1))
    fi
  fi
done < <(aerospace list-windows --all --format '%{window-id}|%{workspace}|%{app-name}' 2>/dev/null)

# Rebuild app-icon labels for workspaces 1-8 (after orphan recovery so any
# rescued windows show up on ws 1 immediately)
for sid in $(aerospace list-workspaces --monitor all --empty no); do
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
  if ! aerospace list-workspaces --monitor all --empty no | grep -qx "$sid"; then
    sketchybar --set "space.$sid" label=""
  fi
done

# Trigger the aerospace event so each pill's script runs (updates active state + notification border).
# DO NOT call `sketchybar --update` here — it re-fires every item with `script=`,
# which would loop right back through this script via the hotplug_listener
# (subscribed to display_change with the same script). The aerospace_workspace_change
# trigger above is sufficient to refresh the workspace pills.
sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$(aerospace list-workspaces --focused)"

# Restore the refresh button styling after a beat
sleep 0.25
sketchybar --set "$NAME" icon.color="$WHITE" background.color="$ITEM_BG_COLOR"

# Log if we rescued windows (shows in sketchybar.err.log if user investigates)
if [ "$moved" -gt 0 ]; then
  echo "refresh.sh: moved $moved orphaned window(s) to ws 1" >&2
fi
