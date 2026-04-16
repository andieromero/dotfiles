#!/bin/bash

export WHITE=0xffffffff
export RED=0xfffda7a6
export GREEN=0xffa6da95
export GREY_TRANSP=0x44000000

# Hot palette — defined up front so items below can reference them
export HOT_PINK=0xffff1493
export HOT_PURPLE=0xffbf00ff
export SOFT_PINK=0xffffb6c1
export NOTIF_COLOR=0xffff3fa3

# Flowen/TWIN OS pill background — dusty rose, distinct from workspace soft pink
export FLOWEN_PILL_BG=0xffd97fa8

# Layout-mode indicator (tiles / accordion / floating)
export FRONT_APP_LAYOUT_ICON_COLOR=$HOT_PURPLE
export FRONT_APP_LAYOUT_BG_COLOR=$GREY_TRANSP

# Calendar event pill
export CAL_EVENT_ICON_COLOR=$HOT_PINK
export CAL_EVENT_LABEL_COLOR=$WHITE
export CAL_EVENT_BG_COLOR=$SOFT_PINK

# -- Teal Scheme --
# export BAR_COLOR=0xff001f30
# export ITEM_BG_COLOR=0xff003547
# export ACCENT_COLOR=0xff2cf9ed

# -- Gray Scheme --
# export BAR_COLOR=0xff101314
# export ITEM_BG_COLOR=0xff353c3f
# export ACCENT_COLOR=0xffffffff

# -- Hot Pink / Hot Purple Scheme (active) --
export BAR_COLOR=0xff9400d3               # dark violet bar (easier on the eyes than neon purple)
export ITEM_BG_COLOR=$SOFT_PINK           # soft pink for inactive pills
export ACCENT_COLOR=$HOT_PINK             # hot pink — active highlight

# -- Purple Scheme --
# export BAR_COLOR=0xff140c42
# export ITEM_BG_COLOR=0xff2b1c84
# export ACCENT_COLOR=0xffeb46f9

# -- Red Scheme ---
# export BAR_COLOR=0xff23090e
# export ITEM_BG_COLOR=0xff591221
# export ACCENT_COLOR=0xffff2453

# -- Blue Scheme ---
# export BAR_COLOR=0xff021254
# export ITEM_BG_COLOR=0xff093aa8
# export ACCENT_COLOR=0xff15bdf9

# -- Green Scheme --
# export BAR_COLOR=0xff003315
# export ITEM_BG_COLOR=0xff008c39
# export ACCENT_COLOR=0xff1dfca1

# -- Orange Scheme --
# export BAR_COLOR=0xff381c02
# export ITEM_BG_COLOR=0xff99440a
# export ACCENT_COLOR=0xfff97716

# -- Yellow Scheme --
# export BAR_COLOR=0xff2d2b02
# export ITEM_BG_COLOR=0xff8e7e0a
# export ACCENT_COLOR=0xfff7fc17

# -- JankyBorders --
export BORDER_ACTIVE_COLOR=$HOT_PINK
export BORDER_BACKGROUND_COLOR=$HOT_PURPLE
