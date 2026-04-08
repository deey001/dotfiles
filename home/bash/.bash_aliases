# ==============================================================================
# .bash_aliases — Aliases shared by Bash and Zsh
# ==============================================================================
# Sourced by .bashrc and .zshrc. All aliases live here so both shells
# get identical behavior.
# Convention: modern tools use `command -v` guards; originals preserved
# as `old*` where the tool is a drop-in replacement.

# ── ls / directory listing ────────────────────────────────────────────────────
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --color=auto --icons'
    alias ll='eza -alF --icons --git'
    alias la='eza -A --icons'
    alias l='eza -CF --icons'
    alias tree='eza --tree --icons'
else
    alias ls='ls --color=auto'
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'
fi

# ── cat / bat ─────────────────────────────────────────────────────────────────
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
    alias oldcat='/bin/cat'
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    export MANROFFOPT="-c"
elif command -v batcat >/dev/null 2>&1; then
    alias cat='batcat --paging=never'
    alias oldcat='/bin/cat'
    export MANPAGER="sh -c 'col -bx | batcat -l man -p'"
    export MANROFFOPT="-c"
fi

# ── grep (always colorize) ────────────────────────────────────────────────────
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# ── Navigation ────────────────────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias -- -='cd -'
alias dc='cd'        # typo corrector

# ── Editors ───────────────────────────────────────────────────────────────────
alias vi='nvim'
alias vim='nvim'
alias v='nvim'

# ── Shell quality-of-life ─────────────────────────────────────────────────────
alias c='clear'
alias q='exit'
alias less='less -R'
alias mkdir='mkdir -p'
alias da='date "+%Y-%m-%d %A %T %Z"'

# ── Git shortcuts ─────────────────────────────────────────────────────────────
alias gti='git'
alias ga='git add'
alias gst='git status'
alias gd='git diff'
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gco='git checkout'
alias glog='git log --oneline --graph --color --all --decorate'

# ── Modern tool replacements ──────────────────────────────────────────────────
command -v fd      >/dev/null 2>&1 && alias fdf='fd'
command -v dust    >/dev/null 2>&1 && { alias duu='dust'; alias olddu='/usr/bin/du'; }
command -v duf     >/dev/null 2>&1 && { alias dff='duf';  alias olddf='/bin/df'; }
command -v procs   >/dev/null 2>&1 && alias prc='procs'
command -v btop    >/dev/null 2>&1 && { alias top='btop'; alias oldtop='/usr/bin/top'; }
command -v xh      >/dev/null 2>&1 && alias http='xh'
command -v colordiff >/dev/null 2>&1 && alias diff='colordiff'

# ── Quick search ──────────────────────────────────────────────────────────────
alias h='history | grep '
alias p='ps aux | grep '
alias f='find . | grep '

# ── System info ───────────────────────────────────────────────────────────────
alias openports='netstat -nape --inet'
alias topcpu='/bin/ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10'

# ── Archives ──────────────────────────────────────────────────────────────────
alias mktar='tar -cvf'
alias mkbz2='tar -cvjf'
alias mkgz='tar -cvzf'
alias untar='tar -xvf'
alias unbz2='tar -xvjf'
alias ungz='tar -xvzf'

# ── Disk ──────────────────────────────────────────────────────────────────────
alias diskspace='du -S | sort -n -r | more'
alias folders='du -h --max-depth=1'
alias mountedinfo='df -hT'
