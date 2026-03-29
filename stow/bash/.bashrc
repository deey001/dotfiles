# ==============================================================================
# .bashrc — Bash Configuration
# ==============================================================================
# Executed by bash(1) for interactive shells.
# Load order: .bash_profile → .bashrc → .bash_exports → .bash_aliases
#             → .bash_functions → .bash_wrappers → .bash_local
# ==============================================================================

# ── 1. Interactive-only guard ──────────────────────────────────────────────────
case $- in *i*) ;; *) return ;; esac

# ── 2. History ─────────────────────────────────────────────────────────────────
HISTCONTROL=ignoredups:ignorespace
HISTSIZE=50000
HISTFILESIZE=100000
HISTIGNORE="ls:ll:la:l:cd:pwd:exit:clear:history:bg:fg:jobs:c:q:vi:vim"
HISTTIMEFORMAT="%F %T "
shopt -s histappend    # append to history; never overwrite
shopt -s cmdhist       # save multiline commands as one history entry
shopt -s lithist       # preserve newlines (not semicolons) in multiline history
# Append pattern: preserves PROMPT_COMMAND already set by system or other tools
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# ── 3. Environment detection ──────────────────────────────────────────────────
[[ -n "${SSH_CLIENT:-}${SSH_TTY:-}" ]] && export IS_SSH=1 || export IS_SSH=0
grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null && export IS_WSL=1 || export IS_WSL=0
_detect_container() {
    [[ -f /.dockerenv ]] && return 0
    [[ -f /run/.containerenv ]] && return 0
    grep -qE 'docker|lxc|kubepods' /proc/1/cgroup 2>/dev/null && return 0
    command -v systemd-detect-virt >/dev/null 2>&1 \
        && systemd-detect-virt -q --container 2>/dev/null && return 0
    return 1
}
_detect_container && export IS_DOCKER=1 || export IS_DOCKER=0
unset -f _detect_container
[[ -n "${TMUX:-}" ]] && export IS_TMUX=1 || export IS_TMUX=0

# ── 4. Connectivity check (file-cached, one ping per 5 minutes) ───────────────
_online_cache="${HOME}/.cache/is_online"
mkdir -p "${HOME}/.cache"
if [[ ! -f "$_online_cache" ]] || \
   [[ -z "$(find "$_online_cache" -mmin -5 2>/dev/null)" ]]; then
    ping -c 1 -W 1 8.8.8.8 &>/dev/null \
        && echo 1 > "$_online_cache" \
        || echo 0 > "$_online_cache"
fi
export IS_ONLINE=$(< "$_online_cache")
unset _online_cache

# ── 5. Shell options ──────────────────────────────────────────────────────────
shopt -s checkwinsize          # keep LINES/COLUMNS accurate on resize
shopt -s globstar              # **/*.sh recursive glob (like zsh)
shopt -s extglob               # !(*.txt) @(a|b) +(pat) extended patterns
shopt -s nullglob              # unmatched glob → empty (not literal string)
shopt -s cdspell               # auto-correct minor typos in cd target
shopt -s dirspell              # typo correction in tab-completed directory names
shopt -s autocd                # bare directory path → cd into it (like zsh autocd)
shopt -s no_empty_cmd_completion  # don't complete on an empty line (slow)
shopt -s checkhash             # verify hashed command paths before using them
stty -ixon 2>/dev/null         # enable Ctrl-S/Ctrl-Q for fzf history search

# ── 6. Readline bindings ──────────────────────────────────────────────────────
bind "set completion-ignore-case on"       2>/dev/null
bind "set show-all-if-ambiguous on"        2>/dev/null
bind "set menu-complete-display-prefix on" 2>/dev/null
bind "set colored-stats on"                2>/dev/null
bind "set colored-completion-prefix on"    2>/dev/null
bind "TAB:menu-complete"                   2>/dev/null
bind '"\e[Z":menu-complete-backward'       2>/dev/null

# ── 7. Terminal utilities ─────────────────────────────────────────────────────
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# ── 8. Core aliases ───────────────────────────────────────────────────────────
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
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
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
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# ── 9. Modular config files ──────────────────────────────────────────────────
[[ -f ~/.bash_exports   ]] && source ~/.bash_exports
[[ -f ~/.bash_aliases   ]] && source ~/.bash_aliases
[[ -f ~/.bash_functions ]] && source ~/.bash_functions
[[ -f ~/.bash_wrappers  ]] && source ~/.bash_wrappers

# ── 10. System bash-completion ────────────────────────────────────────────────
if ! shopt -oq posix; then
    if [[ -f /usr/share/bash-completion/bash_completion ]]; then
        source /usr/share/bash-completion/bash_completion
    elif [[ -f /etc/bash_completion ]]; then
        source /etc/bash_completion
    fi
fi

# ── 11. Carapace ──────────────────────────────────────────────────────────────
if command -v carapace >/dev/null 2>&1; then
    unset CARAPACE_BRIDGES
    complete -r tmux git docker kubectl helm 2>/dev/null
    _cc="${HOME}/.cache/carapace_init.bash"
    if [[ ! -f "$_cc" ]] || [[ "$(command -v carapace)" -nt "$_cc" ]]; then
        carapace _carapace bash > "$_cc" 2>/dev/null
    fi
    source "$_cc"; unset _cc
fi

# ── 12. fzf ───────────────────────────────────────────────────────────────────
if command -v fzf >/dev/null 2>&1; then
    eval "$(fzf --bash 2>/dev/null)" || {
        [[ -f /usr/share/doc/fzf/examples/key-bindings.bash ]] \
            && source /usr/share/doc/fzf/examples/key-bindings.bash
        [[ -f /usr/share/doc/fzf/examples/completion.bash ]] \
            && source /usr/share/doc/fzf/examples/completion.bash
    }
    export FZF_DEFAULT_OPTS="
        --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
        --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
        --color=marker:#a6e3a1,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
        --layout=reverse --border --height=~40%
        --bind='ctrl-/:toggle-preview'"
    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    fi
fi

# ── 13. zoxide ────────────────────────────────────────────────────────────────
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)" 2>/dev/null
    alias cdi='zi'
fi

# ── 14. Atuin (shell history with search) ─────────────────────────────────────
if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init bash)"
fi

# ── 15. direnv ────────────────────────────────────────────────────────────────
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook bash)"
fi

# ── 16. Starship prompt ──────────────────────────────────────────────────────
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

# ── 17. Local/private config ─────────────────────────────────────────────────
[[ -f ~/.bash_local ]] && source ~/.bash_local

# ── 18. Login summary (once per SSH session, never inside tmux) ───────────────
if command -v fastfetch >/dev/null 2>&1 \
    && shopt -q login_shell \
    && [[ -z "${TMUX:-}" ]] \
    && [[ -z "${_FASTFETCH_RAN:-}" ]]; then
    export _FASTFETCH_RAN=1
    fastfetch
fi
