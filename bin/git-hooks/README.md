# Dotfiles git hooks

These hooks are tracked in the repo but not auto-activated on clone. After a fresh clone, run once:

```sh
git -C ~/.config config core.hooksPath bin/git-hooks
```

That sets the clone's `core.hooksPath` so every hook in this directory fires.

## Hooks

### `pre-commit`
Blocks commits that silently shrink a tracked file by ≥30% (added 2026-05-11 after `aerospace.toml` got truncated 249 → 11 lines on a new laptop and broke every cmd-* keybind).

Bypass intentionally with `git commit --no-verify`.
