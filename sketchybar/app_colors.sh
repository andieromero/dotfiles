#!/bin/bash

# Map app name -> hex color (0xffRRGGBB) for per-app icon tinting in workspace pills.
# Add entries here to customize. Fallback = WHITE.
#
# Sourced by plugins/aerospace.sh — pure key→value function, no side effects.

app_color() {
  case "$1" in
    "Google Chrome"|"Chrome"|"Chromium"|"Arc"|"Brave Browser")
      echo "0xff4285f4" ;;           # Google blue
    "Slack")
      echo "0xff611f69" ;;           # Slack aubergine
    "Discord")
      echo "0xff5865f2" ;;           # Discord blurple
    "Windsurf"|"Cursor"|"Code"|"Visual Studio Code"|"VSCode")
      echo "0xff007acc" ;;           # VSCode blue
    "Xcode")
      echo "0xff1575f9" ;;           # Xcode blue
    "Ghostty"|"Terminal"|"iTerm2"|"iTerm"|"Alacritty"|"kitty")
      echo "0xff80e27e" ;;           # terminal green
    "Obsidian")
      echo "0xff6b47e6" ;;           # Obsidian purple
    "Notion")
      echo "0xffeeeeee" ;;           # Notion near-white
    "Linear")
      echo "0xff5e6ad2" ;;           # Linear indigo
    "Figma")
      echo "0xffa259ff" ;;           # Figma purple
    "Safari")
      echo "0xff1e9cf0" ;;           # Safari blue
    "Finder")
      echo "0xff4a9eff" ;;           # Finder blue
    "Calendar")
      echo "0xfffd5a3e" ;;           # Calendar red
    "Mail"|"Microsoft Outlook"|"Outlook"|"Spark")
      echo "0xff4a9eff" ;;           # mail blue
    "Messages"|"Signal"|"WhatsApp"|"Telegram")
      echo "0xff4caf50" ;;           # green
    "Spotify"|"Apple Music"|"Music")
      echo "0xff1db954" ;;           # Spotify green
    "Zoom"|"zoom.us"|"Google Meet")
      echo "0xff2d8cff" ;;           # Zoom blue
    "1Password"|"1Password 7 - Password Manager"|"1Password CLI")
      echo "0xff0572ec" ;;           # 1Password blue
    "System Settings"|"System Preferences")
      echo "0xff888888" ;;           # system grey
    "Activity Monitor")
      echo "0xffff5f87" ;;           # activity red
    "Claude"|"Claude Code"|"Anthropic Claude"|"Claude Desktop")
      echo "0xffd97757" ;;           # Claude terracotta
    "ChatGPT"|"OpenAI")
      echo "0xff10a37f" ;;           # OpenAI green
    "Wispr Flow")
      echo "0xffff69b4" ;;           # Wispr pink
    "Preview"|"Photos"|"Image Viewer"|"QuickTime Player")
      echo "0xffe0e0e0" ;;           # image neutral
    "Adobe Premiere Pro"|"Adobe Photoshop"|"Adobe Illustrator"|"Adobe Lightroom")
      echo "0xff9999ff" ;;           # Adobe purple-ish
    "CleanShot"|"Tuna"|"Leader Key"|"Karabiner-Elements")
      echo "0xff80e27e" ;;           # utility green
    *)
      echo "0xffffffff" ;;           # default white
  esac
}
