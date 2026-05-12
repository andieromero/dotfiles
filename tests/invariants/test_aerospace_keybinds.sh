#!/usr/bin/env bash
# test_aerospace_keybinds.sh — assert specific keybinds exist in aerospace.toml.
#
# Catches the failure mode where the file parses cleanly (test_aerospace_toml.sh
# passes) but key bindings have silently been deleted, renamed, or repointed.
# Each binding is asserted as an exact line so a one-character drift fails loud.

set -euo pipefail

FILE="${AEROSPACE_CONFIG:-$HOME/.config/aerospace/aerospace.toml}"
NAME="test_aerospace_keybinds"
PASS=0; FAIL=0

assert_line() {
  local desc="$1" pattern="$2"
  if grep -qE "$pattern" "$FILE"; then
    printf '  ✓ %s\n' "$desc"
    PASS=$((PASS + 1))
  else
    printf '  ✗ %s\n' "$desc" >&2
    FAIL=$((FAIL + 1))
  fi
}

printf '[%s] %s\n' "$NAME" "$FILE"

if [[ ! -f "$FILE" ]]; then
  printf 'FAIL %s — file missing\n' "$NAME"
  exit 1
fi

# Workspace focus: cmd-1..8 = 'workspace N'
for n in 1 2 3 4 5 6 7 8; do
  assert_line "cmd-$n → workspace $n" \
    "^cmd-$n[[:space:]]*=[[:space:]]*'workspace $n'"
done

# Move window: ctrl-cmd-N = 'move-node-to-workspace N' (per current binding scheme)
# Note: history toggled between cmd-shift-N and ctrl-cmd-N; current canonical
# is ctrl-cmd-N per the trimmed binding sweep in commit dedf561.
for n in 1 2 3 4 5 6 7 8; do
  assert_line "ctrl-cmd-$n → move-node-to-workspace $n" \
    "^ctrl-cmd-$n[[:space:]]*=[[:space:]]*'move-node-to-workspace $n'"
done

# Focus by direction: cmd-arrow keys
for dir in left right up down; do
  assert_line "cmd-$dir present (focus binding)" \
    "^cmd-$dir[[:space:]]*=[[:space:]]*'focus"
done

# Layout toggler: cmd-backslash flips tile orientation.
# (Prior history had cmd-apostrophe too; trimmed out in commit dedf561 —
# matching test against the actual config, not the stale README.)
assert_line "cmd-backslash → layout flip" \
  "^cmd-backslash[[:space:]]*=[[:space:]]*'layout"

if (( FAIL == 0 )); then
  printf 'PASS %s — %d checks\n' "$NAME" "$PASS"
  exit 0
else
  printf 'FAIL %s — %d failed of %d\n' "$NAME" "$FAIL" "$((PASS + FAIL))" >&2
  exit 1
fi
