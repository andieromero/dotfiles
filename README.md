# dotfiles

My personal macOS dev environment, managed out of `~/.config` and tracked in git.

## Target machine

Built and tested on:

- **Model:** MacBook Pro (MacBookPro18,1 — 14" 2021)
- **Chip:** Apple M1 Pro, 10 cores (8 performance + 2 efficiency)
- **Memory:** 16 GB
- **OS:** macOS 26.4 (Darwin 25.4.0)
- **Shell:** zsh 5.x (ships with macOS)
- **Homebrew prefix:** `/opt/homebrew` (Apple Silicon default)

To capture your own machine's exact specs for future reference:

```bash
system_profiler SPHardwareDataType SPSoftwareDataType | \
  grep -E "Model Name|Model Identifier|Chip|Memory|System Version|Kernel Version"
```

Intel Macs will technically work but paths in `zshrc` point to `/opt/homebrew`; on Intel the prefix is `/usr/local`, so search-and-replace those before sourcing.

## What's in here

| Path | Tool |
|---|---|
| `Brewfile` | Homebrew package manifest (single source of truth for installed tools) |
| `aerospace/aerospace.toml` | [AeroSpace](https://github.com/nikitabobko/AeroSpace) — i3-like tiling window manager |
| `sketchybar/` | [SketchyBar](https://github.com/FelixKratz/SketchyBar) — custom top bar |
| `borders/bordersrc` | [JankyBorders](https://github.com/FelixKratz/JankyBorders) — active window borders |
| `ghostty/config` | [Ghostty](https://ghostty.org) terminal |
| `karabiner/karabiner.json` | [Karabiner-Elements](https://karabiner-elements.pqrs.org) keyboard remapping |
| `starship.toml` | [Starship](https://starship.rs) prompt |
| `zshrc` | zsh shell config (symlinked to `~/.zshrc`) |
| `gh/` | GitHub CLI config |

## Bootstrapping a fresh machine

The `Brewfile` is the single source of truth for every CLI, GUI app, cask, and tap this setup depends on. To rebuild from scratch:

```bash
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Clone this repo into ~/.config
git clone <this-repo-url> ~/.config

# 3. Install everything declared in the Brewfile
brew bundle install --file=~/.config/Brewfile

# 4. Symlink shell config (zsh reads ~/.zshrc, not ~/.config/zshrc)
ln -sf ~/.config/zshrc ~/.zshrc

# 5. Start the background services
brew services start sketchybar
brew services start borders
open -a AeroSpace
open -a Karabiner-Elements
```

## macOS permissions per app

Most of these tools need permissions that can only be granted through **System Settings → Privacy & Security**. Without them, the tools will silently fail or behave partially. Grant every permission below on first install.

| App | Permission | Where | Why |
|---|---|---|---|
| **AeroSpace** | Accessibility | Privacy & Security → Accessibility | Needs to move, resize, and focus windows. Prompted on first launch. |
| **SketchyBar** | Screen Recording | Privacy & Security → Screen Recording | Reads window/app info to render icons. Toggle **off then on** if already listed — macOS needs the re-toggle to apply. Then `brew services restart sketchybar`. |
| **JankyBorders** | Accessibility + Screen Recording | Privacy & Security → Accessibility & Screen Recording | Draws border overlays and needs to know which window is focused. |
| **Karabiner-Elements** | Input Monitoring + Accessibility + Driver approval | Privacy & Security (all three) | The driver is a system extension — approve it first, then grant Input Monitoring and Accessibility. Reboot may be needed after driver approval. |
| **Ghostty** | Automation (optional) | Privacy & Security → Automation | Only if you invoke AppleScript from the terminal. Not required for daily use. |
| **Windsurf / Cursor / VS Code** | Accessibility (optional) | Privacy & Security → Accessibility | Only needed if you use editor features that drive other apps. |
| **1Password** | Accessibility | Privacy & Security → Accessibility | For global shortcut (Cmd+Shift+Space) and browser integration. |
| **Claude Code** | Full Disk Access (optional) | Privacy & Security → Full Disk Access | Only if you point it at directories outside your home (Library, System). |

Additional global setting:

- **System Settings → Control Center → Menu Bar Only → Automatically hide and show the menu bar → Always.** Hides the native macOS menu bar so SketchyBar is the only top bar visible. Equivalent terminal command: `defaults write NSGlobalDomain _HIHideMenuBar -bool true && killall SystemUIServer`.

## Auto-launch apps on login (AeroSpace 0.19+)

`after-login-command` was deprecated in AeroSpace 0.19. Use macOS Login Items instead:

**GUI:** System Settings → General → Login Items & Extensions → Open at Login → add Chrome, Ghostty, Windsurf, Slack.

**Terminal:**

```bash
for app in "Google Chrome" "Ghostty" "Windsurf" "Slack"; do
  osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"/Applications/${app}.app\", hidden:false}"
done
```

Verify:

```bash
osascript -e 'tell application "System Events" to get the name of every login item'
```

On next login AeroSpace's `on-window-detected` rules route each window to its designated workspace automatically.

## Workspace layout

Two-monitor flow (when docked), with graceful single-monitor fallback when on the go.

| WS | Monitor when docked | Pinned anchor | Launch hotkey |
|----|--------------------|---------------|---------------|
| 1 | USB C2 (reference) | Free / scratch | — |
| 2 | USB C2 | Slack | `alt-s` |
| 3 | USB C2 | Free | — |
| 4 | USB C2 | Free | — |
| 5 | HP E27 G5 (active) | Ghostty | `alt-t` |
| 6 | HP E27 G5 | Windsurf | `alt-c` |
| 7 | HP E27 G5 | Chrome | `alt-b` |
| 8 | HP E27 G5 | **Overflow / inbox** — unpinned apps land here | — |
| 9 | USB C2 (hidden from bar) | Scratch (Obsidian / Messages) | `alt-w` |

Only Ghostty, Windsurf, Chrome, and Slack are pinned. Every other app falls through to workspace 8 via a catch-all rule — use the sketchybar inbox icon on WS 8 as your reference for "what did I just open". Send anything out of 8 to a specific workspace with `caps+N`.

When only one display is attached, every pinned monitor name falls back to `main`, so all workspaces collapse onto that one screen.

### Keybindings cheat sheet

All keybindings unify around `cmd` for window management so the whole flow is on the left hand.

**Workspace navigation**

| Keys | Action |
|---|---|
| `cmd-1..9` | Switch to workspace N |
| `caps-1..9` (hyper) | Move focused window to workspace N |
| `alt-tab` | Toggle last two workspaces |
| `alt-shift-tab` | Move current workspace to the other monitor |

**Focus (window-level)**

| Keys | Action |
|---|---|
| `cmd-←/↓/↑/→` | Focus window directionally, wrapping across monitors |
| `alt-h/j/k/l` | Same, vim-style (backup) |

**Swap windows within a workspace**

| Keys | Action |
|---|---|
| `alt-shift-h/j/k/l` | Swap focused window with neighbor |
| `alt-shift-minus / equal` | Resize focused window smaller / larger |

**Layout toggles**

| Keys | Action |
|---|---|
| `cmd-\` | Tiles orientation: horizontal ↔ vertical |
| `cmd-/` | Accordion orientation: horizontal ↔ vertical |
| `cmd-.` | Tiles ↔ accordion |
| `cmd-0` | Fullscreen toggle |
| `cmd-'` | Float ↔ tile toggle |
| `alt-e` / `alt-,` / `alt-f` | Same toggles, alt-prefixed backups |

**App launchers**

| Keys | Launch |
|---|---|
| `alt-b` | Google Chrome |
| `alt-c` | Windsurf |
| `alt-t` | Ghostty |
| `alt-o` | Microsoft Outlook |
| `alt-s` | Slack |
| `alt-w` | Obsidian |
| `alt-p` | Adobe Premiere Pro |
| `alt-shift-r` | Reload SketchyBar |

**Service mode** — for fixing a broken layout

`alt-shift-;` enters service mode. While there:

| Keys | Action |
|---|---|
| `esc` | Reload config + exit |
| `r` | Flatten workspace tree (undo weird splits) |
| `f` | Toggle focused window between floating and tiling |
| `backspace` | Close every window in workspace except focused |
| `alt-shift-h/j/k/l` | Join with neighbor in that direction (changes split orientation) |

**Conflicts to know about**

These cmd combos are intercepted globally, which means they no longer work inside apps:

| Combo | What you lose |
|---|---|
| `cmd-1..9` | App tab-switching (Ghostty / Chrome / Windsurf / Finder view modes) |
| `cmd-←/→` | Text nav to start/end of line (use Home/End or `opt-←/→` for word nav) |
| `cmd-↑/↓` | Text nav to top/bottom of document (use `fn-↑/↓`) |

`cmd-tab` stays native for macOS's app switcher. `cmd-shift-<n>` is free.

### Sketchybar cheat sheet

| Element | Behavior |
|---|---|
| Workspace pill (1–8) | Click to switch. Hot pink = active. Magenta-pink border = notification in this workspace. |
| `TILES` / `H-ACC` / `FLOAT` pill | Click: tiles ↔ accordion. Shift+click: flip orientation. Alt+click: float ↔ tile. |
| Calendar pill (right side) | Shows next timed event. Click to open Calendar.app. |
| Bar | Identical on every attached monitor. |

## Re-homing windows when rules don't match open apps

`on-window-detected` rules only fire when a window is **created**, not on already-open windows. If you reload the AeroSpace config while apps are running, they stay where they are. Two ways to fix:

**Manual:** focus each stray window, press `alt-shift-<n>` to send it to the correct workspace.

**Full reset (recommended after editing rules):**

```bash
# Quit apps that may be in the wrong workspace. Keep Ghostty open — that's where you're typing.
for app in "Google Chrome" "Windsurf" "Slack" "WhatsApp" "Microsoft Outlook" \
           "Obsidian" "Plexamp" "Spotify" "Messages" "zoom.us"; do
  osascript -e "tell application \"$app\" to quit" 2>/dev/null
done
sleep 3

# Reload config and relaunch in order — each window hits its rule fresh.
aerospace reload-config
open -a "Google Chrome"
open -a "Windsurf"
open -a "Slack"
open -a "Microsoft Outlook"
open -a "Obsidian"
sleep 2

# Verify — print which workspace each window ended up on.
aerospace list-windows --all --format "%{workspace} | %{app-name} | %{window-title}" | sort
```

Expected result:

```
1 | Google Chrome | ...
2 | Windsurf | ...
3 | Ghostty | ...
4 | Microsoft Outlook | ...
6 | Slack | ...
9 | Obsidian | ...
```

If an app lands on the wrong workspace, the bundle ID in the rule doesn't match. Get the actual ID with:

```bash
osascript -e 'id of app "Windsurf"'
```

…and update the matching `if.app-id = '...'` in `aerospace/aerospace.toml`.

### Why apps sometimes don't auto-assign

- **The app launched before AeroSpace was running** — window-created event wasn't captured. Check `pgrep -x AeroSpace` and restart AeroSpace first.
- **"Reopen windows on quit" is restoring old positions** — macOS can bypass the rule. Use the `osascript quit` loop above to clear saved state.
- **Bundle ID drift** — app updates can change their identifier (e.g., `com.codeium.windsurf` vs `com.exafunction.windsurf`). Use `osascript -e 'id of app "<Name>"'` to check.

## Working with the Brewfile

The Brewfile lives at `~/.config/Brewfile`. Most `brew bundle` commands default to looking for a `Brewfile` in the current directory, so either `cd ~/.config` first or pass `--file=~/.config/Brewfile`.

```bash
# Install everything listed
brew bundle install --file=~/.config/Brewfile

# Check what's declared but not yet installed (or vice versa)
brew bundle check --verbose --file=~/.config/Brewfile

# Capture current machine state back into the Brewfile
brew bundle dump --force --file=~/.config/Brewfile

# Uninstall anything NOT in the Brewfile (dangerous)
brew bundle cleanup --force --file=~/.config/Brewfile
```

### Adding a new tool

1. Edit `Brewfile` and add one of:
   - `brew "<formula>"` for a CLI
   - `cask "<cask>"` for a GUI app
   - `tap "<org/repo>"` for a third-party tap (put these at the top)
2. Run `brew bundle install --file=~/.config/Brewfile`
3. Commit the change:

   ```bash
   cd ~/.config && git add Brewfile && git commit -m "add <tool>"
   ```

### Taps in use

- `nikitabobko/tap` — AeroSpace
- `FelixKratz/formulae` — SketchyBar, JankyBorders

## Reloading configs

| Tool | Reload command | Keybinding |
|---|---|---|
| AeroSpace | `aerospace reload-config` | `alt-shift-;` then `esc` |
| SketchyBar | `sketchybar --reload` | `alt-shift-r` |
| JankyBorders | `brew services restart borders` | — |
| zsh | `exec zsh` | — |
| Ghostty | `Cmd+Shift+,` or quit & reopen | — |

## Health check

```bash
for p in AeroSpace sketchybar borders karabiner_console_user_server; do
  pgrep -x "$p" >/dev/null && echo "✅ $p" || echo "❌ $p"
done
brew bundle check --verbose --file=~/.config/Brewfile
aerospace list-workspaces --focused
aerospace list-windows --all --format "%{workspace} | %{app-name}" | sort | head -20
```

Expected: every service ✅, Brewfile satisfied, and windows distributed across the workspaces listed above.
