#!/usr/bin/env bash
# test_sketchybar_shellcheck.sh — shellcheck pass over sketchybar + bin scripts.
#
# Strategy: error-only (--severity=error) so the test gates on real bugs, not
# style. Warnings are noted but don't fail. SC1091 (sourced files not followed)
# and SC2034 (apparently unused vars — sketchybar plugins set vars consumed by
# the runtime, not by the script) are globally muted because both are
# false positives in this context.

set -euo pipefail

DOTFILES="${DOTFILES_DIR:-$HOME/.config}"
NAME="test_sketchybar_shellcheck"

if ! command -v shellcheck >/dev/null 2>&1; then
  printf 'SKIP %s — shellcheck not installed (brew install shellcheck)\n' "$NAME"
  exit 0
fi

# Collect targets: sketchybar config + plugins + shell-script files in bin/.
# macOS ships bash 3.2 (no mapfile/readarray); use a plain while-read loop.
TARGETS=()
while IFS= read -r -d '' f; do
  TARGETS+=("$f")
done < <(
  find "$DOTFILES/sketchybar" -type f \( -name "sketchybarrc" -o -name "*.sh" \) ! -name "*.disabled" -print0 2>/dev/null
  # Shell scripts in bin/ — detect by `file -b` reporting "shell script".
  find "$DOTFILES/bin" -maxdepth 2 -type f -print0 2>/dev/null \
    | while IFS= read -r -d '' candidate; do
        if file -b "$candidate" 2>/dev/null | grep -q "shell script"; then
          printf '%s\0' "$candidate"
        fi
      done
)

if (( ${#TARGETS[@]} == 0 )); then
  printf 'SKIP %s — no shell-script targets found\n' "$NAME"
  exit 0
fi

printf '[%s] checking %d files\n' "$NAME" "${#TARGETS[@]}"

# Run shellcheck; --severity=error so warnings don't fail the test.
if shellcheck --severity=error --shell=bash -e SC1091,SC2034 "${TARGETS[@]}"; then
  printf 'PASS %s — no errors across %d files\n' "$NAME" "${#TARGETS[@]}"
  exit 0
else
  rc=$?
  printf 'FAIL %s — shellcheck reported errors (exit %d)\n' "$NAME" "$rc" >&2
  exit 1
fi
