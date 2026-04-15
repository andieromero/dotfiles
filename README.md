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
brew services start borders
open -a AeroSpace
open -a Karabiner-Elements

# 6. Install optional zsh plugins (not in Brewfile because they're git clones)
mkdir -p ~/.zsh/plugins
git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git ~/.zsh/plugins/zsh-autocomplete
git clone https://github.com/junegunn/fzf-git.sh ~/fzf-git.sh    # optional
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

| WS | Monitor when docked | Typical purpose (not pinned) |
|----|--------------------|-----------------------------|
| 1 | USB C2 (reference) | Free / scratch |
| 2 | USB C2 | Free / chat |
| 3 | USB C2 | Free |
| 4 | USB C2 | Free |
| 5 | HP E27 G5 (active) | Free / terminal-ish |
| 6 | HP E27 G5 | Free / code-ish |
| 7 | HP E27 G5 | Free / browser-ish |
| 8 | HP E27 G5 | Free / overflow |
| 9 | USB C2 (hidden from bar) | Scratch |

**No app-to-workspace auto-routing.** Every new window opens on whatever workspace you're currently looking at and tiles with the focused container. This keeps the workflow fluid — use `caps+N` (hyper key) to relocate windows after the fact, and glance at the sketchybar app icons to see where each app currently lives.

The monitor pins are by **explicit display name** (USB C2, HP E27 G5) so the layout is independent of macOS's main-display setting. When only one display is attached, every workspace falls back to `main` — all 9 workspaces collapse onto the one screen.

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

Hot pink / hot purple theme. Shows workspaces 1–8 with themed Nerd Font icons; workspace 9 is hidden (reachable only via `cmd-9`).

| Element | Behavior |
|---|---|
| Workspace pill (1–8) | Click to switch. Soft pink = inactive, **hot pink = active**, magenta-pink border = notification in one of the apps on that workspace. Each pill shows `<number> <themed icon>` plus live app-icon strip using sketchybar-app-font. |
| Chevron `` | Visual separator between workspace pills and front-app text. |
| Front app label | Name of the currently-focused app. |
| `TILES` / `H-ACC` / `V-ACC` / `FLOAT` pill (right) | Click: tiles ↔ accordion. Shift+click: flip H/V. Alt+click: float ↔ tile. |
| Clock / volume / battery | Standard right-side status. |
| Calendar pill (right) | Shows next timed event from macOS Calendar (auto-syncs Google Calendar if added to Internet Accounts). Click to open Calendar.app. |
| Bar appearance | Dark violet bar, identical on every attached monitor (`display=all`). |

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
| JankyBorders | `brew services restart borders` | — |
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
