# dotfiles

My personal macOS dev environment, managed out of `~/.config` and tracked in git.

## Who this is for

This repo serves two audiences. Skim the column that matches you.

| Section / Feature | 🛠 Flowen OS contributor (forking + extending) | 👤 Flowen OS user (wants the experience) |
|---|---|---|
| Full bootstrap (Homebrew + Brewfile + symlinks) | **Required** | **Required** |
| AeroSpace + SketchyBar + JankyBorders + Karabiner | **Required** — this is the WM foundation | **Required** |
| Ghostty + tmux + zsh + Starship | **Required** | **Recommended** (any terminal works, but shell aliases expect zsh) |
| Flowen / TWIN OS pills (`ccusage`, `claude_session`, `brain_freshness`, `twin_tasks`, `wispr`) | **Core** — edit the plugin scripts | **Core** — the reason this repo exists for you |
| `ccusage` via `npm i -g ccusage` | Required | Required (only if using Claude Code) |
| `wispr-flow` cask + Login Item | Recommended | Required for voice-to-text pill |
| `ical-buddy` + Calendar permission | Recommended | Recommended (next-event pill) |
| Custom plugins under `sketchybar/plugins/` | **Edit freely** | Treat as black boxes, don't modify |
| Aerospace keybindings (`cmd-N`, `cmd-arrows`, hyper-key moves) | Learn and rebind freely | Learn the cheat sheet — don't rebind, workflow assumes defaults |
| Borders `com.user.borders.plist` LaunchAgent | Edit width/colors to taste | Install as-is |
| Workspace 1-8 layout + auto-route rules | Understand + customize | Accept as-is; apps land where you open them |
| Git history / commit conventions | Follow conventions when contributing back | Not relevant |

If you're a **user**, you mostly care about: getting the Brewfile installed, granting permissions once, and learning the keybindings cheat sheet. Skip the section on "Adding a new tool" and "Working with the Brewfile" beyond the initial install.

If you're a **contributor**, read everything and consider the plugin directory (`sketchybar/plugins/`) as the primary surface area for customization.

## What this setup solves

A keyboard-first workflow on macOS that:

- **Replaces manual window arrangement with tiling** via AeroSpace (like i3 on Linux), so windows auto-arrange and you never drag or resize.
- **Turns the top bar into an information dashboard** via SketchyBar — workspace overview, notifications, calendar, system state — instead of macOS's static menu bar.
- **Keeps every shortcut on the left hand** around `cmd`: `cmd-N` for workspaces, `cmd-arrow` for focus, `cmd-\` for layout toggles, so window management never requires reaching.
- **Moves windows with a hyper key** (caps lock remapped via Karabiner) to avoid conflicting with app-level `cmd-shift` shortcuts.
- **Persists shell sessions across crashes and reboots** via tmux, auto-attached on every Ghostty launch.
- **Makes repos one-command reachable** via env vars (`$TWIN`, `$FLOWEN`), named directory hashes (`cd ~twin`), and interactive helpers that set tab titles.
- **Is fully reproducible** — every dependency declared in the Brewfile, every config in this repo, bootstraps a fresh Mac to this exact state in < 10 minutes.

If you're picking this up for the first time, start with [Bootstrapping a fresh machine](#bootstrapping-a-fresh-machine) and then skim the [Keybindings cheat sheet](#keybindings-cheat-sheet).

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
| `sketchybar/` | [SketchyBar](https://github.com/FelixKratz/SketchyBar) — custom top bar (hot pink/purple theme) |
| `borders/bordersrc` | [JankyBorders](https://github.com/FelixKratz/JankyBorders) — active window borders |
| `ghostty/config` | [Ghostty](https://ghostty.org) terminal (opens to `$TWIN` by default) |
| `karabiner/karabiner.json` | [Karabiner-Elements](https://karabiner-elements.pqrs.org) keyboard remapping (caps lock → hyper) |
| `tmux/tmux.conf` | [tmux](https://github.com/tmux/tmux) terminal multiplexer (prefix `Ctrl+a`) |
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
open -a AeroSpace
open -a Karabiner-Elements
open -a "Wispr Flow"          # voice dictation (center pill)

# 5a. Install the custom borders LaunchAgent (auto-runs bordersrc at login).
#     The brew-generated LaunchAgent invokes `borders` bare and ignores bordersrc,
#     so we use our own. Shipped with the repo at ~/.config/borders/com.user.borders.plist.
brew services stop borders 2>/dev/null || true
cp ~/.config/borders/com.user.borders.plist ~/Library/LaunchAgents/
launchctl load -w ~/Library/LaunchAgents/com.user.borders.plist

# 5b. Install ccusage (Claude Code token/cost tracker) — required by the ccusage pill.
npm install -g ccusage

# 6. Install optional zsh plugins (not in Brewfile because they're git clones)
mkdir -p ~/.zsh/plugins
git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git ~/.zsh/plugins/zsh-autocomplete
git clone https://github.com/junegunn/fzf-git.sh ~/fzf-git.sh    # optional

# 7. Hide the native macOS menu bar so SketchyBar has the top strip
defaults write NSGlobalDomain _HIHideMenuBar -bool true && killall SystemUIServer

# 8. Enable auto-launch of core apps via macOS Login Items.
#    Wispr Flow is in this list so its global hotkey is available immediately on login
#    (without it running, the hotkey does nothing).
for app in "Google Chrome" "Ghostty" "Windsurf" "Slack" "Wispr Flow"; do
  osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"/Applications/${app}.app\", hidden:false}"
done

# 9. Start a fresh zsh so all aliases, env vars, and tmux auto-attach kick in
exec zsh
```

