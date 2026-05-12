#!/usr/bin/env bash
# test_aerospace_reload.sh — e2e: aerospace reload-config exits 0,
# list-workspaces enumerates 1..8.
#
# SKIPs when the daemon is unreachable rather than failing — e2e tests
# shouldn't gate on a missing runtime.

set -euo pipefail

NAME="test_aerospace_reload"

if ! command -v aerospace >/dev/null 2>&1; then
  printf 'SKIP %s — aerospace CLI not in PATH\n' "$NAME"
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

# 1. reload-config exits 0 against the current file
assert "aerospace reload-config exits 0" \
  "aerospace reload-config"

# 2. list-workspaces enumerates exactly 1..8 (no 9, no gaps)
WORKSPACES=$(aerospace list-workspaces --all 2>/dev/null | tr -d ' ' | sort -n | tr '\n' ' ' | sed 's/ $//')
EXPECTED="1 2 3 4 5 6 7 8"
if [[ "$WORKSPACES" == "$EXPECTED" ]]; then
  printf '  ✓ list-workspaces = 1..8 (got "%s")\n' "$WORKSPACES"
  PASS=$((PASS + 1))
else
  printf '  ✗ list-workspaces ≠ 1..8 (got "%s", expected "%s")\n' "$WORKSPACES" "$EXPECTED" >&2
  FAIL=$((FAIL + 1))
fi

# 3. At least one monitor reported
MONITORS=$(aerospace list-monitors --count 2>/dev/null)
if (( MONITORS >= 1 )); then
  printf '  ✓ %d monitor(s) detected\n' "$MONITORS"
  PASS=$((PASS + 1))
else
  printf '  ✗ no monitors detected\n' >&2
  FAIL=$((FAIL + 1))
fi

if (( FAIL == 0 )); then
  printf 'PASS %s — %d checks\n' "$NAME" "$PASS"
  exit 0
else
  printf 'FAIL %s — %d failed of %d\n' "$NAME" "$FAIL" "$((PASS + FAIL))" >&2
  exit 1
fi
