#!/usr/bin/env bash
# test_aerospace_toml.sh — static checks on aerospace.toml
#
# 1. Parses as valid TOML (via Python tomllib — no external deps on macOS)
# 2. >= 200 lines (truncation regression guard; HEAD baseline is ~249)
# 3. Exactly one [workspace-to-monitor-force-assignment] section
# 4. That section sits AFTER line 200 (it's appended at the end by
#    aerospace-monitor-layout; if it surfaces at line 1, the file has been
#    truncated even if line count is also wrong)

set -euo pipefail

FILE="${AEROSPACE_CONFIG:-$HOME/.config/aerospace/aerospace.toml}"
NAME="test_aerospace_toml"
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

# 1. TOML parses
assert "parses as valid TOML" \
  "python3 -c 'import tomllib,sys; tomllib.loads(open(sys.argv[1]).read())' '$FILE'"

# 2. Line count floor
LINES=$(wc -l < "$FILE" | tr -d ' ')
assert "line count >= 200 (got $LINES)" \
  "[ $LINES -ge 200 ]"

# 3. Exactly one workspace-to-monitor-force-assignment section
SECTION_COUNT=$(grep -c '^\[workspace-to-monitor-force-assignment\]' "$FILE" || true)
assert "exactly one [workspace-to-monitor-force-assignment] section (got $SECTION_COUNT)" \
  "[ $SECTION_COUNT -eq 1 ]"

# 4. Section after line 200 — guards against the line-1 truncation shape
SECTION_LINE=$(grep -n '^\[workspace-to-monitor-force-assignment\]' "$FILE" | head -1 | cut -d: -f1 || echo 0)
assert "section starts after line 200 (got line $SECTION_LINE)" \
  "[ ${SECTION_LINE:-0} -gt 200 ]"

if (( FAIL == 0 )); then
  printf 'PASS %s — %d checks\n' "$NAME" "$PASS"
  exit 0
else
  printf 'FAIL %s — %d failed of %d\n' "$NAME" "$FAIL" "$((PASS + FAIL))" >&2
  exit 1
fi
