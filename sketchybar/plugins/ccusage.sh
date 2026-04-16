#!/bin/bash
# Nerd Font glyphs built from UTF-8 byte escapes (survives any shell + file rewrites).
ICON_BOLT=$(printf '\xEF\x83\xA7')   # U+F0E7 fa-bolt

# Claude Code token/cost usage indicator.
# Main label: "$cost · $rate/h · Xm left" for active 5-hour block.
# Color-coded by burn rate: green < $3/h, yellow < $8/h, red >= $8/h.
# Hover popup: detailed breakdown including tokens, projection, today's cost.

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Mouse events just toggle popup; don't re-run ccusage on every hover.
if [ "$SENDER" = "mouse.entered" ]; then
  sketchybar --set "$NAME" popup.drawing=on
  exit 0
elif [ "$SENDER" = "mouse.exited" ] || [ "$SENDER" = "mouse.exited.global" ]; then
  sketchybar --set "$NAME" popup.drawing=off
  exit 0
fi

BLOCKS=$(ccusage blocks --active --json 2>/dev/null)
TODAY=$(ccusage daily --json 2>/dev/null)

if [ -z "$BLOCKS" ]; then
  sketchybar --set "$NAME" icon="$ICON_BOLT" label="n/a" icon.color=0xff888888
  sketchybar --set "$NAME.tt" label="ccusage not installed — npm i -g ccusage"
  exit 0
fi

DATA=$(printf '%s\n---\n%s' "$BLOCKS" "$TODAY" | /usr/bin/python3 -c "
import json, sys
raw = sys.stdin.read().split('---')
try:
    b = json.loads(raw[0]).get('blocks', [{}])[0]
    t = json.loads(raw[1]) if len(raw) > 1 else {}
    if not b or not b.get('isActive'):
        cost, rate, tokens, rem, model = 0, 0, 0, 0, '-'
    else:
        cost = b.get('costUSD', 0)
        rate = b.get('burnRate', {}).get('costPerHour', 0)
        tokens = b.get('totalTokens', 0)
        rem = b.get('projection', {}).get('remainingMinutes', 0)
        models = b.get('models', [])
        model = models[0].replace('claude-', '') if models else '-'
    tc = b.get('tokenCounts', {})
    cache_read = tc.get('cacheReadInputTokens', 0)
    cache_creation = tc.get('cacheCreationInputTokens', 0)
    output = tc.get('outputTokens', 0)
    proj_cost = b.get('projection', {}).get('totalCost', 0)
    today_cost = t.get('totals', {}).get('totalCost', 0)
    today_tokens = t.get('totals', {}).get('totalTokens', 0)
    print(f'{cost:.2f}|{rate:.2f}|{tokens}|{rem}|{model}|{cache_read}|{cache_creation}|{output}|{proj_cost:.2f}|{today_cost:.2f}|{today_tokens}')
except Exception as e:
    print(f'0|0|0|0|err|0|0|0|0|0|0')
")

IFS='|' read -r COST RATE TOKENS REMAINING MODEL CACHE_R CACHE_C OUT PROJ TODAY_COST TODAY_TOKENS <<EOF
$DATA
EOF

if [ "$TOKENS" = "0" ]; then
  sketchybar --set "$NAME" icon="$ICON_BOLT" icon.color=0xff888888 label="idle"
  sketchybar --set "$NAME.tt" label="No active 5-hour block · today: \$$TODAY_COST ($(($TODAY_TOKENS / 1000))K tok)"
  exit 0
fi

RATE_INT=$(printf '%.0f' "$RATE")
if [ "$RATE_INT" -lt 3 ]; then COLOR=0xff80e27e
elif [ "$RATE_INT" -lt 8 ]; then COLOR=0xfff5d76e
else COLOR=0xffff5f87
fi

# Compute % of 5-hour block consumed (300 min total) — lets you see when you're running out.
# Uses elapsed = 300 - remaining to be robust against clock skew.
REM_INT=$(printf '%d' "$REMAINING" 2>/dev/null || echo 0)
if [ "$REM_INT" -gt 300 ]; then REM_INT=300; fi
ELAPSED_MIN=$(( 300 - REM_INT ))
BLOCK_PCT=$(( ELAPSED_MIN * 100 / 300 ))

sketchybar --set "$NAME" \
  icon="$ICON_BOLT" \
  icon.color="$COLOR" \
  label="\$${COST} · ${BLOCK_PCT}% · ${REMAINING}m"

# Human readable token counts
fmt_k() { awk -v n="$1" 'BEGIN{if(n>=1e6)printf "%.1fM",n/1e6;else if(n>=1e3)printf "%.1fK",n/1e3;else print n}'; }

# Block end time = 5 hours after start. ccusage block is a rolling 5-hour window
# per Claude.ai / Claude Code subscription limits (NOT daily/monthly — this is the
# per-session rate cap). New block starts on the next prompt after the 5h expires.
BLOCK_END=$(printf '%s' "$BLOCKS" | /usr/bin/python3 -c "
import json, sys, datetime as dt
try:
    b = json.load(sys.stdin)['blocks'][0]
    e = dt.datetime.fromisoformat(b['endTime'].replace('Z','+00:00')).astimezone()
    print(e.strftime('%H:%M'))
except: print('')
")

TOOLTIP="5h block (Claude rate limit) | $MODEL | block so far: \$${COST} (${BLOCK_PCT}%) -> projected \$${PROJ} | ${REMAINING}m left, resets ${BLOCK_END} | output $(fmt_k $OUT) tok, cache-read $(fmt_k $CACHE_R) tok | today total: \$${TODAY_COST}"

sketchybar --set "$NAME.tt" label="$TOOLTIP"
