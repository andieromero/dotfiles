#!/usr/bin/env bash
# test_sketchybar_items.sh — assert specific sketchybar items are declared
# with the right properties in sketchybarrc.
#
# Catches the failure mode where the config parses cleanly but a key item
# (refresh button, hotplug listener, tile-gap pills) has been deleted or
# misconfigured. Each assertion targets a structural property that has
# bitten us before — see commit 9d86c53 (refresh-loop bug from putting
# script= AND click_script= on the same item).

set -euo pipefail

RC="${SKETCHYBARRC:-$HOME/.config/sketchybar/sketchybarrc}"
NAME="test_sketchybar_items"
PASS=0; FAIL=0

assert() {
  local desc="$1" cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    printf '  ✓ %s\n' "$desc"
    PASS=$((PASS + 1))
  else
    printf '  ✗ %s\n' "$desc" >&2
    FAIL=$((FAIL + 1))
  fi
}

# Extract the contiguous config block for a named item — all lines from
# `--add item <name>` up to (but not including) the next `--add item` or
# top-level `sketchybar` command. Reads the rc file once per call.
item_block() {
  local item="$1"
  awk -v item="$item" '
    $0 ~ "--add item " item "(" |"$") || $0 ~ "--add item " item "$" || $0 ~ "--add item " item " " { in_block=1 }
    in_block { print }
    in_block && NR > 1 && /--add item / && $0 !~ "--add item " item " " && $0 !~ "--add item " item "$" { exit }
  ' "$RC"
}

printf '[%s] %s\n' "$NAME" "$RC"

if [[ ! -f "$RC" ]]; then
  printf 'FAIL %s — rc file missing\n' "$NAME"
  exit 1
fi

# --- refresh button ---
# Regression guard from commit 9d86c53: refresh used to have script= AND
# click_script= pointing to the same file. That created an infinite loop
# (script ran on every poll, fired the script again via --update). Now
# refresh is click-only; hotplug_listener (separate hidden item) carries
# the script=/subscribe.
assert "refresh item declared" \
  "grep -qE '^\s*--add item refresh ' '$RC' || grep -qE 'add item refresh\\\$' '$RC'"
assert "refresh has click_script" \
  "grep -qE 'click_script=.*refresh\.sh' '$RC'"
# Must NOT have `script=` (bare, not `click_script=`) within the refresh item
# block. awk walks from `--add item refresh` to the next `--add item`; if any
# line matches `script=` but NOT `click_script=`, awk exits 1 (failing the
# assert). Empty result = clean = exit 0 = assert ✓.
assert "refresh has NO top-level script= (regression guard for 9d86c53)" \
  "awk '/--add item refresh/{flag=1; next} /--add item / && flag {flag=0} flag && /^[[:space:]]*script=/{exit 1}' '$RC'"

# --- hotplug_listener ---
# Hidden item that re-runs refresh.sh on display_change. Must be:
#   - drawing=off (invisible)
#   - script= set to refresh.sh
#   - subscribed to display_change
assert "hotplug_listener declared" \
  "grep -qE 'add item hotplug_listener' '$RC'"
assert "hotplug_listener has drawing=off" \
  "grep -qE 'drawing=off' '$RC' && awk '/--add item hotplug_listener/{flag=1; next} /--add item / && flag {flag=0} flag && /drawing=off/{found=1; exit} END{exit !found}' '$RC'"
assert "hotplug_listener has script= refresh.sh" \
  "awk '/--add item hotplug_listener/{flag=1; next} /--add item / && flag {flag=0} flag && /script=.*refresh\\.sh/{found=1; exit} END{exit !found}' '$RC'"
assert "hotplug_listener subscribed to display_change" \
  "grep -qE 'subscribe hotplug_listener display_change' '$RC'"

# --- tile-gap pills (per Task 0.2/0.5 work) ---
assert "tile_gap_minus declared" \
  "grep -qE 'add item tile_gap_minus' '$RC'"
assert "tile_gap_plus declared" \
  "grep -qE 'add item tile_gap_plus' '$RC'"

# --- bar_toggle escape hatch (from 9d86c53) ---
assert "bar_toggle declared" \
  "grep -qE 'add item bar_toggle' '$RC'"
assert "bar_toggle has click_script" \
  "awk '/--add item bar_toggle/{flag=1; next} /--add item / && flag {flag=0} flag && /click_script=.*bar_toggle\\.sh/{found=1; exit} END{exit !found}' '$RC'"

if (( FAIL == 0 )); then
  printf 'PASS %s — %d checks\n' "$NAME" "$PASS"
  exit 0
else
  printf 'FAIL %s — %d failed of %d\n' "$NAME" "$FAIL" "$((PASS + FAIL))" >&2
  exit 1
fi
