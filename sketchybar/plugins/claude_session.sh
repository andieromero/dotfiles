#!/bin/sh

# Active Claude Code session indicator.
# Main: "<N>× <project>" when claude processes are running.
# Hover: list of active project dirs with mtime age.

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if [ "$SENDER" = "mouse.entered" ]; then
  sketchybar --set "$NAME" popup.drawing=on
  exit 0
elif [ "$SENDER" = "mouse.exited" ] || [ "$SENDER" = "mouse.exited.global" ]; then
  sketchybar --set "$NAME" popup.drawing=off
  exit 0
fi

COUNT=$(pgrep -x claude 2>/dev/null | wc -l | tr -d ' ')

if [ "$COUNT" = "0" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

PROJ_DIR=$(ls -1dt "$HOME/.claude/projects"/*/ 2>/dev/null | head -1)
PROJ=$(basename "${PROJ_DIR:-}" | sed -E 's/^-Users-[^-]+-//' | awk -F- '{print $NF}')
[ -z "$PROJ" ] && PROJ="session"

sketchybar --set "$NAME" \
  drawing=on \
  icon="󰚩" \
  icon.color=0xffd87cff \
  label="${COUNT}× ${PROJ}"

# Tooltip: top 5 most recent project dirs
TOP=$(ls -1dt "$HOME/.claude/projects"/*/ 2>/dev/null | head -5 | while read d; do
  name=$(basename "$d" | sed -E 's/^-Users-[^-]+-//' | tr '-' '/')
  age_sec=$(( $(date +%s) - $(stat -f %m "$d") ))
  if [ $age_sec -lt 60 ]; then age="${age_sec}s"
  elif [ $age_sec -lt 3600 ]; then age="$((age_sec/60))m"
  elif [ $age_sec -lt 86400 ]; then age="$((age_sec/3600))h"
  else age="$((age_sec/86400))d"
  fi
  printf "%s (%s)  " "$name" "$age"
done)

sketchybar --set "$NAME.tt" label="$COUNT claude procs · recent: $TOP"
