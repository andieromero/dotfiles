#!/bin/bash

# TWINION Pulse pill — agent health via OpenClaw gateway + brain sync status.
# Offline-ready: shows grey "offline" when Tailscale isn't connected.
# When Tailscale is live: polls OpenClaw health + brain git log via SSH.
# Caches results to /tmp to avoid SSH latency on every poll.

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

ICON_ROBOT=$(printf '\xEF\x94\xA4')    # U+F524 nf-md-robot (Nerd Font)
CACHE="/tmp/twinion_pulse.cache"
CACHE_MAX_AGE=110  # seconds — poll is 120s, cache slightly shorter
TWINION_HOST="flowen-jyrgen"  # Tailscale hostname

# Handle hover
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
    state = d.get('BackendState', '')
    print('1' if state == 'Running' else '0')
except:
    print('0')
" 2>/dev/null)
  [ "$TS_STATUS" = "1" ] && TS_CONNECTED=1
fi

# --- Offline mode ---
if [ "$TS_CONNECTED" = "0" ]; then
  sketchybar --set "$NAME" \
    icon="$ICON_ROBOT" \
    icon.color=0xff666666 \
    label="offline"
  sketchybar --set "$NAME.tt" label="TWINION offline | Connect to Flowen Tailscale mesh to see agent status"
  exit 0
fi

# --- Online mode: check cache freshness ---
USE_CACHE=0
if [ -f "$CACHE" ]; then
  CACHE_AGE=$(( $(date +%s) - $(stat -f %m "$CACHE") ))
  [ "$CACHE_AGE" -lt "$CACHE_MAX_AGE" ] && USE_CACHE=1
fi

if [ "$USE_CACHE" = "1" ]; then
  # Read cached values
  source "$CACHE"
else
  # Poll OpenClaw gateway health
  GW_HEALTH=$(curl -s --connect-timeout 3 --max-time 5 "http://${TWINION_HOST}:18789/health" 2>/dev/null)
  if [ -n "$GW_HEALTH" ]; then
    GW_STATUS="up"
  else
    GW_STATUS="down"
  fi

  # Poll brain sync age via SSH
  BRAIN_AGE=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no "$TWINION_HOST" \
    'git -C ~/.openclaw/workspace/brain log -1 --format="%cr" 2>/dev/null || echo "unknown"' 2>/dev/null)
  [ -z "$BRAIN_AGE" ] && BRAIN_AGE="ssh failed"

  # Poll next cron job
  NEXT_CRON=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no "$TWINION_HOST" \
    'docker compose -f /root/.openclaw/docker-compose.yml run --rm openclaw-cli cron list 2>/dev/null | head -1' 2>/dev/null)
  [ -z "$NEXT_CRON" ] && NEXT_CRON="unknown"

  # Write cache
  cat > "$CACHE" <<CACHEEOF
GW_STATUS="$GW_STATUS"
BRAIN_AGE="$BRAIN_AGE"
NEXT_CRON="$NEXT_CRON"
CACHEEOF
fi

# --- Render ---
if [ "$GW_STATUS" = "up" ]; then
  COLOR=0xff80e27e  # green
  LABEL="TWINION"
else
  COLOR=0xffff5f87  # red
  LABEL="TWINION"
fi

sketchybar --set "$NAME" \
  icon="$ICON_ROBOT" \
  icon.color="$COLOR" \
  label="$LABEL"

TOOLTIP="Gateway: $GW_STATUS | Brain sync: $BRAIN_AGE | Next cron: $NEXT_CRON"
sketchybar --set "$NAME.tt" label="$TOOLTIP"
