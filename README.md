# dotfiles

My personal macOS dev environment, managed out of `~/.config` and tracked in git.

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

After step 5, grant the one-time macOS permissions these tools need:

- **Karabiner** — System Settings → Privacy & Security → approve the driver, then grant Input Monitoring + Accessibility.
- **SketchyBar** — System Settings → Privacy & Security → Screen Recording → enable `sketchybar`, then `brew services restart sketchybar`.
- **AeroSpace** — will prompt for Accessibility on first launch.

## Working with the Brewfile

The Brewfile lives at `~/.config/Brewfile`. Most `brew bundle` commands default to looking for a `Brewfile` in the current directory, so either `cd ~/.config` first or pass `--file=~/.config/Brewfile`.

**Install everything listed:**

```bash
brew bundle install --file=~/.config/Brewfile
```

**Check what's declared but not yet installed (or vice versa):**

```bash
brew bundle check --verbose --file=~/.config/Brewfile
```

**Capture the current machine state back into the Brewfile** (useful after installing something ad-hoc with `brew install` and realising you want to keep it):

```bash
brew bundle dump --force --file=~/.config/Brewfile
# Review the diff, then commit
```

**Uninstall anything NOT in the Brewfile** (dangerous — prunes your system to exactly what's declared):

```bash
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

## Health check

One-liner to verify everything is up:

```bash
for p in AeroSpace sketchybar borders karabiner_console_user_server; do
  pgrep -x "$p" >/dev/null && echo "✅ $p" || echo "❌ $p"
done
brew bundle check --verbose --file=~/.config/Brewfile
```