At this point the setup is fully active. See the [macOS permissions per app](#macos-permissions-per-app) section below for the one-time permission prompts you'll need to click through on first launch — without them, AeroSpace / SketchyBar / Karabiner will appear running but won't actually do their jobs.

## macOS permissions per app

Most of these tools need permissions that can only be granted through **System Settings → Privacy & Security**. Without them, the tools will silently fail or behave partially. Grant every permission below on first install.

| App | Permission | Where | Why |
|---|---|---|---|
| **AeroSpace** | Accessibility | Privacy & Security → Accessibility | Needs to move, resize, and focus windows. Prompted on first launch. |
| **SketchyBar** | Screen Recording | Privacy & Security → Screen Recording | Reads window/app info to render icons. Toggle **off then on** if already listed — macOS needs the re-toggle to apply. Then `brew services restart sketchybar`. |
| **JankyBorders** | Accessibility + Screen Recording | Privacy & Security → Accessibility & Screen Recording | Draws border overlays and needs to know which window is focused. |
| **Wispr Flow** | Accessibility + Input Monitoring + Microphone | Privacy & Security (all three) | Without these the global dictation hotkey won't fire. After granting, restart Wispr Flow. |
| **sketchybar + icalBuddy** | Calendars (Full Access) | Privacy & Security → Calendars → Full Access | Required for the next-event pill. Click `+` and add `/opt/homebrew/bin/sketchybar` and `/opt/homebrew/bin/icalBuddy`. Restart sketchybar after. |
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

### How it works at a glance

- **9 workspaces** (like Linux i3). Only 1-8 show up in SketchyBar; workspace 9 is a hidden scratch area you reach only via `cmd-9`.
- Workspaces are **split across two physical monitors** when docked, but **collapse onto whichever monitor is attached** when you're on the go. The layout self-heals — no reconfiguration when you unplug the external displays.
- **No per-app auto-routing.** A new Slack window doesn't teleport to "the chat workspace." It opens on whichever workspace you're looking at, tiles with the focused container, and you move it later with the hyper key if you want.
- The bar's app-icon strip on each pill tells you at a glance **which apps live on which workspace right now** — no mental bookkeeping.

### Main display vs secondary display

The layout uses **two named displays** instead of relying on macOS's "main display" setting:

- **Main display** = your working monitor (the one you're looking at most of the time). For this machine that's the **HP E27 G5** external when docked, the **laptop screen** when mobile.
- **Secondary display** = the reference / chat / overflow monitor. Currently the **USB C2** portrait display when docked.

Display names are matched by the exact string AeroSpace reports — check yours with `aerospace list-monitors`. Edit the `monitor.` keys in `aerospace.toml` if your screens have different names.

### Workspace-to-display mapping

| WS | Display when docked | Display when mobile | Typical purpose (not pinned) |
|----|---------------------|---------------------|-------------------------------|
| 1 | Secondary (USB C2) | Main (laptop) | Free / scratch / browser reference |
| 2 | Secondary (USB C2) | Main (laptop) | Chat (Slack, Messages) |
| 3 | Secondary (USB C2) | Main (laptop) | Free / overflow |
| 4 | Secondary (USB C2) | Main (laptop) | Free / overflow |
| 5 | Main (HP E27 G5) | Main (laptop) | Terminal / tmux |
| 6 | Main (HP E27 G5) | Main (laptop) | Code (Windsurf / Cursor) |
| 7 | Main (HP E27 G5) | Main (laptop) | Browser (Chrome primary) |
| 8 | Main (HP E27 G5) | Main (laptop) | Inbox / overflow |
| 9 | Secondary (USB C2) — hidden from bar | Main (laptop) — hidden from bar | Scratch / experimental |

**Key insight:** the monitor pins are by **display name**, not by macOS's main-display flag. So even if macOS thinks your laptop is the main display, AeroSpace still sends workspaces 5-8 to the HP E27 G5 when it's attached. Plug or unplug monitors and windows flow to the correct place without reconfiguration.

**When only one display is attached** (laptop on the go, or a single external), every workspace collapses to the one available screen. All 9 fit on the one monitor — use `cmd-1..9` to cycle between them as usual.

**Exception — always-float apps:** System Settings, Calculator, QuickTime, Finder "Get Info" popups, and 1Password Quick Access always open as floating windows regardless of workspace. Edit the `on-window-detected` block in `aerospace.toml` to change.

**Exception — always-float apps:** System Settings, Calculator, QuickTime, Finder "Get Info" popups, and 1Password Quick Access always open as floating windows regardless of workspace.

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
| `cmd-shift-w` | Close focused window |
| `cmd-w` | Close tab/window (app-level, native macOS) |
| `cmd-q` | Quit app entirely |
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

Hot pink / hot purple theme. Shows workspaces 1–8 with themed Nerd Font icons; workspace 9 is hidden (reachable only via `cmd-9`). All pills share the same soft-pink background (`$ITEM_BG_COLOR`); the single keyboard-focused workspace turns hot pink.

#### Left-side pills

| Element | Behavior |
|---|---|
| Refresh button | Click to force a full resync of all pill icons + scripts. |
| **Workspace pill (1–8)** | Click to switch. Soft pink = inactive, **hot pink = keyboard-focused** (only one at a time, even on multi-monitor). Each pill shows `<number> <themed-glyph>` with a colored per-workspace icon (yellow star, blue chat, green plus, violet terminal, coral code, teal globe, amber inbox) plus live app-icon strip via sketchybar-app-font. Magenta border = unread notification. |
| Chevron | Visual separator between workspace pills and front-app text. |
| Front app label | Name of the currently-focused app. |

#### Right-side pills (right → left reading order)

| Element | Icon | Behavior |
|---|---|---|
| Clock | — | Date + time. |
| Volume | Speaker glyph | Icon-only (no % label). **Click:** opens Sound in System Settings. |
| Battery | Battery level glyph (charging: battery+bolt) | `<icon> N%`. Level-appropriate glyph, bolt overlay when on AC power. |
| Bluetooth | Bluetooth glyph | Icon-only (no count). **Click:** opens Bluetooth in System Settings. |
| **ccusage** | Lightning bolt | `$cost · X% · Ym` — active 5-hour block cost, % of block consumed, minutes remaining. Green <$3/h, yellow <$8/h, red ≥$8/h. **Hover:** model, projected block total, output/cache tokens, today's total cost, block reset time. Explains that this is a 5-hour rolling rate limit (not daily or monthly). **Click:** opens Claude.app. Requires `npm install -g ccusage`. |
| **Claude session** | Robot | `N× <project>` — shows when `claude` processes are running, with the most-recent project dir as hint. Hidden when no claude process. **Hover:** top 5 recent project dirs with mtime age. **Click:** opens Claude.app. |
| **Brain freshness** | Brain | `<Name> twins Nm/Nh/Nd` — age of `brain-health/progress.md`. Dynamic name derived from `~/Flowen/twin-<name>/` directory. Green <6h, yellow <24h, red ≥24h. **Hover:** exact timestamp + first section heading. **Click:** opens Claude.app. |
| **TWIN tasks** | Task list | `N open · X%` — open `- [ ]` checkbox count across `experiences/plans/*.md` with completion percentage. Green if 0 open, yellow <5, red ≥5. **Hover:** top-3 plans by open count. **Click:** opens Claude.app. |
| **Calendar** | Calendar | `{title 4 chars}... now` if a meeting is active, or `{title 4 chars}... in Xhr Ymin` for the next meeting. Queries Calendar.app via AppleScript (skips all-day events, holidays, birthdays). **Hover:** full title + time + calendar name. **Click:** opens Google Calendar in browser. |
| `TILES` / `H-ACC` / `V-ACC` / `FLOAT` | Layout icon | Current tiling mode. Click: toggle tiles/accordion. Small font, compact. |
| Bar appearance | — | Dark violet bar (`$BAR_COLOR`), identical on every attached monitor (`display=all`). |

#### Tooltip popups

All TWIN OS / AI pills (ccusage, claude_session, brain_freshness, twin_tasks, calendar) have hover tooltips (sketchybar popups). Popups are right-aligned (`popup.align=right`) so they grow leftward and don't overflow off the right edge of the screen.

### Shell extras

| Keys / Command | Behavior |
|---|---|
| Type first character → dropdown | zsh-autocomplete shows live completions. Arrow keys navigate, Enter selects, Esc dismisses. |
| `Ctrl+R` | Fuzzy history search |
| `Ctrl+F` | Open current command line in `$EDITOR` (Windsurf) |
| `→` (end of line) | Accept zsh-autosuggestions inline suggestion from history |
| `cd ~twin` / `cd ~flowen` / `cd ~dots` | Named directory hashes |
| `$TWIN` / `$FLOWEN` | Env vars pointing at those repo paths |
| `twin` / `flowen` | Functions that cd into repo + set Ghostty tab title |
| `wind <path>` | Open files/dirs in Windsurf |
| `zshconfig` / `aeroconfig` / `barconfig` / `ghosttyconfig` / `tmuxconfig` | Quick-edit aliases |
| Git aliases | `g`, `gs`, `ga`, `gaa`, `gco`, `gci`, `gca`, `gp`, `gpf`, `gl`, `glog`, `gd`, `gds`, `gfa`, `gdmb`, `grb`, `gsh`, `gshp` |

## Resetting workspace layouts

Since there's no per-app auto-routing, windows stay where you put them. If a workspace's tile tree gets tangled (stuck floating states, weird splits), use service mode to reset it:

- `alt-shift-;` → enter service mode → `r` (flatten tree) → `esc` (exit)

Full reset of every workspace (run in Ghostty):

```bash
for ws in 1 2 3 4 5 6 7 8 9; do
  aerospace workspace $ws
  aerospace layout tiles
  aerospace flatten-workspace-tree
done
aerospace workspace 5
```

Inspect where each window currently lives:

```bash
aerospace list-windows --all --format "%{workspace} | %{window-layout} | %{app-name}" | sort
```

### If a window is stuck floating

Focus it, then `cmd+'` (float↔tile toggle). If the window snaps into the tile, the tree was fine and just the window was floating.

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
| JankyBorders | `launchctl kickstart -k gui/$(id -u)/com.user.borders` | — |
| zsh | `exec zsh` | — |
| Ghostty | `Cmd+Shift+,` or quit & reopen | — |
| tmux | `tmux source-file ~/.config/tmux/tmux.conf` | `prefix r` (prefix = `Ctrl+a`) |

## tmux auto-attach

Every Ghostty tab automatically attaches to (or creates) a tmux session named `main` when the shell starts. This means:

- **Your shell history and running processes survive** closing Ghostty, crashes, and even reboots (tmux stays alive until the Mac shuts down).
- **Every new Ghostty tab joins the same session**, so you can open ten tabs and they're all windows inside one tmux session — switch between them with tmux's own `prefix <number>` or `Ctrl+a n / p`.
- **Prompt + sketchybar-style status bar at the bottom** — that hot-pink strip is how you know tmux is running.

### Checking whether you're in tmux

```bash
echo $TMUX          # prints a path when inside tmux, empty when not
tmux ls             # list sessions (works inside and outside)
```

### Starting fresh without tmux

Set `NO_TMUX=1` before launching zsh:

```bash
NO_TMUX=1 zsh
```

Useful when debugging, running one-shot commands, or copying a big block to a shell you don't want tmux to capture.

### Detaching without closing

`Ctrl+a d` (prefix + d) detaches. The session keeps running in the background — close Ghostty, reopen it, and the next tab auto-reattaches to exactly where you left off.

## Ghostty tabs ↔ AeroSpace interaction

Ghostty is set to **native macOS tabs** (`macos-titlebar-style = native`). That means when you press **`Cmd+T`** to open a new tab, macOS creates a grouped window — which AeroSpace sees as a separate tile. Your workspace will split in half to accommodate it.

This is a deliberate tradeoff: native tabs give you the nicer macOS UI (Cmd+Shift+[ / Cmd+Shift+] to cycle, merge/unmerge via View menu, proper "Show all tabs" with Cmd+Option+L) but require you to manage the AeroSpace split.

### Reclaiming a single Ghostty window after Cmd+T splits

**Option A — Close the second tab and go back to one window:**

- `Cmd+W` → closes the active tab. If that was the only other tab, you're back to a single Ghostty window and AeroSpace re-flows the workspace to fill the space.

**Option B — Merge the two windows back into one with native tabs:**

- Click inside the second Ghostty window → View menu → **Merge All Windows**.
- macOS collapses them back into one window with two tabs at the top. AeroSpace sees only one window again and the split disappears.

**Option C — Move the second tab to a different workspace:**

- Focus the new Ghostty window → `caps+<N>` (hyper-key, N = 1..9) sends it to workspace N. Your original workspace returns to the pre-split tile.

**Option D — Cycle existing tabs without Cmd+T (no split at all):**

- `Cmd+Shift+]` / `Cmd+Shift+[` cycles through existing tabs.
- `Cmd+Opt+L` opens "Show all tabs" overview.
- These don't create new windows, so AeroSpace is quiet.

### If this gets annoying

Switch Ghostty to **internal tabs** — change `~/.config/ghostty/config` to:

```
macos-titlebar-style = tabs
```

Quit + reopen Ghostty. Tabs become purely Ghostty-drawn (Ghostty's own tab strip replaces the macOS title bar). AeroSpace never sees the new tabs as windows, so `Cmd+T` stops splitting — at the cost of losing native tab conveniences listed above.

### Most-used tmux keys (prefix is `Ctrl+a`)

| Keys | Action |
|---|---|
| `prefix c` | New tmux window |
| `prefix \|` or `prefix \\` | Split pane right |
| `prefix -` | Split pane down |
| `prefix h/j/k/l` | Navigate panes (vim-style) |
| `prefix H/J/K/L` | Resize panes (repeatable) |
| `prefix z` | Zoom focused pane to fullscreen (toggle) |
| `prefix <n>` | Switch to window N |
| `prefix n` / `prefix p` | Next / previous window |
| `prefix ,` | Rename window |
| `prefix [` | Enter copy mode (vi keys; `v` select, `y` yank to macOS clipboard) |
| `prefix d` | Detach (session keeps running) |
| `prefix r` | Reload `tmux.conf` |

### Session management

```bash
tmux ls                    # list sessions
tmux a                     # attach to the last session (defaults to "main")
tmux a -t <name>           # attach to a specific session
tmux new -s <name>         # create a new named session
tmux kill-session -t main  # nuke the "main" session (all windows/panes die)
```

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

## Troubleshooting

Most problems fall into one of these buckets. Check in order.

### SketchyBar doesn't appear on screen

1. **macOS menu bar isn't hidden.** SketchyBar draws over, and the native menu bar can be covering the pills. Run `defaults write NSGlobalDomain _HIHideMenuBar -bool true && killall SystemUIServer`.
2. **Screen Recording permission missing.** System Settings → Privacy & Security → Screen Recording → toggle `sketchybar` off then back on. Then `brew services restart sketchybar`.
3. **Process died.** `pgrep -x sketchybar` should return a PID. If not, `brew services restart sketchybar` and check `tail -30 "$(brew --prefix)/var/log/sketchybar/sketchybar.err.log"`.

### Workspace pills show `:slack:` or `:windsurf:` as literal text

`sketchybar-app-font` isn't installed or loaded. Fix:

```bash
brew install --cask sketchybar-app-font
brew services restart sketchybar
```

If brew doesn't have the cask, fall back to:

```bash
curl -fL https://github.com/kvndrsslr/sketchybar-app-font/releases/latest/download/sketchybar-app-font.ttf \
  -o ~/Library/Fonts/sketchybar-app-font.ttf
brew services restart sketchybar
```

### Cmd+T in Ghostty splits the workspace

Known tradeoff — Ghostty's native macOS tabs register as separate windows. See [Ghostty tabs ↔ AeroSpace interaction](#ghostty-tabs-↔-aerospace-interaction) for reclaim flow. If the split bothers you, swap `macos-titlebar-style = native` → `macos-titlebar-style = tabs` in `ghostty/config` and restart Ghostty.

### `cmd+1..9` or `cmd+arrow` doesn't switch workspaces

AeroSpace isn't running or lost accessibility permission. Check:

```bash
pgrep -x AeroSpace || open -a AeroSpace
```

If running: System Settings → Privacy & Security → Accessibility → ensure AeroSpace is enabled. Toggle off/on to reset.

### `caps+N` (hyper) doesn't move windows

Karabiner's hyper-key rule isn't active.

```bash
pgrep -f karabiner_console_user_server  # should return a PID
```

If not running, open Karabiner-Elements.app once and grant all three required permissions (Driver, Input Monitoring, Accessibility). Hit caps lock alone in any text field — it should do nothing (not toggle caps). If it toggles caps, the remap rule isn't loaded.

### Env vars `$TWIN` / `$FLOWEN` are empty in a new shell

`~/.zshrc` isn't symlinked to `~/.config/zshrc`. Check:

```bash
ls -la ~/.zshrc
# expected: ~/.zshrc -> /Users/you/.config/zshrc
```

If it's a real file, symlink it:

```bash
mv ~/.zshrc ~/.zshrc.backup
ln -s ~/.config/zshrc ~/.zshrc
exec zsh
```

### Ghostty opens in `~` instead of `$TWIN`

The `working-directory` config only applies to **new** windows. Existing windows restore from their last cwd. Quit Ghostty fully (`Cmd+Q`) and reopen.

### New apps don't tile (open as floating instead)

A previous floating state is stuck. Focus the window and press `cmd+'` to toggle back to tiled, or:

```bash
aerospace flatten-workspace-tree   # flattens the focused workspace
```

### tmux status bar not showing

You're not actually inside tmux. `echo $TMUX` should print a path. If empty, run `tmux` to start, or restart your shell with `exec zsh` to trigger the auto-attach.

### Something's drastically wrong — nuclear reset

```bash
# Kill everything
brew services stop sketchybar borders
osascript -e 'tell application "AeroSpace" to quit'
osascript -e 'tell application "Karabiner-Elements" to quit'

# Reload from clean state
brew bundle install --file=~/.config/Brewfile
brew services start sketchybar borders
open -a AeroSpace
open -a Karabiner-Elements

# Verify
for p in AeroSpace sketchybar borders karabiner_console_user_server; do
  pgrep -x "$p" >/dev/null && echo "✅ $p" || echo "❌ $p"
done
```

## JankyBorders — why a custom LaunchAgent

Out of the box, `brew services start borders` installs `~/Library/LaunchAgents/homebrew.mxcl.borders.plist`, which invokes `/opt/homebrew/bin/borders` **with no arguments**. That means your `~/.config/borders/bordersrc` (active color, width, blacklist) is ignored — borders runs with defaults.

We replace it with `~/.config/borders/com.user.borders.plist` (shipped in this repo), which runs `bordersrc` instead. Benefits:

- `active_color`, `width`, `blacklist` etc. actually take effect
- Auto-restarts if borders crashes (`KeepAlive`)
- Logs to `/tmp/borders.{out,err}.log`
- Portable — uses `$HOME` instead of a hardcoded user path
- 5-second startup delay so macOS TCC (Screen Recording / Accessibility permissions) is fully initialized before borders tries to read window focus state. Without this, borders launches at login but can't see any windows and draws nothing until you manually toggle the Screen Recording permission off/on.
- `ThrottleInterval=10` prevents KeepAlive from hammer-restarting if borders crashes during the TCC init window.

**Install:**

```bash
brew services stop borders 2>/dev/null || true
cp ~/.config/borders/com.user.borders.plist ~/Library/LaunchAgents/
launchctl load -w ~/Library/LaunchAgents/com.user.borders.plist
```

**Reload after editing `bordersrc`:**

```bash
launchctl kickstart -k gui/$(id -u)/com.user.borders
```

**Uninstall (fall back to brew service):**

```bash
launchctl unload ~/Library/LaunchAgents/com.user.borders.plist
rm ~/Library/LaunchAgents/com.user.borders.plist
brew services start borders
```

## TWIN OS / Flowen pills

Right-side sketchybar pills that surface information from your TWIN OS brain and Claude Code workflow. All share the same soft-pink background as other pills and all click to open Claude.app.

| Pill | Script | Label | Icon | Requires |
|---|---|---|---|---|
| ccusage | `plugins/ccusage.sh` | `$cost · X% · Ym` — 5-hour block cost, % consumed, minutes left. Color-coded by burn rate. | Lightning bolt | `npm install -g ccusage` |
| Claude session | `plugins/claude_session.sh` | `N× <project>` — active Claude Code processes + recent project. Hidden when idle. | Robot | Claude Code CLI |
| `<Name>` twins | `plugins/brain_freshness.sh` | Age of `brain-health/progress.md`. Green <6h, yellow <24h, red ≥24h. | Brain | `$HOME/Flowen/twin-<name>/brain-health/progress.md` |
| TWIN tasks | `plugins/twin_tasks.sh` | `N open · X%` — open `- [ ]` checkboxes across `experiences/plans/*.md`. | Task list | `$HOME/Flowen/twin-<name>/experiences/plans/` |
| Calendar | `plugins/calendar_event.sh` | `{4-char title}... now` or `...in Xhr Ymin`. Queries Calendar.app via AppleScript, skipping all-day events and holiday calendars. Click opens Google Calendar. | Calendar | Calendar.app synced with Google (via Internet Accounts) |

All five pills have **hover tooltips** (right-aligned popups) with expanded detail: token projections, plan breakdowns, exact timestamps, and meeting info.

**Wispr Flow** is not shown in the bar — it uses its own native overlay at the bottom of the screen. Wispr Flow is added to macOS Login Items so the dictation hotkey is available immediately on boot. Grant Accessibility + Input Monitoring + Microphone to both the outer app and the inner helper at `/Applications/Wispr Flow.app/Contents/Resources/swift-helper-app-dist/Wispr Flow.app`.

### Plugin icon encoding

All Nerd Font glyphs in plugin scripts are encoded as UTF-8 byte escapes via `printf '\xEF\x83\xA7'` (for U+F0E7 etc.) because macOS ships `/bin/bash` 3.2 which doesn't support `$'\uHHHH'`. If you add a new glyph, convert the codepoint U+XXXX to UTF-8 bytes (search "unicode to utf-8 hex") and use the `printf` pattern.

### Dynamic `<Name>` derivation

The brain-freshness pill shows `Andie twins 4h`, `Casey twins 12m`, etc. Name resolution order:

1. `$TWIN_NAME` env var (set in `zshrc` to force a value)
2. Directory name after `twin-` in `$HOME/Flowen/twin-*/`
3. `$USER`

Contributors who fork this repo will see their own name automatically as long as they follow the `$HOME/Flowen/twin-<name>/` convention from the [TWIN OS template](https://github.com/flowen/twin).

## Updating your own repo from this one

```bash
cd ~/.config
git pull origin main                       # pull any remote changes
brew bundle install --file=Brewfile        # pick up new brew packages
aerospace reload-config
sketchybar --reload
launchctl kickstart -k gui/$(id -u)/com.user.borders
exec zsh
```

## TL;DR

A keyboard-first, tiling-window macOS setup with a dashboard-style top bar that surfaces your Claude Code usage, TWIN OS brain state, open tasks, next meeting, and battery/bluetooth — so your AI workflow is always one glance away.

**If you're here to use it:**

1. Run the [Bootstrapping steps](#bootstrapping-a-fresh-machine) (10 min).
2. Grant every permission in [macOS permissions per app](#macos-permissions-per-app) — including **Wispr Flow (3 permissions + inner helper)**, **sketchybar + icalBuddy for Calendars**, and **borders for Screen Recording**. Skip these and pills silently no-op / borders won't draw.
3. Skim the [Keybindings cheat sheet](#keybindings-cheat-sheet). Left hand on `cmd`, workspace moves with caps-lock hyper.
4. Glance at [TWIN OS / Flowen pills](#twin-os--flowen-pills) to understand the right-side pills on the top bar.
5. You're done. Don't edit plugin scripts unless you want to extend them.

**If you're here to fork and extend:**

1. Do everything above.
2. Read [Workspace layout](#workspace-layout) to understand the main/secondary display model.
3. Plugin scripts live in `sketchybar/plugins/`. Colors in `sketchybar/colors.sh`. WM behavior in `aerospace/aerospace.toml`. Borders visuals in `borders/bordersrc`. App→color icon map in `sketchybar/app_colors.sh`.
4. Custom LaunchAgent for borders is in `borders/com.user.borders.plist` — see [JankyBorders — why a custom LaunchAgent](#jankyborders--why-a-custom-launchagent) for why the brew service isn't enough and why the 5-second startup delay exists (TCC timing).
5. `$TWIN_NAME` env var lets you hard-override the name shown on the brain-freshness pill; otherwise it auto-derives from `$HOME/Flowen/twin-<name>/`.
6. Plugin icons use UTF-8 byte escapes (`printf '\xEF\x83\xA7'`) because macOS `/bin/bash` 3.2 doesn't support `$'\uHHHH'`. See [Plugin icon encoding](#plugin-icon-encoding).

**What runs automatically on login** (no manual commands after reboot):

- AeroSpace, Karabiner, SketchyBar — via brew services + LaunchAgents
- JankyBorders — via `com.user.borders` custom LaunchAgent (5s delay for TCC init, auto-restarts on crash via KeepAlive)
- Ghostty, Chrome, Windsurf, Slack, Wispr Flow — via macOS Login Items

**What still needs manual action once, ever:** granting the permissions listed in [macOS permissions per app](#macos-permissions-per-app). macOS does not let us script these. If borders appear to run but don't draw after login, toggle Screen Recording off/on for `borders` in System Settings — this is a known macOS TCC timing quirk documented in the [JankyBorders section](#jankyborders--why-a-custom-launchagent).
