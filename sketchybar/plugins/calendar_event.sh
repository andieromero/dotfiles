#!/bin/bash
ICON_CAL=$(printf '\xEF\x81\xB3')   # U+F073 fa-calendar

# Next meeting pill - queries Calendar.app via AppleScript.
# Label:  calendar icon + title (truncated to 10 chars + ...)
# Hover:  full title + time + calendar name
# Click:  opens Google Calendar in browser

source "$CONFIG_DIR/colors.sh"

if [ "$SENDER" = "mouse.entered" ]; then
  sketchybar --set "$NAME" popup.drawing=on
  exit 0
fi
if [ "$SENDER" = "mouse.exited" ] || [ "$SENDER" = "mouse.exited.global" ]; then
  sketchybar --set "$NAME" popup.drawing=off
  exit 0
fi

# AppleScript emits: title | secondsUntilStart | secondsUntilEnd | calendarName
# Computing deltas in AppleScript avoids locale-dependent date-string parsing.
RAW=$(osascript - 2>/dev/null <<'ASCRIPT'
tell application "Calendar"
  set rightNow to current date
  set horizon to rightNow + (7 * days)
  set chosen to missing value
  set chosenStart to horizon
  set skipCals to {"Holidays in United States", "Birthdays", "Feriados", "Siri Suggestions"}
  repeat with c in calendars
    set cName to title of c
    if cName is not in skipCals then
      try
        set evs to (every event of c whose end date is greater than or equal to rightNow and start date is less than horizon and allday event is false)
        repeat with e in evs
          set s to start date of e
          if s is less than chosenStart then
            set chosen to {summary of e, s, end date of e, cName}
            set chosenStart to s
          end if
        end repeat
      end try
    end if
  end repeat
  if chosen is missing value then return ""
  set secStart to ((item 2 of chosen) - rightNow) as integer
  set secEnd to ((item 3 of chosen) - rightNow) as integer
  set absTime to time string of (item 2 of chosen)
  return (item 1 of chosen) & "|" & secStart & "|" & secEnd & "|" & (item 4 of chosen) & "|" & absTime
end tell
ASCRIPT
)

if [ -z "$RAW" ]; then
  sketchybar --set "$NAME" \
    icon="$ICON_CAL" \
    icon.color="$CAL_EVENT_ICON_COLOR" \
    icon.padding_left=10 \
    icon.padding_right=7 \
    label="clear" \
    label.color="$CAL_EVENT_LABEL_COLOR" \
    label.padding_right=10
  sketchybar --set "$NAME.tt" label="No upcoming meetings in the next 7 days"
  exit 0
fi

TITLE=$(printf '%s' "$RAW" | awk -F'|' '{print $1}')
SEC_START=$(printf '%s' "$RAW" | awk -F'|' '{print $2}')
SEC_END=$(printf '%s' "$RAW" | awk -F'|' '{print $3}')
CALNAME=$(printf '%s' "$RAW" | awk -F'|' '{print $4}')
ABS=$(printf '%s' "$RAW" | awk -F'|' '{print $5}')

# Truncate title to 4 chars + ellipsis
if [ ${#TITLE} -gt 4 ]; then
  SHORT="$(printf '%s' "$TITLE" | cut -c1-4)..."
else
  SHORT="$TITLE"
fi

# Decide WHEN based on AppleScript-computed deltas
if [ "$SEC_START" -le 0 ] && [ "$SEC_END" -ge 0 ]; then
  WHEN="now"
else
  DIFF="$SEC_START"
  [ "$DIFF" -lt 0 ] && DIFF=0
  H=$(( DIFF / 3600 ))
  M=$(( (DIFF % 3600) / 60 ))
  if [ "$H" -gt 0 ]; then
    WHEN="in ${H}hr ${M}min"
  else
    WHEN="in ${M}min"
  fi
fi

LABEL="$SHORT $WHEN"

sketchybar --set "$NAME" \
  icon="$ICON_CAL" \
  icon.color="$CAL_EVENT_ICON_COLOR" \
  icon.padding_left=10 \
  icon.padding_right=7 \
  label="$LABEL" \
  label.color="$CAL_EVENT_LABEL_COLOR" \
  label.padding_right=10

TOOLTIP="$TITLE | $ABS | $WHEN | $CALNAME"
sketchybar --set "$NAME.tt" label="$TOOLTIP"
