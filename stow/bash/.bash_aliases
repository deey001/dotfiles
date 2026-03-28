# ==============================================================================
# .bash_aliases — Custom Aliases
# ==============================================================================
# Sourced by .bashrc. ls/grep/cat/eza/bat aliases are in .bashrc (single source
# of truth). This file contains all other aliases.
# ==============================================================================

# ── Navigation ─────────────────────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias -- -='cd -'
alias dc='cd'

# ── Editors ────────────────────────────────────────────────────────────────────
alias vi='nvim'
alias vim='nvim'
alias v='nvim'

# ── Quick shell actions ─────────────────────────────────────────────────────────
alias c='clear'
alias q='exit'
alias less='less -R'
alias mkdir='mkdir -p'
alias da='date "+%Y-%m-%d %A %T %Z"'

# ── Git shortcuts ───────────────────────────────────────────────────────────────
alias gti='git'
alias ga='git add'
alias gst='git status'
alias gd='git diff'
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gco='git checkout'
alias glog='git log --oneline --graph --color --all --decorate'

# ── Colorized diff ─────────────────────────────────────────────────────────────
if command -v colordiff >/dev/null 2>&1; then
    alias diff='colordiff'
fi

# ── Modern tool aliases (safe names that don't shadow system commands) ──────────

# fd (faster find — different CLI, don't shadow 'find')
if command -v fd >/dev/null 2>&1; then
    alias fdf='fd'
    alias oldfind='/usr/bin/find'
fi

# dust (better du)
if command -v dust >/dev/null 2>&1; then
    alias duu='dust'
    alias olddu='/usr/bin/du'
fi

# duf (colorful df)
if command -v duf >/dev/null 2>&1; then
    alias dff='duf'
    alias olddf='/bin/df'
fi

# procs (modern ps — different flags, don't shadow 'ps')
if command -v procs >/dev/null 2>&1; then
    alias prc='procs'
fi

# btop (beautiful resource monitor)
if command -v btop >/dev/null 2>&1; then
    alias top='btop'
    alias oldtop='/usr/bin/top'
fi

# ── Search shortcuts ────────────────────────────────────────────────────────────
alias h="history | grep "
alias p="ps aux | grep "
alias f="find . | grep "

# ── System information ──────────────────────────────────────────────────────────
alias openports='netstat -nape --inet'
alias topcpu="/bin/ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10"

# ── Archive shortcuts ───────────────────────────────────────────────────────────
alias mktar='tar -cvf'
alias mkbz2='tar -cvjf'
alias mkgz='tar -cvzf'
alias untar='tar -xvf'
alias unbz2='tar -xvjf'
alias ungz='tar -xvzf'

# ── Disk & mounts ───────────────────────────────────────────────────────────────
alias diskspace="du -S | sort -n -r | more"
alias folders='du -h --max-depth=1'
alias mountedinfo='df -hT'

# ── HTTP with xh ───────────────────────────────────────────────────────────────
if command -v xh >/dev/null 2>&1; then
    alias http='xh'
fi

