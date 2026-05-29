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
┌ sessions ──────────────────────────────────────────────────────────┐
│ session >                                                         │
│ enter·attach  ctrl-w·wrap  ctrl-f·fork  ctrl-x·kill  ctrl-d·delete│
│                                                                   │
│ ++ codu builder                                                   │
│ ++ tmux                                                           │
│ ++ claude                                                         │
│ ++ shell                                                          │
│ codu mc-beta feat/mc-beta ●3 ··········  272K $27  3d             │
│ codu mvp-revisions main ···············  279K $27  now            │
│ -- fed main ·······································  1d           │
├ code guide ────────────────────────────────────────────────────────┤
│  LEGEND / CONTEXT / ACTIONS / BEST PRACTICES                     │
└────────────────────────────────────────────────────────────────────┘
```

Each session shows:
- **Runtime**: `codu` = codu builder, `cc` = claude code, `--` = plain shell
- **Branch**: git branch name (dimmed, truncated)
- **Git status**: `●3` = 3 uncommitted files (yellow), `↑2` = 2 unpushed commits (cyan)
- **Context**: `272K` = 272,000 tokens of conversation history (green/yellow/red by health)
- **Cost**: `$27` = total API spend for this session's lifetime
- **Age**: `3d` = last activity was 3 days ago

### Starting a New Session

When you pick `++ codu builder` or `++ claude`, a **plan picker** appears:

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

**`ctrl-w` — Wrap + attach** (safest way to close):
- Opens the session and runs `/wrap` automatically
- `/wrap` commits + pushes code, runs `/learn` to extract patterns, writes a handoff doc
- Ensures nothing is lost before you kill

**`ctrl-f` — Fork session**:
- Creates a new session branched from the old conversation
- Original session stays untouched
- Use when you want to explore a different direction without losing context

**`ctrl-x` — Safe kill** (process only):
- Ends the process, frees RAM
- Conversation stays in the database — can resume later
- Use when pausing work or freeing memory

**`ctrl-d` — Full delete** (cannot undo):
- Kills process AND deletes conversation from the database
- Frees RAM + context + disk
- Use when done with a task, session is stale, or context too degraded

**`/wrap`** (type inside the session):
- Commits + pushes code to branch, runs `/learn`, writes handoff, compacts context
- Always `/wrap` before killing a session with unsaved work

**Start fresh on the same plan**:
- `ctrl-d` the old session, `++ codu builder`, pick the same plan
- You get a clean 0-token context with the plan's `/dispatch` loaded automatically
- The plan file itself is the persistent memory — the conversation doesn't need to be

### Cleaning Up Stale Sessions

Over time, sessions accumulate. Good practice:

1. Open the picker (`Cmd+T` or `prefix S`)
2. Look at age + context: anything with `>3d ago` and no active work is a candidate
3. `Tab` to multi-select several stale sessions
4. `ctrl-x` to kill them all at once — the list reloads with survivors
5. The currently-attached session is protected from accidental kill

**How much RAM am I using?** Each codu builder process pair uses 80-500MB depending on conversation size. 10 stale sessions can easily eat 1-2GB.

**Do idle sessions cost money?** No. The `$` shown is already spent. Idle sessions make zero API calls — only RAM is consumed. Cost resumes when you send a new message.

### Scripts Reference

| Script | Purpose |
|--------|---------|
| `ghostty-session-picker` | fzf session picker — runs on every new Ghostty window/tab, also via `prefix S` |
| `codu-plan-picker` | fzf plan picker — called by session picker when creating new codu builder sessions |
| `codu-tmux-status` | Generates tmux status bar content (AVE + plan + context + cost) |
| `codu-context-for-pid` | Given a codu builder PID, matches to sqlite session and emits context stats |
| `codu-context-for-session` | Direct codu builder session ID lookup for context stats |
| `claude-context-for-pid` | Given a Claude Code PID, reads JSONL transcript and emits context stats |
| `claude-tmux-sync` | Renames tmux session/window to match Claude Code session name |
| `codu-tmux-sync` | Renames tmux session/window to match codu builder session name |
| `codu-tab-launcher` | Direct-launch codu builder without the picker (for `CODU_TAB_ON_OPEN=1`) |
| `session-kill` | Full cleanup: kills process + deletes conversation from DB |

---

## Directory Structure

```
dotfiles/
├── bin/                    # Scripts → ~/.local/bin/
│   ├── ghostty-session-picker    # fzf session picker (Ghostty startup + prefix S)
│   ├── codu-plan-picker           # fzf plan picker (called by session picker)
│   ├── codu-tmux-status           # tmux status bar (AVE + plan + context)
│   ├── codu-context-for-pid       # codu builder context stats by PID
│   ├── codu-context-for-session   # codu builder context stats by session ID
│   ├── codu-tmux-sync             # auto-rename tmux to match codu session
│   ├── codu-tab-launcher          # direct codu builder launch (no picker)
│   ├── session-kill               # full cleanup (kill + delete conversation)
│   ├── claude-context-for-pid     # Claude Code context stats by PID
│   ├── claude-tmux-sync           # auto-rename tmux to match Claude session
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
