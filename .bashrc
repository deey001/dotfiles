# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History settings
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000

# Window size check
shopt -s checkwinsize

# Lesspipe setup
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
esac

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# eza aliases (better ls)
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --color=auto'
    alias ll='eza -alF'
    alias la='eza -A'
    alias l='eza -CF'
fi

# bat alias (better cat)
DISTRIBUTION=$(distribution)
if [ "$DISTRIBUTION" = "redhat" ] || [ "$DISTRIBUTION" = "arch" ]; then
      alias cat='bat'
else
      alias cat='batcat'
fi
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Programmable completion
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# bash-preexec for predictive text hooks - TESTING
if [ -f ~/.bash-preexec/bash-preexec.sh ]; then
    source ~/.bash-preexec/bash-preexec.sh
fi

# Fuzzy history search with fzf
if [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
  source /usr/share/doc/fzf/examples/key-bindings.bash
fi

# Alias for fuzzy directory finder
alias ff='cd $(find . -type d | fzf)'

# hstr for better history search
alias hh=hstr

# zoxide initialization - TESTING (use 'z' command for smarter cd)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)" 2>/dev/null || true
fi

# Starship initialization
if [ -f /usr/local/bin/starship ]; then
    eval "$(starship init bash)"
fi

# Fastfetch system info on login
if command -v fastfetch >/dev/null 2>&1; then
    fastfetch
fi

# Auto-log SSH sessions (excludes passwords since they're not echoed)
# Temporarily disabled due to PTY issues
# if ([ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]) && [ -z "$SCRIPT" ]; then
#     LOGFILE="$HOME/ssh_logs/$(date +%Y%m%d_%H%M%S)_ssh.log"
#     mkdir -p "$HOME/ssh_logs"
#     script -q -a "$LOGFILE"
# fi

# ble.sh (Bash Line Editor) for predictive text and syntax highlighting
# Must be sourced at the end of .bashrc
# TESTING - likely the crash culprit
if [ -f ~/.local/share/blesh/ble.sh ]; then
    source ~/.local/share/blesh/ble.sh
fi
# Ctrl-R for history, Ctrl-T for files, Alt-C for zoxide cd
eval "$(fzf --bash)"