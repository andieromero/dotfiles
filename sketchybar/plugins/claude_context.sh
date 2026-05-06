#!/usr/bin/env bash
# claude_context.sh: Sketchybar pill showing Claude Code context window usage.
# Reads from ~/.claude/sketchybar-context.json (written by statusline.sh).

source "$CONFIG_DIR/colors.sh"

CTX_FILE="$HOME/.claude/sketchybar-context.json"

if [ ! -f "$CTX_FILE" ] || [ ! -s "$CTX_FILE" ]; then
  # No active Claude session
  sketchybar --set "$NAME" drawing=off
  sketchybar --set claude_context.tt label="No active Claude session"
  exit 0
fi

# Check file age — if older than 2 minutes, session is likely dead
file_age=$(( $(date +%s) - $(stat -f %m "$CTX_FILE" 2>/dev/null || echo 0) ))
if (( file_age > 120 )); then
  sketchybar --set "$NAME" drawing=off
  sketchybar --set claude_context.tt label="No active Claude session"
  exit 0
fi

# Parse JSON
eval "$(python3 -c '
import json, sys
try:
    with open(sys.argv[1]) as f:
        d = json.load(f)
    print(f"used_pct={d.get(\"used_pct\", 0)}")
    print(f"window_size={d.get(\"window_size\", 200000)}")
    print(f"total_in={d.get(\"total_in\", 0)}")
    print(f"total_out={d.get(\"total_out\", 0)}")
    print(f"total_cost={d.get(\"total_cost\", 0)}")
    print(f"cache_hit_pct={d.get(\"cache_hit_pct\", 0)}")
    print(f"model=\"{d.get(\"model\", \"?\")}\"")
    print(f"session_name=\"{d.get(\"session_name\", \"\")}\"")
    print(f"rl5h_pct={d.get(\"rl5h_pct\", 0)}")
    print(f"lines_added={d.get(\"lines_added\", 0)}")
    print(f"lines_removed={d.get(\"lines_removed\", 0)}")
    print(f"duration_min={d.get(\"duration_min\", 0)}")
except:
    print("used_pct=0")
    print("model=\"?\"")
' "$CTX_FILE" 2>/dev/null)" || { sketchybar --set "$NAME" drawing=off; exit 0; }

# Color based on usage
if (( used_pct >= 90 )); then
  icon_color=0xffff0000   # bright red
  bg_color=0xffff1493     # hot pink bg
elif (( used_pct >= 75 )); then
  icon_color=0xffff6b6b   # red
  bg_color=$ITEM_BG_COLOR
elif (( used_pct >= 50 )); then
  icon_color=0xffffd93d   # yellow
  bg_color=$ITEM_BG_COLOR
else
  icon_color=0xff51cf66   # green
  bg_color=$ITEM_BG_COLOR
fi

# Compact bar (5 chars)
bar_filled=$(( used_pct * 5 / 100 ))
bar_empty=$(( 5 - bar_filled ))
bar=""
for ((i=0; i<bar_filled; i++)); do bar+="█"; done
for ((i=0; i<bar_empty; i++)); do bar+="░"; done

# Format window size
if (( window_size >= 1000000 )); then
  ws_label="1M"
else
  ws_label="200K"
fi

sketchybar --set "$NAME" \
  drawing=on \
  icon="󰧑" \
  icon.color="$icon_color" \
  label="${bar} ${used_pct}%" \
  background.color="$bg_color"

# Tooltip
tooltip="${used_pct}% of ${ws_label} context"
tooltip="${tooltip} | \$${total_cost} cost"
tooltip="${tooltip} | ${model}"
if [ -n "$session_name" ]; then
  tooltip="${tooltip} | ${session_name}"
fi
tooltip="${tooltip} | +${lines_added}/-${lines_removed} lines"
tooltip="${tooltip} | cache ${cache_hit_pct}%"
if (( duration_min > 0 )); then
  tooltip="${tooltip} | ${duration_min}m"
fi
if (( rl5h_pct > 0 )); then
  tooltip="${tooltip} | RL:${rl5h_pct}%"
fi

sketchybar --set claude_context.tt label="$tooltip"
