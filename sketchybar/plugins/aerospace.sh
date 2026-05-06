#!/usr/bin/env bash
#
# Single-item workspace pill renderer.
# - Sets pill background hot pink ONLY for the keyboard-focused workspace
#   (singular — `--focused` returns one workspace per monitor, so we use the
#   focused window's workspace instead).
# - Builds the app-icon strip from sketchybar-app-font glyphs.
# - Adds notification border if any app in the workspace has a dock badge.

source "$CONFIG_DIR/colors.sh"

SID="$1"

# Resolve the SINGLE keyboard-focused workspace by querying the focused window.
# If no focused window (empty workspace), fall back to the first --focused entry.
KEYBOARD_FOCUSED=$(aerospace list-windows --focused --format '%{workspace}' 2>/dev/null | head -1)
if [ -z "$KEYBOARD_FOCUSED" ]; then
  KEYBOARD_FOCUSED=$(aerospace list-workspaces --focused 2>/dev/null | head -1)
fi

if [ "$SID" = "$KEYBOARD_FOCUSED" ]; then
  PILL_BG="$HOT_PINK"
  PILL_BORDER_WIDTH=0
else
  PILL_BG="$ITEM_BG_COLOR"
  PILL_BORDER_WIDTH=0
fi

# App-icon strip
apps=$(aerospace list-windows --workspace "$SID" 2>/dev/null | awk -F'|' '{gsub(/^ *| *$/, "", $2); print $2}' | awk '!seen[$0]++')
icon_strip=""
has_notif=false

if [ -n "$apps" ]; then
  first=1
  while IFS= read -r app; do
    [ -z "$app" ] && continue
    glyph=$("$CONFIG_DIR/plugins/icon_map_fn.sh" "$app")
    if [ "$first" = "1" ]; then
      icon_strip="$glyph"
      first=0
    else
      icon_strip+=" $glyph"
    fi
    badge=$(osascript -e "tell application \"System Events\" to tell process \"Dock\" to get value of attribute \"AXStatusLabel\" of UI element \"$app\" of list 1" 2>/dev/null)
    if [ -n "$badge" ] && [ "$badge" != "missing value" ]; then
      has_notif=true
    fi
  done <<<"$apps"
fi

# Notification border (only on focused or non-focused — both, just thin)
if [ "$has_notif" = "true" ]; then
  PILL_BORDER_COLOR="$NOTIF_COLOR"
  PILL_BORDER_WIDTH=2
else
  PILL_BORDER_COLOR="$HOT_PURPLE"
fi

# Wispr Flow recording override: if Wispr is recording AND this is the focused
# workspace, replace pill colors with the pulse phase set by wispr_indicator.sh.
# Sharing the tick file keeps both scripts in lockstep so update_freq=2 here
# doesn't fight update_freq=1 there.
WISPR_STATE_FILE=/tmp/wispr_state
WISPR_TICK_FILE=/tmp/wispr_tick
if [ "$SID" = "$KEYBOARD_FOCUSED" ] \
  && [ -f "$WISPR_STATE_FILE" ] \
  && [ "$(cat "$WISPR_STATE_FILE" 2>/dev/null)" = "recording" ]; then
  WISPR_TICK=0
  [ -f "$WISPR_TICK_FILE" ] && WISPR_TICK=$(cat "$WISPR_TICK_FILE")
  if [ "$WISPR_TICK" = "0" ]; then
    PILL_BG=0xffff1493
    PILL_BORDER_COLOR=0xffffea00
    PILL_BORDER_WIDTH=3
  else
    PILL_BG=0xff8b0040
    PILL_BORDER_COLOR=0xff8b0040
    PILL_BORDER_WIDTH=1
  fi
fi

sketchybar --set "$NAME" \
  background.color="$PILL_BG" \
  background.border_color="$PILL_BORDER_COLOR" \
  background.border_width="$PILL_BORDER_WIDTH" \
  label="$icon_strip"
