# ==============================================================================
# .bash_aliases — Custom Aliases
# ==============================================================================
# Sourced by .bashrc. ls/grep/cat/eza/bat aliases are in .bashrc (single source
# of truth). This file contains all other aliases.
#
# Convention: Modern tool replacements use `command -v` guards so the alias is
# only defined when the tool is installed. Original commands are preserved via
# `old*` prefix aliases (e.g., `oldtop`, `oldfind`) for quick fallback.
# ==============================================================================

# ── Navigation ─────────────────────────────────────────────────────────────────
# Shorthand cd-up aliases — number of dots matches directory levels to ascend.
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias -- -='cd -'                     # Return to previous directory (-- stops option parsing)
alias dc='cd'                         # Typo corrector — dc is a common mis-type of cd

# ── Editors ────────────────────────────────────────────────────────────────────
# Point all legacy vi/vim invocations to Neovim so muscle memory still works.
alias vi='nvim'
alias vim='nvim'
alias v='nvim'                        # Single-char shortcut for quick edits

# ── Quick shell actions ─────────────────────────────────────────────────────────
alias c='clear'
alias q='exit'
alias less='less -R'                  # -R preserves ANSI color escape sequences
alias mkdir='mkdir -p'                # -p creates intermediate dirs & never errors on existing
alias da='date "+%Y-%m-%d %A %T %Z"' # Human-friendly timestamp: 2024-06-15 Saturday 14:30:00 UTC

# ── Git shortcuts ───────────────────────────────────────────────────────────────
# Minimal aliases for the most common git operations. Keep these short — lazygit
# covers anything more complex.
alias gti='git'                       # Typo corrector
alias ga='git add'
alias gst='git status'
alias gd='git diff'
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gco='git checkout'
alias glog='git log --oneline --graph --color --all --decorate'

# ── Colorized diff ─────────────────────────────────────────────────────────────
# Wraps diff with color output when colordiff is available.
if command -v colordiff >/dev/null 2>&1; then
    alias diff='colordiff'
fi

# ── Modern tool aliases (safe names that don't shadow system commands) ──────────
# Pattern: each block checks for the tool with `command -v`, creates a
# *non-conflicting* alias, and preserves the original via an `old*` alias.
# This avoids breaking scripts that expect standard flags on the original tool.

# fd (faster find — different CLI, don't shadow 'find')
if command -v fd >/dev/null 2>&1; then
    alias fdf='fd'                    # "fd find" — avoids colliding with /usr/bin/fd on some distros
    alias oldfind='/usr/bin/find'
fi

# dust (better du)
if command -v dust >/dev/null 2>&1; then
    alias duu='dust'                  # "du upgraded" — visual tree of disk usage
    alias olddu='/usr/bin/du'
fi

# duf (colorful df)
if command -v duf >/dev/null 2>&1; then
    alias dff='duf'                   # "df fancy" — color table of mounted filesystems
    alias olddf='/bin/df'
fi

# procs (modern ps — different flags, don't shadow 'ps')
if command -v procs >/dev/null 2>&1; then
    alias prc='procs'                 # Color process list with tree view
fi

# btop (beautiful resource monitor)
if command -v btop >/dev/null 2>&1; then
    alias top='btop'                  # Replaces top entirely — btop is a superset
    alias oldtop='/usr/bin/top'
fi

# ── Search shortcuts ────────────────────────────────────────────────────────────
# Quick one-liners for filtering — pipe to grep for instant results.
alias h="history | grep "             # Search command history
alias p="ps aux | grep "             # Find running processes by name
alias f="find . | grep "             # Find files in CWD by name fragment

# ── System information ──────────────────────────────────────────────────────────
alias openports='netstat -nape --inet'   # Show all open IPv4 network connections
alias topcpu="/bin/ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10"  # Top 10 CPU hogs

# ── Archive shortcuts ───────────────────────────────────────────────────────────
# Create archives — verbose output so you see what's being packed.
alias mktar='tar -cvf'               # Plain tarball (no compression)
alias mkbz2='tar -cvjf'              # bzip2 compressed
alias mkgz='tar -cvzf'               # gzip compressed
# Extract archives — matches the create aliases above.
alias untar='tar -xvf'
alias unbz2='tar -xvjf'
alias ungz='tar -xvzf'

# ── Disk & mounts ───────────────────────────────────────────────────────────────
alias diskspace="du -S | sort -n -r | more"  # Largest directories first (separate sizes)
alias folders='du -h --max-depth=1'           # Human-readable size of each child dir
alias mountedinfo='df -hT'                    # Show filesystem types alongside usage

# ── HTTP with xh ───────────────────────────────────────────────────────────────
# xh is a modern httpie-compatible HTTP client written in Rust.
if command -v xh >/dev/null 2>&1; then
    alias http='xh'
fi

# ── Suggested additions (uncomment to enable) ─────────────────────────────────
# alias reload='source ~/.bashrc'      # Reload shell config without restarting
# alias path='echo -e ${PATH//:/\\n}'  # Print PATH entries one per line
# alias weather='curl wttr.in'         # Quick weather forecast in terminal
# alias myip='curl -s ifconfig.me'     # Show public IP address
# alias ports='ss -tulnp'             # Modern replacement for netstat on Linux
# alias lg='lazygit'                   # TUI git client (already installed)
# alias ld='lazydocker'               # TUI docker management

