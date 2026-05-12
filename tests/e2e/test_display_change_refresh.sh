#!/usr/bin/env bash
# test_display_change_refresh.sh — e2e: fire `display_change` via sketchybar
# trigger (mimics monitor hotplug without unplugging anything), then verify:
#   1. aerospace.toml line count is unchanged (no truncation race)
#   2. aerospace daemon is still responsive
#   3. all 8 workspaces still enumerable
#
# This is the proof that the Task 0.5 mkdir-lock works under the same trigger
# pattern that was historically destroying the config.

set -euo pipefail

NAME="test_display_change_refresh"
TOML="${AEROSPACE_CONFIG:-$HOME/.config/aerospace/aerospace.toml}"

if ! command -v sketchybar >/dev/null 2>&1 || ! command -v aerospace >/dev/null 2>&1; then
  printf 'SKIP %s — sketchybar or aerospace CLI missing\n' "$NAME"
  exit 0
fi
if ! sketchybar --query bar >/dev/null 2>&1; then
  printf 'SKIP %s — sketchybar daemon unreachable\n' "$NAME"
  exit 0
fi
if ! aerospace list-monitors --count >/dev/null 2>&1; then
  printf 'SKIP %s — aerospace daemon unreachable\n' "$NAME"
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

printf '[%s]\n' "$NAME"

LINES_BEFORE=$(wc -l < "$TOML" | tr -d ' ')
printf '  · pre-trigger line count: %d\n' "$LINES_BEFORE"

# Fire the display_change trigger 3× in quick succession — historically this is
# what produced the race. The Task 0.5 mkdir-lock should serialize them.
sketchybar --trigger display_change 2>/dev/null || true
sketchybar --trigger display_change 2>/dev/null || true
sketchybar --trigger display_change 2>/dev/null || true

# refresh.sh takes ~1s plus the 0.25s color-flash sleep; allow generous window.
sleep 3

LINES_AFTER=$(wc -l < "$TOML" | tr -d ' ')
printf '  · post-trigger line count: %d\n' "$LINES_AFTER"

# 1. Line count must not have shrunk significantly
if (( LINES_AFTER >= LINES_BEFORE - 5 && LINES_AFTER <= LINES_BEFORE + 5 )); then
  printf '  ✓ line count stable (%d → %d)\n' "$LINES_BEFORE" "$LINES_AFTER"
  PASS=$((PASS + 1))
else
  printf '  ✗ line count drifted (%d → %d) — possible truncation race regression\n' \
    "$LINES_BEFORE" "$LINES_AFTER" >&2
  FAIL=$((FAIL + 1))
fi

# 2. Hard floor — never below 200 (the truncation-bug shape was 10)
if (( LINES_AFTER >= 200 )); then
  printf '  ✓ aerospace.toml still ≥ 200 lines\n'
  PASS=$((PASS + 1))
else
  printf '  ✗ aerospace.toml DROPPED below 200 lines (got %d) — RACE NOT FIXED\n' "$LINES_AFTER" >&2
  FAIL=$((FAIL + 1))
fi

# 3. Daemon still responsive
assert "aerospace daemon still responsive" \
  "aerospace list-monitors --count"

# 4. Workspaces still enumerable
WORKSPACES=$(aerospace list-workspaces --all 2>/dev/null | tr -d ' ' | sort -n | tr '\n' ' ' | sed 's/ $//')
if [[ "$WORKSPACES" == "1 2 3 4 5 6 7 8" ]]; then
  printf '  ✓ all 8 workspaces still enumerable\n'
  PASS=$((PASS + 1))
else
  printf '  ✗ workspaces drifted (got "%s")\n' "$WORKSPACES" >&2
  FAIL=$((FAIL + 1))
fi

if (( FAIL == 0 )); then
  printf 'PASS %s — %d checks\n' "$NAME" "$PASS"
  exit 0
else
  printf 'FAIL %s — %d failed of %d\n' "$NAME" "$FAIL" "$((PASS + FAIL))" >&2
  exit 1
fi
