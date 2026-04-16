#!/bin/bash

# Flowen OS cheatsheet pill.
# Hover: vertical popup with 7 lines covering core loop, triggers, routing, hygiene.
# Click: opens Claude.app.
# Static content — no polling needed (update_freq=0).

ICON_BOOK=$(printf '\xEF\x80\xAD')   # U+F02D fa-book

if [ "$SENDER" = "mouse.entered" ]; then
  sketchybar --set "$NAME" popup.drawing=on
  exit 0
elif [ "$SENDER" = "mouse.exited" ] || [ "$SENDER" = "mouse.exited.global" ]; then
  sketchybar --set "$NAME" popup.drawing=off
  exit 0
fi

sketchybar --set "$NAME" \
  drawing=on \
  icon="$ICON_BOOK" \
  icon.color=0xffbf00ff \
  label="Flowen"

# Populate the 7 tooltip lines (set once, static content).
sketchybar --set "$NAME.tt1" label="/plan [task]  >  /work  >  /learn"
sketchybar --set "$NAME.tt2" label="/capture pattern  |  /daily-sync (AM)"
sketchybar --set "$NAME.tt3" label="Slack #dev-flowen-os  |  GH Flowen-AI"
sketchybar --set "$NAME.tt4" label="Session start: read progress.md"
sketchybar --set "$NAME.tt5" label="Session end: update Notes for Next"
sketchybar --set "$NAME.tt6" label="~70%: /learn > handoff > /compact"
sketchybar --set "$NAME.tt7" label="1 task = 1 session | always /plan first"
