#!/bin/bash

# Pending Approvals pill — badge count of TWINION actions awaiting human review.
# Reads governance.db pending_actions via SSH when Tailscale is connected.
# Offline-ready: shows grey "—" when Tailscale isn't available.
# Click: opens Ghostty and launches `claude` in the twin dir to run /work.
# Applies patterns: Graceful Offline Degradation, SSH Cache-to-Tmpfile.

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

ICON_INBOX=$(printf '\xEF\x80\x9C')     # U+F01C fa-inbox
CACHE="/tmp/pending_approvals.cache"
CACHE_MAX_AGE=110  # update_freq=120, cache slightly shorter
TWINION_HOST="flowen-jyrgen"
GOV_DB="/root/.openclaw/governance.db"

# Handle hover — never SSH on hover, just toggle popup
if [ "$SENDER" = "mouse.entered" ]; then
  sketchybar --set "$NAME" popup.drawing=on
  exit 0
elif [ "$SENDER" = "mouse.exited" ] || [ "$SENDER" = "mouse.exited.global" ]; then
  sketchybar --set "$NAME" popup.drawing=off
  exit 0
fi

# --- Check Tailscale connectivity ---
TS_CONNECTED=0
if command -v tailscale >/dev/null 2>&1; then
  TS_STATUS=$(tailscale status --json 2>/dev/null | /usr/bin/python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print('1' if d.get('BackendState', '') == 'Running' else '0')
except:
    print('0')
" 2>/dev/null)
  [ "$TS_STATUS" = "1" ] && TS_CONNECTED=1
fi

# --- Offline mode ---
if [ "$TS_CONNECTED" = "0" ]; then
  sketchybar --set "$NAME" \
    icon="$ICON_INBOX" \
    icon.color=0xff666666 \
    label="—" \
    background.border_width=0
  sketchybar --set "$NAME.tt" label="Approvals offline | Connect Tailscale to see pending TWINION actions"
  exit 0
fi

# --- Online: check cache ---
USE_CACHE=0
if [ -f "$CACHE" ]; then
  CACHE_AGE=$(( $(date +%s) - $(stat -f %m "$CACHE") ))
  [ "$CACHE_AGE" -lt "$CACHE_MAX_AGE" ] && USE_CACHE=1
fi

if [ "$USE_CACHE" = "1" ]; then
  source "$CACHE"
else
  # Count pending actions
  COUNT=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no "$TWINION_HOST" \
    "sqlite3 $GOV_DB \"SELECT count(*) FROM pending_actions WHERE status='pending'\"" 2>/dev/null)
  [ -z "$COUNT" ] && COUNT="?"

  # First 3 action summaries for tooltip
  SUMMARIES=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no "$TWINION_HOST" \
    "sqlite3 -separator '|' $GOV_DB \"SELECT content_preview FROM pending_actions WHERE status='pending' ORDER BY rowid DESC LIMIT 3\"" 2>/dev/null)
  [ -z "$SUMMARIES" ] && SUMMARIES="(could not fetch)"

  # Write cache
  cat > "$CACHE" <<CACHEEOF
COUNT="$COUNT"
SUMMARIES="$SUMMARIES"
CACHEEOF
fi

# --- Render ---
if [ "$COUNT" = "?" ]; then
  COLOR=0xff888888
  BORDER_W=0
elif [ "$COUNT" -gt 0 ] 2>/dev/null; then
  COLOR=0xffff5f87   # red/amber — needs attention
  BORDER_W=2
else
  COLOR=0xff80e27e   # green — all clear
  BORDER_W=0
fi

sketchybar --set "$NAME" \
  icon="$ICON_INBOX" \
  icon.color="$COLOR" \
  label="$COUNT" \
  background.border_color=0xffff3fa3 \
  background.border_width="$BORDER_W"

# Tooltip
if [ "$COUNT" = "0" ]; then
  TOOLTIP="No pending approvals"
elif [ "$COUNT" = "?" ]; then
  TOOLTIP="Could not reach governance.db"
else
  TOOLTIP="$COUNT pending | $SUMMARIES"
fi

sketchybar --set "$NAME.tt" label="$TOOLTIP"
