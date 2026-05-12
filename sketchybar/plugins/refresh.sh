#!/usr/bin/env bash
#
# Manual resync of sketchybar state:
#   - Reconfigures monitor layout (handles plugged/unplugged monitors)
#   - Recovers orphaned windows: any window NOT on workspaces 1-8 (e.g. ws 9
#     hidden scratch, or some broken state from monitor hotplug) gets moved
#     to workspace 1 so it reappears in sketchybar pills.
#   - Re-reads every workspace's windows and rebuilds the app-icon strip
#   - Triggers the aerospace_workspace_change event so pills re-render
#
# Visible feedback:
#   - Pressed state at start (pink icon, purple background)
#   - Final ✓ in green for 1.5s
#   - macOS notification with the per-phase counts
#   - Last-run summary persisted to /tmp/sketchybar-refresh-last.txt for
#     the popup tooltip
#
# Why orphan recovery on refresh: connecting a new monitor or AeroSpace
# state confusion can dump windows onto workspace 9 (hidden scratch),
# where they're invisible in sketchybar's 1-8 pills.

source "$CONFIG_DIR/colors.sh"

SUMMARY_FILE="/tmp/sketchybar-refresh-last.txt"
START_TS=$(date +%s)
RUN_AT=$(date '+%H:%M:%S')

# --- Pressed state ---
sketchybar --set "$NAME" \
  icon.color="$HOT_PINK" \
  background.color="$HOT_PURPLE"

# --- Phase 1: monitor layout ---
phase_layout="ok"
if ! "$HOME/.local/bin/aerospace-monitor-layout" >/dev/null 2>&1; then
  phase_layout="failed"
fi

# --- Phase 2: orphan recovery ---
moved=0
while IFS='|' read -r wid wspace _; do
  wspace="${wspace// /}"
  if ! [[ "$wspace" =~ ^[1-8]$ ]]; then
    if aerospace move-node-to-workspace --window-id "$wid" 1 2>/dev/null; then
      moved=$((moved + 1))
    fi
  fi
done < <(aerospace list-windows --all --format '%{window-id}|%{workspace}|%{app-name}' 2>/dev/null)

# --- Phase 3: rebuild app-icon labels for workspaces 1-8 ---
workspaces_rebuilt=0
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
  workspaces_rebuilt=$((workspaces_rebuilt + 1))
done

# Clear drawing on empty workspaces
for sid in 1 2 3 4 5 6 7 8; do
  if ! aerospace list-workspaces --monitor all --empty no | grep -qx "$sid"; then
    sketchybar --set "space.$sid" label=""
  fi
done

# --- Phase 4: pulse aerospace_workspace_change so each pill re-runs ---
# DO NOT call `sketchybar --update` here — it would loop via the
# hotplug_listener subscribed to display_change.
sketchybar --trigger aerospace_workspace_change \
  FOCUSED_WORKSPACE="$(aerospace list-workspaces --focused)"

# --- Stats for feedback ---
monitor_count=$(aerospace list-monitors --count 2>/dev/null || echo 0)
elapsed=$(( $(date +%s) - START_TS ))

# --- Compose summary string ---
status_glyph="✓"; status_color="$GREEN"; notif_title="Sketchybar refresh"
if [[ "$phase_layout" == "failed" ]]; then
  status_glyph="!"
  status_color="$HOT_PINK"
  notif_title="Sketchybar refresh — partial"
fi

summary="${monitor_count} monitor(s) · ${workspaces_rebuilt} workspace(s) rebuilt · ${moved} orphan(s) rescued · ${elapsed}s"
[[ "$phase_layout" == "failed" ]] && summary="layout=FAILED · $summary"

# --- Persist for popup tooltip ---
{
  printf 'last refresh: %s\n' "$RUN_AT"
  printf '  monitor-layout: %s\n' "$phase_layout"
  printf '  monitors detected: %s\n' "$monitor_count"
  printf '  workspaces rebuilt: %s\n' "$workspaces_rebuilt"
  printf '  orphans rescued: %s\n' "$moved"
  printf '  elapsed: %ss\n' "$elapsed"
} > "$SUMMARY_FILE"

# --- Inline ✓ for 1.5s ---
sketchybar --set "$NAME" \
  icon="$status_glyph" \
  icon.color="$status_color" \
  background.color="$ITEM_BG_COLOR"
sleep 1.5

# --- Restore refresh icon ---
sketchybar --set "$NAME" \
  icon="󰜉" \
  icon.color="$WHITE" \
  background.color="$ITEM_BG_COLOR"

# --- macOS notification (best-effort; ignore if osascript blocked) ---
osascript -e "display notification \"$summary\" with title \"$notif_title\"" 2>/dev/null || true

# --- Update popup tooltip label (if popup item exists) ---
sketchybar --set "$NAME.summary" label="$(cat "$SUMMARY_FILE")" 2>/dev/null || true

# Log if we rescued windows
if [ "$moved" -gt 0 ]; then
  echo "refresh.sh: moved $moved orphaned window(s) to ws 1" >&2
fi
