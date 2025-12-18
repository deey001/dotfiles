# .bash_aliases: Custom aliases for common commands
# This file contains shortcuts to make frequent commands shorter and more efficient.

# List all files in long format with classification
alias ll='ls -alF'

# List all files except . and ..
alias la='ls -A'

# List files with classification
alias l='ls -CF'

# Colorized grep output
alias grep='grep --color=auto'

# Colorized fgrep output
alias fgrep='fgrep --color=auto'

# Colorized egrep output
alias egrep='egrep --color=auto'
alias gti='git'
#alias tmux='tmux -2'
alias less='less -R'
alias diff='colordiff'
alias dc='cd'
alias glog='git log --oneline --graph --color --all --decorate'
alias vi='nvim'
alias c='clear'
alias q='exit'
alias v='nvim'
alias vim='nvim'

# ==============================================================================
# Modern Tool Aliases (with fallbacks to original commands)
# ==============================================================================
# These override standard commands with modern alternatives if available

# cat -> bat/batcat (syntax highlighting)
if command -v bat >/dev/null 2>&1; then
    alias cat='bat'
    alias oldcat='/bin/cat'
elif command -v batcat >/dev/null 2>&1; then
    alias cat='batcat'
    alias oldcat='/bin/cat'
fi

# ls -> eza (icons and git status) - already configured in .bashrc

# cd -> zoxide (smarter navigation) - already configured in .bashrc

# grep -> ripgrep would be 'rg', but we keep grep with colors

# find -> fd (faster find)
# Note: fd-find package installs as 'fdfind', symlink created in ~/.local/bin/fd
if command -v fd >/dev/null 2>&1; then
    alias find='fd'
    alias oldfind='/usr/bin/find'
fi

# du -> dust (better disk usage)
if command -v dust >/dev/null 2>&1; then
    alias du='dust'
    alias olddu='/usr/bin/du'
fi

# df -> duf (colorful df)
if command -v duf >/dev/null 2>&1; then
    alias df='duf'
    alias olddf='/bin/df'
fi

# ps -> procs (modern process viewer)
if command -v procs >/dev/null 2>&1; then
    alias ps='procs'
    alias oldps='/bin/ps'
fi

# top -> btop (beautiful resource monitor)
if command -v btop >/dev/null 2>&1; then
    alias top='btop'
    alias oldtop='/usr/bin/top'
fi

# Quick directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Search aliases
alias h="history | grep "
alias p="ps aux | grep "
alias f="find . | grep "

# System information
alias openports='netstat -nape --inet'
alias topcpu="/bin/ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10"

# Archive aliases
alias mktar='tar -cvf'
alias mkbz2='tar -cvjf'
alias mkgz='tar -cvzf'
alias untar='tar -xvf'
alias unbz2='tar -xvjf'
alias ungz='tar -xvzf'

# Disk space
alias diskspace="du -S | sort -n -r | more"
alias folders='du -h --max-depth=1'
alias mountedinfo='df -hT'

# Date alias
alias da='date "+%Y-%m-%d %A %T %Z"'

