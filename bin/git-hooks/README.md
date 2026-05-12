# Dotfiles git hooks

These hooks are tracked in the repo but not auto-activated on clone. After a fresh clone, run once:

```sh
git -C ~/.config config core.hooksPath bin/git-hooks
```

That sets the clone's `core.hooksPath` so every hook in this directory fires.

## Hooks

### `pre-commit`
Two gates, each independently bypassable:

1. **Shrink guard** — blocks commits that silently shrink a tracked file by ≥30% (added 2026-05-11 after `aerospace.toml` got truncated 249 → 11 lines on a new laptop and broke every cmd-* keybind).

2. **Fast test suite** — runs `tests/run.sh static invariants` (~4s) on every commit. Fails the commit if any check fails. E2E layer is NOT in pre-commit (daemons may legitimately be down at commit time — run `dotfiles-doctor` for the full suite).

Bypass either gate with `git commit --no-verify`.

---

## Companion: aerospace.toml runtime tripwire

The pre-commit hook only catches truncations that get committed. `aerospace.toml` has also been wiped at runtime (2026-05-12 incident) without ever being committed — pre-commit was silent. The runtime watcher closes that gap.

### What it is
- Script: [`bin/aerospace-toml-tripwire`](../aerospace-toml-tripwire) — fswatch on `~/.config/aerospace/aerospace.toml`. Every write event triggers a forensic record (timestamp, line count, lsof, ps snapshot of likely writers, git diff vs HEAD, recent edits in `~/.config`).
- LaunchAgent: `~/Library/LaunchAgents/com.andie.aerospace-toml-tripwire.plist` — auto-starts on login, KeepAlive.
- Log: `~/.local/state/aerospace-toml-writes.log` (rotates at 1 MB → `.1`).

### Install on a fresh machine
```sh
brew install fswatch  # also in Brewfile
launchctl bootstrap "gui/$(id -u)" ~/Library/LaunchAgents/com.andie.aerospace-toml-tripwire.plist
```

### After a suspected wipeout
```sh
# What touched the file recently?
tail -200 ~/.local/state/aerospace-toml-writes.log

# Look for ALARM lines — line count < 100 = likely truncation
grep -B 2 -A 30 ALARM ~/.local/state/aerospace-toml-writes.log
```

### Bypass / disable temporarily
```sh
launchctl bootout "gui/$(id -u)" ~/Library/LaunchAgents/com.andie.aerospace-toml-tripwire.plist
```
