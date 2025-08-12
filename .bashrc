# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
# This checks if the shell is interactive; if not (e.g., script execution), skip the rest to avoid unnecessary setup.
case $- in
    *i*) ;;
      *) return;;
esac

# History settings
# Ignore duplicate commands and lines starting with space in history. Append to history file instead of overwriting. Set history size limits.
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000

# Window size check
# Automatically update LINES and COLUMNS after each command if window size changes.
shopt -s checkwinsize

# Globstar (disabled by default)
# If enabled, ** would match all files and subdirectories recursively (commented out to avoid unexpected behavior).
#shopt -s globstar

# Lesspipe setup
# Make 'less' handle non-text files better by preprocessing them.
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Chroot identification
# Set a prompt prefix if in a chroot environment.
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Color prompt detection
# Check if the terminal supports colors for the prompt.
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# Force color prompt (disabled by default)
# If enabled, force colors even if not detected (commented out).
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

# Set default prompt
# Define PS1 with colors if supported, including chroot prefix, user@host, and working directory.
if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# Set terminal title
# For xterm-like terminals, set the title to user@host:dir.
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# Enable color support of ls and handy aliases
# Enable color for ls and grep commands if dircolors is available.
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Colored GCC warnings and errors (disabled by default)
# Enable colored output for GCC warnings/errors (commented out).
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Additional ls aliases
# Shortcuts for common ls variations.
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Alert alias
# Notify after long-running commands complete.
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions
# Load custom aliases from .bash_aliases if it exists.
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Programmable completion
# Enable bash-completion for enhanced tab autocomplete (e.g., for commands, files, Git).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Fuzzy history search with fzf (Ctrl-R)
# Source fzf keybindings if available for interactive history search.
if [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
  source /usr/share/doc/fzf/examples/key-bindings.bash
fi

# Alias for fuzzy directory finder
# cd into a directory chosen via fzf from a recursive search.
alias ff='cd $(find . -type d | fzf)'

# Modern Prompt for Bash: user@host dir git-branch/status (with Nerd Font icons)
# Define functions for Git branch and dirty status, then set PS1 to show user@host, dir, Git info with colors and icons.
function parse_git_dirty {
  [[ $(git status --porcelain 2> /dev/null) ]] && echo "*"
}
function parse_git_branch {
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/  (\1$(parse_git_dirty))/"
}
export PS1="\[\033[32m\]\u@\h \w\[\033[33m\]\$(parse_git_branch)\[\033[00m\] ❯ "