#!/usr/bin/env bash
#
# Wispr Flow recording indicator — pulses center pill, bar border, window border.
#
# States:
#   off       — Wispr Flow not running                       → hidden
#   idle      — Wispr running, no mic activity                → small dim mic glyph
#   recording — Wispr running + IOAudioEngine active          → flashing REC pill
#
# When recording, the script also:
#   • Flashes the sketchybar outer border (width + color toggle)
#   • Flashes the JankyBorders active window border
#   • Writes /tmp/wispr_state + /tmp/wispr_tick so aerospace.sh can flash the
#     focused workspace pill in lockstep (without conflicting on its own refresh)
#
# Update_freq=1 → ~1 Hz pulse. State files survive across ticks so transitions
# in/out of recording cleanly restore everything.

source "$CONFIG_DIR/colors.sh"

STATE_FILE=/tmp/wispr_state
TICK_FILE=/tmp/wispr_tick
PREV_FOCUS_FILE=/tmp/wispr_prev_focused_ws

# --- Detect state -------------------------------------------------------------
if pgrep -x "Wispr Flow" >/dev/null 2>&1; then
  WISPR_RUNNING=1
else
  WISPR_RUNNING=0
fi

MIC_ACTIVE=0
if [ "$WISPR_RUNNING" = "1" ]; then
  MIC_ACTIVE=$(ioreg -r -c IOAudioEngine 2>/dev/null | grep -c '"IOAudioEngineState" = 1')
fi

if [ "$WISPR_RUNNING" = "0" ]; then
  STATE="off"
elif [ "$MIC_ACTIVE" -gt 0 ]; then
  STATE="recording"
else
  STATE="idle"
fi

PREV_STATE=""
[ -f "$STATE_FILE" ] && PREV_STATE=$(cat "$STATE_FILE")

# --- Resolve focused workspace ------------------------------------------------
FOCUSED_WS=$(aerospace list-windows --focused --format '%{workspace}' 2>/dev/null | head -1)
[ -z "$FOCUSED_WS" ] && FOCUSED_WS=$(aerospace list-workspaces --focused 2>/dev/null | head -1)

PREV_FOCUS=""
[ -f "$PREV_FOCUS_FILE" ] && PREV_FOCUS=$(cat "$PREV_FOCUS_FILE")

# --- Render -------------------------------------------------------------------
case "$STATE" in
  off)
    sketchybar --set "$NAME" \
      drawing=off \
      background.drawing=off
    ;;

  idle)
    sketchybar --set "$NAME" \
      drawing=on \
      icon="󰍮" \
      icon.color=0xff888888 \
      label.drawing=off \
      background.drawing=off
    ;;

  recording)
    # Flip parity each tick — drives the pulse
    TICK=0
    [ -f "$TICK_FILE" ] && TICK=$(cat "$TICK_FILE")
    NEW_TICK=$(( (TICK + 1) % 2 ))
    echo "$NEW_TICK" > "$TICK_FILE"

    FRONT_APP=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)

    # If the user moved focus mid-recording, repaint the previously-flashing pill
    # by re-firing the workspace event (each space.N is subscribed to it).
    if [ -n "$PREV_FOCUS" ] && [ "$PREV_FOCUS" != "$FOCUSED_WS" ]; then
      sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$FOCUSED_WS" >/dev/null 2>&1 &
    fi
    echo "$FOCUSED_WS" > "$PREV_FOCUS_FILE"

    if [ "$NEW_TICK" = "0" ]; then
      # BRIGHT phase
      sketchybar --animate sin_in_out 25 --set "$NAME" \
        drawing=on \
        icon="󰑊" \
        icon.color=0xffffffff \
        label="REC → ${FRONT_APP:-?}" \
        label.drawing=on \
        label.color=0xffffffff \
        background.drawing=on \
        background.color=0xffff1493 \
        background.corner_radius=6 \
        background.height=24 \
        background.border_color=0xffffea00 \
        background.border_width=2

      sketchybar --bar border_width=4 border_color=0xffff1493
      sketchybar --set space.$FOCUSED_WS \
        background.color=0xffff1493 \
        background.border_color=0xffffea00 \
        background.border_width=3

      borders active_color=0xffff1493 width=14.0 >/dev/null 2>&1 &
    else
      # DIM phase
      sketchybar --animate sin_in_out 25 --set "$NAME" \
        drawing=on \
        icon="󰍬" \
        icon.color=0xffaaaaaa \
        label="REC → ${FRONT_APP:-?}" \
        label.drawing=on \
        label.color=0xffaaaaaa \
        background.drawing=on \
        background.color=0xff330011 \
        background.corner_radius=6 \
        background.height=24 \
        background.border_color=0xff8b0040 \
        background.border_width=1

      sketchybar --bar border_width=1 border_color=0xff330011
      sketchybar --set space.$FOCUSED_WS \
        background.color=0xff8b0040 \
        background.border_color=0xff8b0040 \
        background.border_width=1

      borders active_color=0xff8b0040 width=6.0 >/dev/null 2>&1 &
    fi
    ;;
esac

# --- Restore on exit-from-recording -------------------------------------------
if [ "$PREV_STATE" = "recording" ] && [ "$STATE" != "recording" ]; then
  sketchybar --bar border_width=0
  borders active_color=$BORDER_ACTIVE_COLOR width=9.5 >/dev/null 2>&1 &
  rm -f "$TICK_FILE" "$PREV_FOCUS_FILE"
  # Repaint all workspace pills via their subscribed event
  sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE="$FOCUSED_WS" >/dev/null 2>&1 &
fi

echo "$STATE" > "$STATE_FILE"
