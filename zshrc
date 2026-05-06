autoload -U +X compinit && compinit
autoload -U +X bashcompinit && bashcompinit

eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(starship init zsh)"
export PATH="$HOME/.local/bin:$PATH"

# The next line updates PATH for egcli command.
if [ -f "$HOME/Library/Group Containers/FELUD555VC.group.com.egnyte.DesktopApp/CLI/egcli.inc" ]; then . "$HOME/Library/Group Containers/FELUD555VC.group.com.egnyte.DesktopApp/CLI/egcli.inc"; fi

# ---- Zsh plugins (installed via Homebrew + git clones) ----
# Order matters: zsh-autocomplete first, then syntax-highlighting, then
# autosuggestions last. Each line is guarded with -f so a missing install
# skips silently instead of erroring.

# zsh-autocomplete — dropdown of suggestions as you type (arrows + Enter)
# Install: git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git ~/.zsh/plugins/zsh-autocomplete
[ -f ~/.zsh/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh ] && \
  source ~/.zsh/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh

# Configure autocomplete behavior (no-op if plugin not loaded)
zstyle ':autocomplete:*' min-input 1                      # start suggesting after 1 character
zstyle ':autocomplete:*' delay 0.0                        # instant suggestions
zstyle ':autocomplete:*' list-lines 10                    # max dropdown size
zstyle ':autocomplete:history-search:*' list-lines 10
zstyle ':autocomplete:tab:*' insert-unambiguous yes       # tab only fills in unique part
zstyle ':autocomplete:tab:*' widget-style menu-select     # menu on tab
zstyle ':autocomplete:*' fzf-completion yes               # use fzf for long completion lists

# Make arrow keys go through dropdown entries instead of history at the prompt
bindkey '\e[A' up-line-or-search
bindkey '\e[B' down-line-or-search

