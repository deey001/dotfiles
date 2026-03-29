# ==============================================================================
# .bashrc — Bash Configuration
# ==============================================================================
# Executed by bash(1) for interactive shells.
# Load order: .bash_profile → .bashrc → .bash_exports → .bash_aliases
#             → .bash_functions → .bash_wrappers → .bash_local
# ==============================================================================

# ── 1. Interactive-only guard ──────────────────────────────────────────────────
case $- in *i*) ;; *) return ;; esac

# ── 2. ble.sh — Bash Line Editor (syntax highlighting, auto-complete, vim mode) ─
# Requires: bash-completion >= 2.12, fzf >= 0.61 (fixes read: '': not a valid
# identifier on bash 5.2 — upstream bugs in bash-completion/fzf, not ble.sh).
# Install: bash ~/dotfiles/scripts/install-blesh.sh
if [[ -f ~/.local/share/blesh/ble.sh && $- == *i* ]]; then
    source ~/.local/share/blesh/ble.sh --attach=none
fi

# ── 3. History ─────────────────────────────────────────────────────────────────
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

# ── 4. Environment detection ───────────────────────────────────────────────────
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

# ── 5. Connectivity check (file-cached, one ping per 5 minutes across all shells)
# tmux panes are children of the tmux server process — they don't inherit the
# login shell's exported env. Cache file lets all shells read IS_ONLINE cheaply.
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

# ── 6. Shell options ───────────────────────────────────────────────────────────
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

# ── 7. Readline bindings ───────────────────────────────────────────────────────
bind "set completion-ignore-case on"       2>/dev/null
bind "set show-all-if-ambiguous on"        2>/dev/null
bind "set menu-complete-display-prefix on" 2>/dev/null
bind "set colored-stats on"                2>/dev/null
bind "set colored-completion-prefix on"    2>/dev/null
bind "TAB:menu-complete"                   2>/dev/null
bind '"\e[Z":menu-complete-backward'       2>/dev/null

# ── 8. Terminal utilities ──────────────────────────────────────────────────────
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi
# Set LS_COLORS via dircolors — aliases are the single source of truth below
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

# ── 9. Core aliases (single source of truth — NOT duplicated in .bash_aliases) ─
# ls: eza → ls --color fallback
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
# cat: bat → batcat → system cat
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

# ── 10. Modular config files ───────────────────────────────────────────────────
[[ -f ~/.bash_exports   ]] && source ~/.bash_exports
[[ -f ~/.bash_aliases   ]] && source ~/.bash_aliases
[[ -f ~/.bash_functions ]] && source ~/.bash_functions
[[ -f ~/.bash_wrappers  ]] && source ~/.bash_wrappers

# ── 11. System bash-completion ────────────────────────────────────────────────
if ! shopt -oq posix; then
    if [[ -f /usr/share/bash-completion/bash_completion ]]; then
        source /usr/share/bash-completion/bash_completion
    elif [[ -f /etc/bash_completion ]]; then
        source /etc/bash_completion
    fi
fi

# ── 12. Carapace (order matters: clear stale completions FIRST, then register) ─
# bash-completion loaded above may register handlers for tmux, git, etc.
# Those must be cleared BEFORE carapace registers its own, or the next
# complete -r call (the old bug) would delete carapace's registrations.
if command -v carapace >/dev/null 2>&1; then
    unset CARAPACE_BRIDGES
    complete -r tmux git docker kubectl helm 2>/dev/null
    # Cache carapace init output; regenerate only when the binary changes.
    _cc="${HOME}/.cache/carapace_init.bash"
    if [[ ! -f "$_cc" ]] || [[ "$(command -v carapace)" -nt "$_cc" ]]; then
        carapace _carapace bash > "$_cc" 2>/dev/null
    fi
    source "$_cc"; unset _cc
fi

# ── 13. fzf ────────────────────────────────────────────────────────────────────
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

# ── 13b. Completion version guard ─────────────────────────────────────────────
# bash-completion < 2.12 passes empty ${ipvx-} as a read variable name.
# fzf < 0.61 has __fzf_list_hosts using failglob unsafely.
# Both cause "read: '': not a valid identifier" on bash 5.2.
# Workaround: remove SSH-related completions on affected versions.
# Permanent fix: bash ~/dotfiles/scripts/install.sh (upgrades both tools).
{
    _bc_ver=$(pkg-config --modversion bash-completion 2>/dev/null)
    _bc_maj=${_bc_ver%%.*}
    _bc_min=${_bc_ver#*.}; _bc_min=${_bc_min%%.*}
    _fzf_ver=$(fzf --version 2>/dev/null | awk '{print $1}')
    _fzf_min=${_fzf_ver#*.}; _fzf_min=${_fzf_min%%.*}
    _need_fix=0
    [[ -n "$_bc_maj" && ("$_bc_maj" -lt 2 || ("$_bc_maj" -eq 2 && "${_bc_min:-0}" -lt 12)) ]] \
        && _need_fix=1
    [[ -n "$_fzf_ver" && "${_fzf_ver%%.*}" -eq 0 && "${_fzf_min:-99}" -lt 61 ]] \
        && _need_fix=1
    if [[ "$_need_fix" -eq 1 ]]; then
        complete -r ssh scp sftp 2>/dev/null
        unset -f _ssh _scp _sftp _known_hosts_real \
                 __fzf_list_hosts __fzf_complete_ssh 2>/dev/null
    fi
    unset _bc_ver _bc_maj _bc_min _fzf_ver _fzf_min _need_fix
}

# ── 14. zoxide ────────────────────────────────────────────────────────────────
# Don't alias cd=z — scripts rely on 'cd' behaving as the builtin.
# Use 'z' directly for frecency-based jumps; 'cdi' for interactive fzf picker.
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)" 2>/dev/null
    alias cdi='zi'
fi

# ── 15. Atuin (shell history) ──────────────────────────────────────────────────
if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init bash)"
fi

# ── 16. direnv (per-directory environment) ────────────────────────────────────
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook bash)"
fi

# ── 17. Starship prompt (after atuin/direnv so they don't clobber it) ──────────
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

# ── 18. Local/private config ──────────────────────────────────────────────────
# Machine-specific overrides, API keys, custom PATH additions.
# Created from templates/.bash_local.template — NOT tracked in git.
[[ -f ~/.bash_local ]] && source ~/.bash_local

# ── 19. Login summary (exactly once per SSH session, never inside tmux) ────────
# _FASTFETCH_RAN is exported so nested login shells (bash -l) also skip it.
# Root cause of double-run: .bash_profile sources .bashrc both via .profile
# AND directly, so shopt -q login_shell alone fires twice.
if command -v fastfetch >/dev/null 2>&1 \
    && shopt -q login_shell \
    && [[ -z "${TMUX:-}" ]] \
    && [[ -z "${_FASTFETCH_RAN:-}" ]]; then
    export _FASTFETCH_RAN=1
    fastfetch
fi

# ── 20. ble.sh attach (must be last — after all completions/prompts are set up) ─
[[ ${BLE_VERSION-} ]] && ble-attach
