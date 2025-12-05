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
alias fd='df'

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

