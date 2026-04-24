# dotfiles

Dev environment for macOS. Ghostty + tmux + AeroSpace + sketchybar + nvim + zsh.

## Fresh Mac Setup

### Prerequisites

1. Xcode Command Line Tools: `xcode-select --install`
2. [Homebrew](https://brew.sh): `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

### Install

```sh
git clone https://github.com/andieromero/dotfiles.git ~/Andie/dotfiles
cd ~/Andie/dotfiles
script/setup
brew bundle --file=brew/Brewfile.symlink
```

`script/setup` does three things:
- Symlinks `*.symlink` files to `~/` (e.g., `zsh/zshrc.symlink` → `~/.zshrc`)
- Symlinks XDG config dirs to `~/.config/` (ghostty, tmux)
- Symlinks scripts from `bin/` to `~/.local/bin/` (session picker, claude-tmux-sync)
- Runs platform-specific installers (`macos.sh`)

### Post-Install

1. **tmux plugins**: Open tmux, press `Ctrl+a I` (capital I) to install TPM plugins (resurrect + continuum)
2. **Claude Code hook**: Copy the hook config so Claude sessions auto-rename tmux windows:
   ```sh
   # Merge into your existing ~/.claude/settings.json:
   cat claude/settings.json
   ```
3. **Fonts**: Ghostty uses the system font — install via `brew bundle` (Iosevka, Cascadia Code, etc.)
4. **Catppuccin theme**: Ghostty ships Catppuccin Mocha built-in; no extra install needed

---

## Stack

| Layer | Tool | Config |
|-------|------|--------|
| Terminal | [Ghostty](https://ghostty.org) | `ghostty/config` |
| Multiplexer | [tmux](https://github.com/tmux/tmux) | `tmux/tmux.conf` |
| Window Manager | [AeroSpace](https://github.com/nikitabobko/AeroSpace) | `macos/aerospace.toml.symlink` |
| Status Bar | [sketchybar](https://github.com/FelixKratz/SketchyBar) | `macos/sketchybar/` |
| Window Borders | [borders](https://github.com/FelixKratz/JankyBorders) | `macos/bordersrc` |
| Editor | [Neovim](https://neovim.io) / [Cursor](https://cursor.sh) | `nvim/` / `cursor/` |
| Shell | zsh + [Oh My Posh](https://ohmyposh.dev) | `zsh/` |
| Keyboard | [Karabiner-Elements](https://karabiner-elements.pqrs.org) | `karabiner/` |
| Version Manager | [mise](https://mise.jdx.dev) | `mise/` |

---

## How Ghostty + tmux Work Together

Ghostty is the terminal emulator (renders pixels, handles fonts/colors). tmux is the multiplexer (manages windows, panes, sessions inside the terminal).

```
Ghostty window
└── tmux session
    ├── Window 1: twin-andie      ← Claude Code session
    ├── Window 2: dotfiles         ← Claude Code session
    └── Window 3: zsh              ← plain shell
```

- **Ghostty** handles: Cmd+T (new tab), Cmd+N (new window), Cmd+W (close), clipboard
- **tmux** handles: everything inside the terminal (windows, panes, splits, sessions)
- **Session picker**: New Ghostty windows open an fzf picker to create/attach tmux sessions
- **Window titles**: Claude Code session names propagate to tmux window names → Ghostty title bar via `claude-tmux-sync`

---

## Keybindings

### Ghostty

| Key | Action |
|-----|--------|
| `Cmd+T` | New tab (opens session picker) |
| `Cmd+N` | New window (opens session picker) |
| `Cmd+W` | Close tab/window |
| `Cmd+C` | Copy |
| `Cmd+V` | Paste |
| `Cmd+Q` | Quit Ghostty |
| `Shift+Enter` | Send escape sequence (Claude Code multiline) |

### tmux (prefix = `Ctrl+a`)

**Sessions & Windows**

| Key | Action |
|-----|--------|
| `prefix c` | New window (inherits cwd) |
| `prefix 1-9` | Switch to window N |
| `prefix S` | Session picker (fzf) |
| `prefix d` | Detach (session keeps running) |
| `prefix r` | Reload tmux config |

**Panes**

| Key | Action |
|-----|--------|
| `prefix \|` or `prefix \\` | Split vertically |
| `prefix -` | Split horizontally |
| `prefix h/j/k/l` | Navigate panes (vim-style) |
| `prefix H/J/K/L` | Resize panes (repeatable) |
| `prefix z` | Zoom/unzoom current pane |

**Copy Mode**

| Key | Action |
|-----|--------|
| `prefix [` | Enter copy mode (vi keys) |
| `v` | Begin selection (in copy mode) |
| `y` | Yank to macOS clipboard (in copy mode) |
| Mouse drag | Select + copy to clipboard |

### AeroSpace (see `macos/aerospace.toml.symlink` for full config)

Tiling WM — keyboard-driven workspace management. Ghostty windows tile automatically.

---

## Claude Code Integration

tmux windows auto-rename to match Claude Code sessions:

1. **SessionStart hook** (`~/.claude/settings.json`) runs `claude-tmux-sync` when a session begins
2. The script reads `~/.claude/sessions/{PID}.json` to find the session name
3. Falls back to the project directory basename if no custom name is set
4. Ghostty picks up the tmux window name via `set-titles on`

**Manual sync** (if you rename a session mid-flight):
```sh
claude-tmux-sync
```

---

## Directory Structure

```
dotfiles/
├── bin/                    # Scripts → ~/.local/bin/
│   ├── ghostty-session-picker
│   ├── claude-tmux-sync
│   └── ...
├── brew/
│   └── Brewfile.symlink    # → ~/.Brewfile
├── claude/
│   └── settings.json       # Reference config for ~/.claude/settings.json
├── ghostty/
│   └── config              # → ~/.config/ghostty/config
├── tmux/
│   └── tmux.conf           # → ~/.config/tmux/tmux.conf
├── macos/
│   ├── aerospace.toml.symlink
│   ├── bordersrc
│   └── sketchybar/
├── nvim/                   # Neovim config
├── zsh/
│   ├── zshrc.symlink       # → ~/.zshrc
│   ├── aliases.zsh
│   └── omp.toml            # Oh My Posh theme
├── karabiner/
├── git/
├── cursor/
└── script/
    └── setup               # Main installer
```
