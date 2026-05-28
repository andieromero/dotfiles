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

## Session Management

AI coding sessions accumulate context (conversation history) that affects response quality, speed, and cost. This setup gives you visibility into that state and tools to manage it.

### The Session Picker

Every new Ghostty window/tab opens an fzf-based session picker. Also available inside tmux with `prefix S`.

```
session > pick a session or create new
  enter=attach  tab=select  ctrl-x=kill session (ends conversation, frees RAM)

  [new] flowen repl (AVE-aware opencode)
  [new] claude (named tmux + claude)
  [new] Ghostty (plain shell)
  [new] tmux
  [tmux / opencode] mc-beta         (272K ctx  $27.44  3d ago  plan:flowen-os-mission-control-beta)
  [tmux / opencode] mvp-revisions   (279K ctx  $27.69  now)
  [tmux / opencode] pdf-change      (34K ctx   $0.26   6d ago)
  [tmux] fed                        (1d ago)
```

Each session shows:
- **Runtime**: `opencode`, `claude`, `claude+opencode`, or plain `tmux`
- **Context**: `272K ctx` = 272,000 tokens of conversation history the model processes on every message
- **Cost**: `$27.44` = total API spend for this session's lifetime
- **Age**: `3d ago` = last activity was 3 days ago
- **Plan**: `plan:flowen-os-mission-control-beta` = the flowen plan this session is working on

### Starting a New Session

When you pick `[new] flowen repl` or `[new] claude`, a **plan picker** appears:

```
plan > pick a plan to work on (esc = skip)
  !! flowen-os-mission-control-beta  (43%)  feat/poc-frontend-demo runs cleanly...
  !! flowen-os-daylight-rollout      (62%)  packages/design-tokens ships with...
  !  config-templates-001            (81%)  After merge: tag the runbook in...
     (no plan -- blank session)
```

- `!!` = HIGH priority, `!` = MEDIUM, blank = LOW
- Progress percentage and next incomplete task shown inline
- Pick a plan: session is named after it, agent boots, then `/dispatch <plan>` fires automatically
- Esc to skip: falls back to manual name prompt, starts a blank session

Claude sessions default to `--model claude-opus-4-6`.

### The Status Bar

The tmux status bar updates every 5 seconds with session context:

```
 NESTOR │ mc-beta │ flowen-os-mission-control-beta      132K ctx  $9.62   18:45
 ├─ AVE    session   plan (when set)                     context   cost    time
```

- **Left**: Active AVE (from `~/.flowen/state.toml`) + tmux session name + plan name
- **Right**: Current context window size + cumulative session cost + clock

### Understanding Context

The **context number** (e.g., `272K ctx`) is the size of the conversation history the AI model has to read and process on every new message you send. It directly affects three things:

| Context Size | Quality | Speed | Cost per Message |
|-------------|---------|-------|-----------------|
| < 50K | Full coherence | Fast | Low |
| 50K-150K | Good | Normal | Moderate |
| 150K-300K | Starts forgetting early details | Slower | High |
| 300K-500K | Noticeable degradation | Slow | Very high |
| 500K+ | Unreliable, misses instructions | Very slow | Expensive |

**Context is not RAM.** The token count represents conversation quality and cost, not system memory usage. However, each running agent process does consume RAM (typically 80-500MB depending on conversation size).

### When to Take Action

| You see in the picker | What it means | What to do |
|----------------------|---------------|------------|
| `34K ctx  $0.26  6d ago` | Small, old, cheap | **Kill it** (`ctrl-x`) — clearly stale |
| `272K ctx  $27  3d ago` | Big, idle | **Kill it** unless you need that conversation's context. Attach first to check if unsure. |
| `561K ctx  $97  1d ago` | Very big, expensive, idle | **Kill it.** At 561K the model is degrading. Start fresh on the same plan. |
| `111K ctx  $7  now` | Active, moderate | **Keep working.** Type `/compact` inside the session when it starts feeling slow. |
| `279K ctx  $28  now` | Active but getting big | **Compact now.** Type `/compact` to summarize the conversation and shrink context. Or finish current task and start a new session. |

### Actions Explained

**Kill session** (`ctrl-x` in picker):
- Ends the conversation permanently — context is gone from live memory
- Frees RAM (the agent process dies)
- Session history stays in the database (opencode sqlite / Claude JSONL) — browsable but not resumable as a live conversation
- Next time you work on the same plan, start a new session — fresh context, same task scope

**Compact** (`/compact` inside the agent):
- Summarizes the conversation history into a shorter form
- Keeps the session alive with compressed context — you continue where you left off
- Use this when you want to keep working but the session is getting slow/expensive

**Start fresh on the same plan**:
- Kill the old session, open a new one, pick the same plan
- You get a clean 0-token context with the plan's `/dispatch` loaded automatically
- The plan file itself is the persistent memory — the conversation doesn't need to be

### Cleaning Up Stale Sessions

Over time, sessions accumulate. Good practice:

1. Open the picker (`Cmd+T` or `prefix S`)
2. Look at age + context: anything with `>3d ago` and no active work is a candidate
3. `Tab` to multi-select several stale sessions
4. `ctrl-x` to kill them all at once — the list reloads with survivors
5. The currently-attached session is protected from accidental kill

**How much RAM am I using?** Each opencode process pair (node wrapper + native binary) uses 80-500MB depending on conversation size. 10 stale sessions can easily eat 1-2GB.

### Scripts Reference

| Script | Purpose |
|--------|---------|
| `ghostty-session-picker` | fzf session picker — runs on every new Ghostty window/tab, also via `prefix S` |
| `flowen-plan-picker` | fzf plan picker — called by session picker when creating new agent sessions |
| `flowen-tmux-status` | Generates tmux status bar content (AVE + plan + context + cost) |
| `claude-context-for-pid` | Given a Claude Code PID, reads JSONL transcript and emits `142K ctx  $0.83` |
| `opencode-context-for-pid` | Given an opencode PID, matches to sqlite session and emits context stats |
| `opencode-context-for-session` | Direct opencode session ID lookup for context stats |
| `claude-tmux-sync` | Renames tmux session/window to match Claude Code session name |
| `flowen-tab-launcher` | Direct-launch flowen repl without the picker (for `FLOWEN_TAB_ON_OPEN=1`) |

---

## Directory Structure

```
dotfiles/
├── bin/                    # Scripts → ~/.local/bin/
│   ├── ghostty-session-picker    # fzf session picker (Ghostty startup + prefix S)
│   ├── flowen-plan-picker        # fzf plan picker (called by session picker)
│   ├── flowen-tmux-status        # tmux status bar (AVE + plan + context)
│   ├── claude-context-for-pid    # Claude Code context stats by PID
│   ├── claude-tmux-sync          # auto-rename tmux to match Claude session
│   ├── opencode-context-for-pid  # opencode context stats by PID
│   ├── opencode-context-for-session # opencode context stats by session ID
│   ├── flowen-tab-launcher       # direct flowen repl launch (no picker)
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
