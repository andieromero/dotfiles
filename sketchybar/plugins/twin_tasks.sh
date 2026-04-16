#!/bin/bash
ICON_TASKS=$(printf '\xEF\x82\xAE')  # U+F0AE fa-tasks
ICON_CHECK=$(printf '\xEF\x80\x8C')  # U+F00C fa-check

# TWIN OS open-tasks indicator.
# Counts `- [ ]` checkboxes across experiences/plans/*.md.
# Popup: which plans have the most open tasks.

TWIN="$HOME/Flowen/twin-andie"
PLANS_DIR="$TWIN/experiences/plans"

if [ "$SENDER" = "mouse.entered" ]; then
  sketchybar --set "$NAME" popup.drawing=on
  exit 0
elif [ "$SENDER" = "mouse.exited" ] || [ "$SENDER" = "mouse.exited.global" ]; then
  sketchybar --set "$NAME" popup.drawing=off
  exit 0
fi

if [ ! -d "$PLANS_DIR" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

OPEN=$(grep -rhE '^\s*[-*] \[ \]' "$PLANS_DIR" 2>/dev/null | wc -l | tr -d ' ')
DONE=$(grep -rhE '^\s*[-*] \[[xX]\]' "$PLANS_DIR" 2>/dev/null | wc -l | tr -d ' ')
TOTAL=$(( OPEN + DONE ))

if [ "$TOTAL" = "0" ]; then
  sketchybar --set "$NAME" drawing=on icon="$ICON_CHECK" icon.color=0xff80e27e label="no plans"
  sketchybar --set "$NAME.tt" label="No checkbox-style tasks found in experiences/plans/"
  exit 0
fi

PCT=$(( DONE * 100 / TOTAL ))

# Color by open count
if [ "$OPEN" = "0" ]; then COLOR=0xff80e27e
elif [ "$OPEN" -lt 5 ]; then COLOR=0xfff5d76e
else COLOR=0xffff5f87
fi

sketchybar --set "$NAME" \
  drawing=on \
  icon="$ICON_TASKS" \
  icon.color="$COLOR" \
  label="${OPEN} open · ${PCT}%"

# Popup: top 3 plans with open tasks
BREAKDOWN=$(grep -lE '^\s*[-*] \[ \]' "$PLANS_DIR"/*.md 2>/dev/null | while read f; do
  n=$(grep -cE '^\s*[-*] \[ \]' "$f")
  printf "%d\t%s\n" "$n" "$(basename "$f" .md)"
done | sort -rn | head -3 | awk -F'\t' '{printf "%s (%d) · ", $2, $1}')

sketchybar --set "$NAME.tt" label="${OPEN} open / ${DONE} done · ${BREAKDOWN:-nothing active}"
