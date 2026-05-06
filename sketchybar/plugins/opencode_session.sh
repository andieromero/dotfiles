#!/bin/sh

# Active opencode session indicator — mirrors claude_session.sh.
# Main: "<N>× <project>" when opencode processes are running.
# Hover: list of recent session dirs (parsed from log files) with mtime age.

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if [ "$SENDER" = "mouse.entered" ]; then
  sketchybar --set "$NAME" popup.drawing=on
  exit 0
elif [ "$SENDER" = "mouse.exited" ] || [ "$SENDER" = "mouse.exited.global" ]; then
  sketchybar --set "$NAME" popup.drawing=off
  exit 0
fi

COUNT=$(pgrep -x opencode 2>/dev/null | wc -l | tr -d ' ')

if [ "$COUNT" = "0" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

LOG_DIR="$HOME/.local/share/opencode/log"
NEWEST_LOG=$(ls -1t "$LOG_DIR"/*.log 2>/dev/null | head -1)
PROJ_PATH=$(grep -m1 -oE 'directory=[^ ]+' "$NEWEST_LOG" 2>/dev/null | head -1 | sed 's/^directory=//')
PROJ=$(basename "${PROJ_PATH:-session}")

sketchybar --set "$NAME" \
  drawing=on \
  icon="󱙺" \
  icon.color=0xff7cfaff \
  label="${COUNT}× ${PROJ}"

# Tooltip: top 5 most recent session log files, extract project basename + age
TOP=$(ls -1t "$LOG_DIR"/*.log 2>/dev/null | head -5 | while read -r f; do
  dir=$(grep -m1 -oE 'directory=[^ ]+' "$f" 2>/dev/null | head -1 | sed 's/^directory=//')
  name=$(basename "${dir:-?}")
  age_sec=$(( $(date +%s) - $(stat -f %m "$f") ))
  if [ $age_sec -lt 60 ]; then age="${age_sec}s"
  elif [ $age_sec -lt 3600 ]; then age="$((age_sec/60))m"
  elif [ $age_sec -lt 86400 ]; then age="$((age_sec/3600))h"
  else age="$((age_sec/86400))d"
  fi
  printf "%s (%s)  " "$name" "$age"
done)

sketchybar --set "$NAME.tt" label="$COUNT opencode procs · recent: $TOP"
