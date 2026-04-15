#!/bin/sh

source "$CONFIG_DIR/colors.sh"

# Get upcoming timed events today (excluding all-day events).
# Requires: brew install ical-buddy
#
# Reads from macOS Calendar.app, which syncs Google Calendar automatically if
# you added it under System Settings -> Internet Accounts.
#
# To filter to specific calendars only, uncomment and edit the -ic line:
#   -ic "<calendar name>" includes ONLY that calendar (can pass multiple).
#   -ec "<calendar name>" excludes that calendar.
# List available names with:  icalBuddy calendars
#
# CAL_FILTER=(-ic "andriana@beltranfamily.com")
CAL_FILTER=()

OUTPUT=$(icalBuddy "${CAL_FILTER[@]}" -n -nc -npn -ea -li 10 -tf '%H:%M' -df '' -b '•' eventsToday 2>/dev/null)

LABEL=""
CURRENT_TIME=$(date +%H:%M)
CURRENT_MINUTES=$(echo "$CURRENT_TIME" | awk -F: '{print $1*60 + $2}')

if [ -n "$OUTPUT" ] && [ "$OUTPUT" != "" ]; then
  TEMP_FILE=$(mktemp)
  echo "$OUTPUT" > "$TEMP_FILE"

  CURRENT_EVENT_TITLE=""

  while IFS= read -r line; do
    if echo "$line" | grep -q '^•'; then
      CURRENT_EVENT_TITLE=$(echo "$line" | sed 's/^•[[:space:]]*//')
    elif echo "$line" | grep -q '^[[:space:]]*[0-9][0-9]:[0-9][0-9]'; then
      EVENT_TIME=$(echo "$line" | grep -o '^[[:space:]]*[0-9][0-9]:[0-9][0-9]' | xargs)

      if [ -n "$EVENT_TIME" ] && [ -n "$CURRENT_EVENT_TITLE" ]; then
        EVENT_START_MINUTES=$(echo "$EVENT_TIME" | awk -F: '{print $1*60 + $2}')
        TIME_DIFF=$((CURRENT_MINUTES - EVENT_START_MINUTES))
        # Show next event, or current one if it started <5 min ago
        if [ $TIME_DIFF -le 5 ]; then
          LABEL="$EVENT_TIME $CURRENT_EVENT_TITLE"
          break
        fi
      fi
      CURRENT_EVENT_TITLE=""
    fi
  done < "$TEMP_FILE"

  rm -f "$TEMP_FILE"
fi

if [ -z "$LABEL" ]; then
  sketchybar --set "$NAME" \
    icon="󰃮" \
    icon.color="$CAL_EVENT_ICON_COLOR" \
    icon.padding_left=10 \
    icon.padding_right=7 \
    label="" \
    label.padding_right=0
else
  sketchybar --set "$NAME" \
    icon="󰃮" \
    icon.color="$CAL_EVENT_ICON_COLOR" \
    icon.padding_left=10 \
    icon.padding_right=10 \
    label="$LABEL" \
    label.color="$CAL_EVENT_LABEL_COLOR" \
    label.padding_right=10
fi
