#!/bin/sh

# Some events send additional information specific to the event in the $INFO
# variable. E.g. the front_app_switched event sends the name of the newly
# focused application in the $INFO variable:
# https://felixkratz.github.io/SketchyBar/config/events#events-and-scripting

# Handle both the front_app item (shows focused app name) and the
# front_app_layout item (shows current AeroSpace layout mode).

# Return the icon + human-readable name for the focused window's layout.
get_layout_info() {
  LAYOUT=$(aerospace list-windows --focused --format '%{window-layout}' 2>/dev/null)
  case "$LAYOUT" in
    h_accordion) echo " H-ACC" ;;
    v_accordion) echo " V-ACC" ;;
    h_tiles)     echo " TILES" ;;
    v_tiles)     echo " TILES" ;;
    floating)    echo "󰉈 FLOAT" ;;
    *)           echo " —" ;;
  esac
}

if [ "$NAME" = "front_app" ]; then
  if [ "$SENDER" = "front_app_switched" ]; then
    app=$(aerospace list-windows | awk -F'|' '$1 ~ /true/ { gsub(/^ *| *$/, "", $3); print $3 }')
    sketchybar --set "$NAME" label="$app"
  fi
elif [ "$NAME" = "front_app_layout" ]; then
  # Update on every event AND on the 2s poll, so it's always in sync with
  # layout-toggle commands (alt-e / alt-,) that don't fire any event.
  INFO_STR=$(get_layout_info)
  ICON="${INFO_STR% *}"
  LABEL="${INFO_STR##* }"
  sketchybar --set "$NAME" icon="$ICON" label="$LABEL"
fi
