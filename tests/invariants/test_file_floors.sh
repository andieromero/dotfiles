#!/usr/bin/env bash
# test_file_floors.sh — minimum-line-count invariants on the configs that
# have been silently truncated before. Cheap insurance: if any of these
# critical files shrink dramatically, something nuked them.
#
# Floors are deliberately conservative — well below current HEAD line counts
# so they don't fail on legitimate trimming, but high enough to catch the
# catastrophic-truncation class of bug. Adjust here if you genuinely shrink
# a file (e.g., real refactor); don't bypass.

set -euo pipefail

NAME="test_file_floors"
PASS=0; FAIL=0

DOTFILES="${DOTFILES_DIR:-$HOME/.config}"

# (path-relative-to-DOTFILES, minimum-line-count)
FLOORS=(
  "aerospace/aerospace.toml:200"
  "sketchybar/sketchybarrc:350"
  "karabiner/karabiner.json:5"
  "zshrc:50"
  "Brewfile:30"
)

assert_floor() {
  local entry="$1"
  local path="${entry%:*}" floor="${entry##*:}"
  local full="$DOTFILES/$path"

  if [[ ! -f "$full" ]]; then
    printf '  ✗ %s missing\n' "$path" >&2
    FAIL=$((FAIL + 1))
    return
  fi

  local lines
  lines=$(wc -l < "$full" | tr -d ' ')
  if (( lines >= floor )); then
    printf '  ✓ %s (%d lines, floor %d)\n' "$path" "$lines" "$floor"
    PASS=$((PASS + 1))
  else
    printf '  ✗ %s (%d lines, floor %d) — possible truncation\n' "$path" "$lines" "$floor" >&2
    FAIL=$((FAIL + 1))
  fi
}

printf '[%s] %d files\n' "$NAME" "${#FLOORS[@]}"

for entry in "${FLOORS[@]}"; do
  assert_floor "$entry"
done

if (( FAIL == 0 )); then
  printf 'PASS %s — %d files above floor\n' "$NAME" "$PASS"
  exit 0
else
  printf 'FAIL %s — %d below floor of %d\n' "$NAME" "$FAIL" "$((PASS + FAIL))" >&2
  exit 1
fi
