#!/usr/bin/env bash
# test_sketchybar_query.sh — e2e: each critical sketchybar item resolves
# via `sketchybar --query <name>` and returns valid JSON with the expected
# script wiring.
#
# SKIPs when sketchybar daemon is unreachable. JSON parsing via jq.

set -euo pipefail

NAME="test_sketchybar_query"

if ! command -v sketchybar >/dev/null 2>&1; then
  printf 'SKIP %s — sketchybar CLI not in PATH\n' "$NAME"
  exit 0
fi

if ! sketchybar --query bar >/dev/null 2>&1; then
  printf 'SKIP %s — sketchybar daemon unreachable\n' "$NAME"
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  printf 'SKIP %s — jq required for JSON assertions\n' "$NAME"
  exit 0
fi

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

# Test: item exists in sketchybar's runtime. Retry up to 3× with backoff —
# sketchybar can briefly return null for items right after a heavy trigger
# burst (e.g. when run immediately after test_display_change_refresh).
query_exists() {
  local item="$1"
  for _ in 1 2 3; do
    if sketchybar --query "$item" 2>/dev/null | jq -e '.name' >/dev/null; then
      return 0
    fi
    sleep 0.5
  done
  return 1
}

# Sketchybar nests scripts under `.scripting.*` and uses the LITERAL STRING
# `"(null)"` for unset (not a JSON null). Both quirks need handling.
# Same retry pattern as query_exists.
query_has_click_script() {
  local item="$1"
  for _ in 1 2 3; do
    if sketchybar --query "$item" 2>/dev/null \
        | jq -e '.scripting.click_script != null and .scripting.click_script != "" and .scripting.click_script != "(null)"' \
        >/dev/null; then
      return 0
    fi
    sleep 0.5
  done
  return 1
}

query_has_script() {
  local item="$1"
  for _ in 1 2 3; do
    if sketchybar --query "$item" 2>/dev/null \
        | jq -e '.scripting.script != null and .scripting.script != "" and .scripting.script != "(null)"' \
        >/dev/null; then
      return 0
    fi
    sleep 0.5
  done
  return 1
}

printf '[%s]\n' "$NAME"

# refresh: must exist + must have click_script (no top-level script= regression guard)
assert "refresh item exists" "query_exists refresh"
assert "refresh has click_script" "query_has_click_script refresh"

# hotplug_listener: must exist + must have script= (it's the listener that fires refresh.sh on display_change)
assert "hotplug_listener item exists" "query_exists hotplug_listener"
assert "hotplug_listener has script (polling/event)" "query_has_script hotplug_listener"

# tile-gap pills
assert "tile_gap_minus item exists" "query_exists tile_gap_minus"
assert "tile_gap_minus has click_script" "query_has_click_script tile_gap_minus"
assert "tile_gap_plus item exists" "query_exists tile_gap_plus"
assert "tile_gap_plus has click_script" "query_has_click_script tile_gap_plus"

# bar_toggle escape hatch
assert "bar_toggle item exists" "query_exists bar_toggle"
assert "bar_toggle has click_script" "query_has_click_script bar_toggle"

# Pulse: trigger aerospace_workspace_change must not error (used by refresh.sh)
assert "aerospace_workspace_change trigger fires cleanly" \
  "sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=1"

if (( FAIL == 0 )); then
  printf 'PASS %s — %d checks\n' "$NAME" "$PASS"
  exit 0
else
  printf 'FAIL %s — %d failed of %d\n' "$NAME" "$FAIL" "$((PASS + FAIL))" >&2
  exit 1
fi
