#!/usr/bin/env bash
# tests/run.sh — orchestrate dotfile tests across layers.
#
# Usage:
#   tests/run.sh [LAYER]...
#
# LAYER selects which directories under tests/ to run. Defaults to all.
#   static       — file parsing + linting (<1s, no daemons)
#   invariants   — semantic assertions on key/item presence (<1s, no daemons)
#   e2e          — exercises aerospace + sketchybar daemons (~5s, SKIPs if down)
#   all          — alias for "static invariants e2e"
#
# Each test script under tests/<layer>/test_*.sh must:
#   - be executable
#   - print a final-line `PASS <name>` / `FAIL <name>` / `SKIP <name>`
#   - exit 0 on PASS or SKIP, non-zero on FAIL
#
# Exit code: number of failed tests (0 on full pass).

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $# -eq 0 ]] || [[ "$1" == "all" ]]; then
  LAYERS=(static invariants e2e)
else
  LAYERS=("$@")
fi

# ANSI colors when stdout is a TTY
if [[ -t 1 ]]; then
  C_BOLD=$'\e[1m'; C_DIM=$'\e[2m'
  C_GREEN=$'\e[32m'; C_RED=$'\e[31m'; C_YELLOW=$'\e[33m'
  C_RESET=$'\e[0m'
else
  C_BOLD=''; C_DIM=''; C_GREEN=''; C_RED=''; C_YELLOW=''; C_RESET=''
fi

PASS_TOTAL=0
FAIL_TOTAL=0
SKIP_TOTAL=0
FAILED_TESTS=()
SKIPPED_TESTS=()
START_TS=$(date +%s)

for layer in "${LAYERS[@]}"; do
  layer_dir="$TESTS_DIR/$layer"
  if [[ ! -d "$layer_dir" ]]; then
    printf '%s[warn]%s no such layer: %s\n' "$C_YELLOW" "$C_RESET" "$layer"
    continue
  fi

  printf '\n%s===%s %s%s%s\n' "$C_BOLD" "$C_RESET" "$C_BOLD" "$layer" "$C_RESET"

  # Find test files; sort for deterministic order.
  test_files=()
  while IFS= read -r -d '' f; do
    test_files+=("$f")
  done < <(find "$layer_dir" -maxdepth 1 -type f -name 'test_*.sh' -print0 2>/dev/null | sort -z)

  if (( ${#test_files[@]} == 0 )); then
    printf '%s  (no test files)%s\n' "$C_DIM" "$C_RESET"
    continue
  fi

  for t in "${test_files[@]}"; do
    name=$(basename "$t" .sh)
    out=$("$t" 2>&1) || rc=$? && rc=${rc:-0}
    # Last line is the verdict
    verdict=$(printf '%s\n' "$out" | tail -1)
    case "$verdict" in
      PASS*)
        PASS_TOTAL=$((PASS_TOTAL + 1))
        printf '  %s✓%s %s\n' "$C_GREEN" "$C_RESET" "$name"
        ;;
      SKIP*)
        SKIP_TOTAL=$((SKIP_TOTAL + 1))
        SKIPPED_TESTS+=("$name: ${verdict#SKIP }")
        printf '  %s⊘%s %s — %s\n' "$C_YELLOW" "$C_RESET" "$name" "${verdict#SKIP $name — }"
        ;;
      FAIL*)
        FAIL_TOTAL=$((FAIL_TOTAL + 1))
        FAILED_TESTS+=("$name")
        printf '  %s✗%s %s\n' "$C_RED" "$C_RESET" "$name"
        # Print the FULL output of failed tests so the user sees what blew up
        printf '%s\n' "$out" | sed 's/^/      /'
        ;;
      *)
        FAIL_TOTAL=$((FAIL_TOTAL + 1))
        FAILED_TESTS+=("$name (no verdict, exit $rc)")
        printf '  %s?%s %s — no PASS/FAIL/SKIP verdict (exit %d)\n' "$C_RED" "$C_RESET" "$name" "$rc"
        printf '%s\n' "$out" | sed 's/^/      /'
        ;;
    esac
  done
done

END_TS=$(date +%s)
ELAPSED=$((END_TS - START_TS))

printf '\n%s===%s summary\n' "$C_BOLD" "$C_RESET"
printf '  %s%d pass%s · %s%d fail%s · %s%d skip%s · %ds elapsed\n' \
  "$C_GREEN" "$PASS_TOTAL" "$C_RESET" \
  "$C_RED" "$FAIL_TOTAL" "$C_RESET" \
  "$C_YELLOW" "$SKIP_TOTAL" "$C_RESET" \
  "$ELAPSED"

if (( FAIL_TOTAL > 0 )); then
  printf '\n%sfailed:%s\n' "$C_RED" "$C_RESET"
  for t in "${FAILED_TESTS[@]}"; do printf '  · %s\n' "$t"; done
fi

exit "$FAIL_TOTAL"