# zsh-syntax-highlighting — colorize commands as you type
[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# zsh-autosuggestions — gray inline history suggestion, accept with →
[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh


# ---- FZF -----

# Set up fzf key bindings and fuzzy completion
eval "$(fzf --zsh)"

# -- Use fd instead of fzf --

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

# FZF-GIT — optional; clone with:
#   git clone https://github.com/junegunn/fzf-git.sh ~/fzf-git.sh
[ -f ~/fzf-git.sh/fzf-git.sh ] && source ~/fzf-git.sh/fzf-git.sh

# --- setup fzf theme ---
fg="#CBE0F0"
bg="#011628"
bg_highlight="#143652"
purple="#B388FF"
blue="#06BCE4"
cyan="#2CF9ED"

export FZF_DEFAULT_OPTS="--color=fg:${fg},bg:${bg},hl:${purple},fg+:${fg},bg+:${bg_highlight},hl+:${purple},info:${blue},prompt:${cyan},pointer:${cyan},marker:${cyan},spinner:${cyan},header:${cyan}"

# ----- Bat (better cat) -----

export BAT_THEME=tokyonight_night

show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo ${}'"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}

# ---- Eza (better ls) -----

alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"

# thefuck alias
eval $(thefuck --alias)
eval $(thefuck --alias fk)

# ---- Zoxide (better cd) ----
eval "$(zoxide init zsh)"

alias cd="z"
alias y="yazi"

# 1Password SSH Keys
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# ---- Ghostty helpers (drive the app via AppleScript) ----
# Ghostty doesn't expose a full CLI, so these poke at its menu bar instead.

# Close the active Ghostty tab from the terminal.
ghostty-close-tab() {
  osascript -e 'tell application "System Events" to tell process "Ghostty" to keystroke "w" using {command down}'
}

# Merge every open Ghostty window into a single tabbed window.
# After this runs, AeroSpace sees one window with N tabs instead of N tiles.
ghostty-merge() {
  osascript <<'EOF'
tell application "Ghostty" to activate
tell application "System Events"
  tell process "Ghostty"
    try
      click menu item "Merge All Windows" of menu "Window" of menu bar 1
    on error
      -- Fallback to the keystroke if the menu item is named differently
      keystroke "m" using {command down, shift down, control down}
    end try
  end tell
end tell
EOF
}

# Cycle to the next tab without opening a new one.
ghostty-next-tab() {
  osascript -e 'tell application "System Events" to tell process "Ghostty" to keystroke "]" using {command down, shift down}'
}

ghostty-prev-tab() {
  osascript -e 'tell application "System Events" to tell process "Ghostty" to keystroke "[" using {command down, shift down}'
}

alias gt-close='ghostty-close-tab'
alias gt-merge='ghostty-merge'
alias gt-next='ghostty-next-tab'
alias gt-prev='ghostty-prev-tab'

# ---- Auto-attach to tmux ----
# Disabled: Ghostty's session picker (ghostty-session-picker) handles tmux
# session creation/attachment on window open. This block was conflicting with it.
# To restore: uncomment the lines below.
# if command -v tmux >/dev/null 2>&1 && [ -z "$TMUX" ] && [ -z "$NO_TMUX" ] && [ -n "$PS1" ]; then
#   tmux attach -t main 2>/dev/null || tmux new -s main
# fi

# ---- Project paths ----
# Environment variables pointing at the repos. Use these from any command:
#   cd $TWIN
#   wind $FLOWEN
#   ls $TWIN/src
# Exported so tools like `make`, `git`, and sub-shells can see them too.
export TWIN="$HOME/Flowen/twin-andie"
export FLOWEN="$HOME/Flowen/flowen-os"

# ---- Project session helpers ----
# Each function cd's into a repo and sets the Ghostty tab/pane title.

# Set a terminal title that sticks across prompts (overrides auto-title from
# shell integration). Call once; re-run if your title gets clobbered.
set_term_title() {
  local title="$1"
  # OSC 0 sets both window and tab/icon title
  printf '\e]0;%s\a' "$title"
  # Stop Ghostty's shell integration from updating the title back to $PWD
  export DISABLE_AUTO_TITLE="true"
}

twin-andie() {
  cd "$TWIN" || return
  set_term_title "Andie's TWIN"
}

flowen-os() {
  cd "$FLOWEN" || return
  set_term_title "flowen-os"
}

# Short aliases
alias twin='twin-andie'
alias flowen='flowen-os'
alias wind='windsurf'     # Open files/directories in Windsurf: `wind .` or `wind path/to/file`

# Use Windsurf as the default editor for commands like `git commit`, `crontab -e`, etc.
export EDITOR="windsurf --wait"
export VISUAL="windsurf --wait"

# Named directory hashes — let you reference paths as ~name anywhere.
#   cd ~twin         # jumps to the twin-andie repo
#   ls ~flowen/src   # tab-completes into the repo
#   vim ~flowen      # works with any command
hash -d twin="$TWIN"
hash -d flowen="$FLOWEN"
hash -d dots=~/.config

# Quick-edit shortcuts for this dotfiles repo
alias zshconfig='$EDITOR ~/.config/zshrc'
alias aeroconfig='$EDITOR ~/.config/aerospace/aerospace.toml'
alias barconfig='$EDITOR ~/.config/sketchybar/sketchybarrc'
alias ghosttyconfig='$EDITOR ~/.config/ghostty/config'
alias tmuxconfig='$EDITOR ~/.config/tmux/tmux.conf'

# ---- Git aliases (cherry-picked from oh-my-zsh + dev setup) ----
alias g='git'
alias gs='git status -sb'
alias gst='git status'
alias ga='git add'
alias gaa='git add --all'
alias gan='git add --all -N'
alias gco='git checkout'
alias gb='git branch'
alias gcm='git commit -m'
alias gci='git commit -m'
alias gca='git commit --amend --no-edit'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gl='git pull'
alias glog='git log --oneline --graph --decorate'
alias gloga='git log --oneline --graph --decorate --all'
alias gd='git diff'
alias gds='git diff --staged'
alias gfa='git fetch --all --prune'
alias gdmb='git branch --merged | grep -v "\*" | xargs -n 1 git branch -d'
alias grb='git rebase'
alias grbi='git rebase -i'
alias gsh='git stash'
alias gshp='git stash pop'

# ---- Shell behavior tuning ----
setopt no_beep
setopt auto_cd                    # type a dir name alone to cd into it
setopt hist_ignore_all_dups       # no duplicate entries in history
setopt hist_ignore_space          # skip history if command starts with a space
setopt hist_expire_dups_first     # when trimming, lose oldest duplicates first
setopt inc_append_history         # append to history file as commands run
setopt share_history              # other terminals see new history immediately
setopt hist_verify                # don't auto-execute history expansions
setopt hist_reduce_blanks         # collapse extra whitespace in history

HISTFILE=$HOME/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

# ---- Completion improvements ----
# Case-insensitive + partial-word + substring matching
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Interactive menu: press Tab to open, arrow keys to navigate, Enter to select.
# Also let left/right arrows move between entries in multi-column menus.
zstyle ':completion:*' menu select
zmodload -i zsh/complist
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char

# Color completion entries the same way ls does
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Group completions by type (commands, files, options) with headers
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}%B%d%b%f'
zstyle ':completion:*:warnings' format '%F{red}no matches for: %d%f'

# Complete from the middle of a word; show menu on the first Tab, not the second
setopt complete_in_word
setopt always_to_end
setopt auto_menu
unsetopt menu_complete

# ---- Useful keybindings ----
bindkey "^R" history-incremental-search-backward  # Ctrl-R fuzzy history
autoload edit-command-line
zle -N edit-command-line
bindkey '^F' edit-command-line                    # Ctrl-F opens current command in $EDITOR
bindkey '^[b' backward-word                       # Alt-b
bindkey '^[f' forward-word                        # Alt-f
