#!/usr/bin/env bash
#
# bar_toggle.sh — collapse / expand sketchybar in-place.
#
# Click the toggle pill to flip every other item's `drawing` between on and
# off. The toggle itself stays visible. Useful when:
#   - a pill is rendering badly / flashing / infinite-resizing and the user
#     needs to recover without restarting sketchybar
#   - the user wants the bar out of the way temporarily without quitting it
#
# State lives in /tmp/sketchybar-collapsed.flag (file present = collapsed).
# Clean across reboots since /tmp clears at boot.

set -euo pipefail

FLAG=/tmp/sketchybar-collapsed.flag
SELF="${NAME:-bar_toggle}"

# Snapshot every item except the toggle pill itself.
items_to_toggle() {
  sketchybar --query bar 2>/dev/null \
    | jq -r '.items[]' 2>/dev/null \
    | grep -v "^${SELF}$" || true
}

if [ -f "$FLAG" ]; then
  # Currently collapsed → expand.
  while IFS= read -r item; do
    [ -z "$item" ] && continue
    sketchybar --set "$item" drawing=on >/dev/null 2>&1 || true
  done < <(items_to_toggle)
  sketchybar --set "$SELF" icon="" icon.color=0xffffffff
  rm -f "$FLAG"
else
  # Currently expanded → collapse.
  while IFS= read -r item; do
    [ -z "$item" ] && continue
    sketchybar --set "$item" drawing=off >/dev/null 2>&1 || true
  done < <(items_to_toggle)
  sketchybar --set "$SELF" icon="" icon.color=0xffff8a65
  touch "$FLAG"
fi
