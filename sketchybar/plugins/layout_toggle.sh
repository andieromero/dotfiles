#!/usr/bin/env bash
#
# Cycle layout modes for the focused workspace by clicking the layout pill.
#   click          -> toggle floating <-> tiling for the focused window
#   shift + click  -> toggle orientation (horizontal / vertical) within tiles
#
# Accordion mode is intentionally not exposed. Only tiles and float are used.
# BUTTON and MODIFIER are provided by sketchybar when the click_script runs.

case "${MODIFIER:-none}" in
  shift)
    aerospace layout horizontal vertical
    ;;
  *)
    aerospace layout floating tiling
    ;;
esac

# Push an immediate refresh so the pill updates without waiting for the poll
sketchybar --trigger aerospace_mode_changed
