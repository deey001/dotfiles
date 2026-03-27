# ==============================================================================
# .bashrc - Bash Configuration File
# ==============================================================================
# Executed by bash(1) for non-login shells.
# This file sets up the shell environment, history, aliases, and prompts.
# ==============================================================================

# ------------------------------------------------------------------------------
# Interactive Check
# ------------------------------------------------------------------------------
# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# ------------------------------------------------------------------------------
# History Settings
# ------------------------------------------------------------------------------
# erasedups: Remove duplicates if they are the same as the previous command
# ignoredups: Do not record an event that is the same as the previous one
# ignorespace: Do not record an event starting with a space
HISTCONTROL=erasedups:ignoredups:ignorespace

# Append to the history file, don't overwrite it
shopt -s histappend

# Large history size for better recall (via fzf/hstr)
HISTSIZE=10000
HISTFILESIZE=20000

# Save history immediately after each command (prevents loss on crash/multiple terms)
PROMPT_COMMAND='history -a'

# ------------------------------------------------------------------------------
# Environment Detection
# ------------------------------------------------------------------------------
# Detect special environments and set flags for conditional behavior

# Detect SSH session
# USAGE: Check if you're connected via SSH to adjust prompt/behavior
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    export IS_SSH=1
else
    export IS_SSH=0
fi

# Detect WSL (Windows Subsystem for Linux)
# USAGE: Enable Windows-specific integrations when running in WSL
if grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null; then
    export IS_WSL=1
else
    export IS_WSL=0
fi

# Detect Docker container
# USAGE: Adjust resource-intensive operations in containers
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    export IS_DOCKER=1
else
    export IS_DOCKER=0
fi

# Detect if running in Tmux
# USAGE: Prevent nested tmux or adjust terminal behavior
if [ -n "$TMUX" ]; then
    export IS_TMUX=1
else
    export IS_TMUX=0
fi

# ------------------------------------------------------------------------------
# Shell Options
# ------------------------------------------------------------------------------
# Update window size after each command (useful for resizing)
shopt -s checkwinsize

# Disable XON/XOFF flow control (allows using Ctrl-S/Ctrl-Q)
stty -ixon 2>/dev/null

# Bash completion improvements
# Ignore case when completing
bind "set completion-ignore-case on" 2>/dev/null
# Show all options immediately if ambiguous
bind "set show-all-if-ambiguous on" 2>/dev/null

# ------------------------------------------------------------------------------
# Utilities
# ------------------------------------------------------------------------------
# Lesspipe: Use lesspipe to view file contents if available
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Debian chroot support
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# ------------------------------------------------------------------------------
# Color Support
# ------------------------------------------------------------------------------
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# Enable color support for ls, grep, etc.
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# ------------------------------------------------------------------------------
# Aliases
# ------------------------------------------------------------------------------
# Standard ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# eza aliases (Modern replacement for ls)
# Only active if eza is installed
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --color=auto --icons'
    alias ll='eza -alF --icons'
    alias la='eza -A --icons'
    alias l='eza -CF --icons'
fi

# bat alias (Better cat with syntax highlighting)
# Detects 'bat' or 'batcat' (Ubuntu/Debian)
if command -v bat > /dev/null 2>&1; then
    alias cat='bat'
elif command -v batcat > /dev/null 2>&1; then
    alias cat='batcat'
fi

# Fast directory navigation (zoxide)
if command -v zoxide > /dev/null 2>&1; then
    eval "$(zoxide init bash)" 2>/dev/null
    alias cd='z'
fi

# Alert alias for long running commands
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# ------------------------------------------------------------------------------
# Imports
# ------------------------------------------------------------------------------
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

if [ -f ~/.bash_functions ]; then
    . ~/.bash_functions
fi

# Programmable completion
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# ------------------------------------------------------------------------------
# Helper Tools & Environment
# ------------------------------------------------------------------------------

# Detect if we are in an air-gapped environment (simple ping check)
# Only run this check once per session to avoid delay
if [ -z "$IS_ONLINE" ]; then
    if ping -c 1 8.8.8.8 &> /dev/null; then
        export IS_ONLINE=1
    else
        export IS_ONLINE=0
    fi
fi

# fzf (Fuzzy Finder) Configuration
if command -v fzf > /dev/null 2>&1; then
    # Load key bindings and completion
    [ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && source /usr/share/doc/fzf/examples/key-bindings.bash
    [ -f /usr/share/doc/fzf/examples/completion.bash ] && source /usr/share/doc/fzf/examples/completion.bash
    
    # Custom fzf alias for directory movement
    alias ff='cd $(find . -type d | fzf)'
fi

# hstr (History Search)
if command -v hstr > /dev/null 2>&1; then
    alias hh=hstr
    # Bind Ctrl-r to hstr if desired (commented out by default to prefer fzf)
    # bind '"\C-r": "\C-a hstr -- \C-j"'
fi

# ------------------------------------------------------------------------------
# Starship Prompt (Must be initialized last)
# ------------------------------------------------------------------------------
if command -v starship > /dev/null 2>&1; then
    eval "$(starship init bash)"
fi

# ------------------------------------------------------------------------------
# ble.sh (Bash Line Editor)
# ------------------------------------------------------------------------------
# Provides syntax highlighting and predictive text.
# Must be sourced AFTER starship prompt.
if [ -f ~/.local/share/blesh/ble.sh ]; then
    source ~/.local/share/blesh/ble.sh
    
    # Apply custom config (fixes paste issues)
    if [ -f ~/.blerc ]; then
        source ~/.blerc
    fi
fi

# ------------------------------------------------------------------------------
# Local/Private Configuration
# ------------------------------------------------------------------------------
# Source machine-specific or private settings (API keys, custom paths, etc.)
# This file is NOT tracked in git and should be created manually if needed
#
# USAGE:
#   Create ~/.bash_local with your private settings:
#   echo 'export GITHUB_TOKEN="ghp_your_token_here"' >> ~/.bash_local
#   echo 'export CUSTOM_PATH="/opt/mytools"' >> ~/.bash_local
#
if [ -f ~/.bash_local ]; then
    source ~/.bash_local
fi

# ------------------------------------------------------------------------------
# Login Summary
# ------------------------------------------------------------------------------
# Show system info on login (only for login shells, and not if inside Tmux)
if command -v fastfetch > /dev/null 2>&1; then
    # Don't run if in tmux (too noisy for every pane)
    if shopt -q login_shell && [ -z "$TMUX" ]; then
        fastfetch
    fi
fi