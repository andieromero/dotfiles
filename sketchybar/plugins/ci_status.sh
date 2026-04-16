#!/bin/bash

# CI/CD Status pill — polls GitHub Actions for flowen-os repo.
# Green checkmark (success), red X (failure), yellow gear (in_progress), grey ? (error).
# Tooltip: workflow name + branch + conclusion + time ago.
# Click: opens GitHub Actions in browser.

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Icons via UTF-8 byte escapes (macOS bash 3.2 compat)
ICON_CHECK=$(printf '\xEF\x80\x8C')    # U+F00C fa-check
ICON_TIMES=$(printf '\xEF\x80\x8D')    # U+F00D fa-times
ICON_COG=$(printf '\xEF\x80\x93')      # U+F013 fa-cog
ICON_QUESTION=$(printf '\xEF\x80\xA8') # U+F028 fa-question

REPO="Flowen-AI/flowen-os"

# Handle hover
if [ "$SENDER" = "mouse.entered" ]; then
  sketchybar --set "$NAME" popup.drawing=on
  exit 0
elif [ "$SENDER" = "mouse.exited" ] || [ "$SENDER" = "mouse.exited.global" ]; then
  sketchybar --set "$NAME" popup.drawing=off
  exit 0
fi

# Poll GitHub Actions
JSON=$(gh run list --repo "$REPO" --limit 1 --json status,conclusion,headBranch,name,updatedAt 2>/dev/null)

if [ -z "$JSON" ] || [ "$JSON" = "[]" ]; then
  sketchybar --set "$NAME" icon="$ICON_QUESTION" icon.color=0xff888888 label="CI ?"
  sketchybar --set "$NAME.tt" label="gh CLI error or no runs found for $REPO"
  exit 0
fi

# Parse JSON
read -r STATUS CONCLUSION BRANCH WORKFLOW UPDATED <<EOF
$(printf '%s' "$JSON" | /usr/bin/python3 -c "
import json, sys
from datetime import datetime, timezone
try:
    d = json.load(sys.stdin)[0]
    status = d.get('status', '')
    conclusion = d.get('conclusion', '')
    branch = d.get('headBranch', '?')
    workflow = d.get('name', '?')
    updated = d.get('updatedAt', '')
    # Time ago
    if updated:
        dt = datetime.fromisoformat(updated.replace('Z', '+00:00'))
        delta = datetime.now(timezone.utc) - dt
        mins = int(delta.total_seconds() // 60)
        if mins < 60:
            ago = f'{mins}m ago'
        elif mins < 1440:
            ago = f'{mins // 60}h ago'
        else:
            ago = f'{mins // 1440}d ago'
    else:
        ago = ''
    print(f'{status}|{conclusion}|{branch[:8]}|{workflow}|{ago}')
except Exception:
    print('error||||')
")
EOF

IFS='|' read -r STATUS CONCLUSION BRANCH WORKFLOW AGO <<< "$STATUS"

# Choose icon + color
case "$STATUS" in
  completed)
    case "$CONCLUSION" in
      success)
        ICON="$ICON_CHECK"
        COLOR=0xff80e27e  # green
        STATE="passed"
        ;;
      failure)
        ICON="$ICON_TIMES"
        COLOR=0xffff5f87  # red
        STATE="failed"
        ;;
      cancelled)
        ICON="$ICON_TIMES"
        COLOR=0xfff5d76e  # yellow
        STATE="cancelled"
        ;;
      *)
        ICON="$ICON_QUESTION"
        COLOR=0xff888888
        STATE="$CONCLUSION"
        ;;
    esac
    ;;
  in_progress)
    ICON="$ICON_COG"
    COLOR=0xfff5d76e  # yellow
    STATE="running"
    ;;
  queued)
    ICON="$ICON_COG"
    COLOR=0xff888888
    STATE="queued"
    ;;
  *)
    ICON="$ICON_QUESTION"
    COLOR=0xff888888
    STATE="?"
    ;;
esac

sketchybar --set "$NAME" \
  icon="$ICON" \
  icon.color="$COLOR" \
  label="$BRANCH"

TOOLTIP="$WORKFLOW | $BRANCH | $STATE | $AGO"
sketchybar --set "$NAME.tt" label="$TOOLTIP"
