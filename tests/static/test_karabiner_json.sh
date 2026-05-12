#!/usr/bin/env bash
# test_karabiner_json.sh — static checks on karabiner.json
#
# 1. Parses as valid JSON (via jq)
# 2. Has `profiles[].complex_modifications.rules` keypath (even if empty —
#    Karabiner refuses to start cleanly if the structure is malformed)

set -euo pipefail

FILE="${KARABINER_CONFIG:-$HOME/.config/karabiner/karabiner.json}"
NAME="test_karabiner_json"
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

printf '[%s] %s\n' "$NAME" "$FILE"

if [[ ! -f "$FILE" ]]; then
  printf 'FAIL %s — file missing: %s\n' "$NAME" "$FILE"
  exit 1
fi

# 1. Valid JSON
assert "parses as valid JSON" \
  "jq '.' '$FILE' > /dev/null"

# 2. complex_modifications.rules present on every profile
assert "every profile has complex_modifications.rules" \
  "jq -e '.profiles | map(.complex_modifications.rules) | all(. != null)' '$FILE'"

# 3. Top-level expected keys (defense against silent reset to defaults)
assert "has 'profiles' top-level key" \
  "jq -e '.profiles | type == \"array\" and length > 0' '$FILE'"

if (( FAIL == 0 )); then
  printf 'PASS %s — %d checks\n' "$NAME" "$PASS"
  exit 0
else
  printf 'FAIL %s — %d failed of %d\n' "$NAME" "$FAIL" "$((PASS + FAIL))" >&2
  exit 1
fi
