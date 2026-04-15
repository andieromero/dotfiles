#!/usr/bin/env bash
#
# Cycle layout modes for the focused workspace by clicking the layout pill.
#   click          -> tiles / accordion toggle
#   shift + click  -> toggle orientation (horizontal / vertical) within tiles
#   alt   + click  -> toggle floating / tiling for the focused window
#
# BUTTON and MODIFIER are provided by sketchybar when the click_script runs.

case "${MODIFIER:-none}" in
  shift)
    # Flip orientation within the current mode
    aerospace layout horizontal vertical
    ;;
  alt)
    # Yank the focused window between tiling and floating
    aerospace layout floating tiling
    ;;
  *)
    # Main toggle: tiles <-> accordion
    aerospace layout tiles accordion
    ;;
esac

# Push an immediate refresh so the pill updates without waiting for the poll
sketchybar --trigger aerospace_mode_changed
