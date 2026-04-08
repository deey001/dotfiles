# ==============================================================================
# .bashrc — Bash Configuration
# ==============================================================================
# Load order: .bash_profile → .bashrc → .common_shell → .bash_aliases → tools

# ── 1. Interactive-only guard ─────────────────────────────────────────────────
case $- in *i*) ;; *) return ;; esac

# ── 2. ble.sh early load (activated last in section 19) ──────────────────────
[[ -f "${HOME}/.local/share/blesh/ble.sh" ]] && \
    source "${HOME}/.local/share/blesh/ble.sh" --attach=none

# ── 3. History ────────────────────────────────────────────────────────────────
HISTCONTROL=ignoredups:ignorespace
HISTSIZE=50000
HISTFILESIZE=100000
HISTIGNORE="ls:ll:la:l:cd:pwd:exit:clear:history:bg:fg:jobs:c:q:vi:vim"
HISTTIMEFORMAT="%F %T "
shopt -s histappend cmdhist lithist
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# ── 4. Shell options ──────────────────────────────────────────────────────────
shopt -s checkwinsize globstar extglob nullglob cdspell dirspell autocd \
         no_empty_cmd_completion checkhash
stty -ixon 2>/dev/null    # free up Ctrl-S/Q for fzf

# ── 5. Readline (skipped when ble.sh is active — it has its own) ─────────────
if [[ ! ${BLE_VERSION-} ]]; then
    bind "set completion-ignore-case on"       2>/dev/null
    bind "set menu-complete-display-prefix on" 2>/dev/null
    bind "set colored-stats on"                2>/dev/null
    bind "set colored-completion-prefix on"    2>/dev/null
    bind "set show-all-if-unmodified on"       2>/dev/null
    bind "TAB:menu-complete"                   2>/dev/null
    bind '"\e[Z":menu-complete-backward'       2>/dev/null
fi

# ── 6. Terminal colors ────────────────────────────────────────────────────────
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
[[ -z "${debian_chroot:-}" && -r /etc/debian_chroot ]] && \
    debian_chroot=$(cat /etc/debian_chroot)
[ -x /usr/bin/dircolors ] && \
    { test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"; }

# ── 7. PATH + environment ─────────────────────────────────────────────────────
export PATH="${HOME}/.local/bin:${HOME}/bin:${PATH}"
# Deduplicate PATH (prevents bloat on repeated sourcing)
export PATH=$(awk -v RS=':' -v ORS=':' '!seen[$0]++' <<< "$PATH" | sed 's/:$//')

# Editor — prefer nvim, fall back gracefully
for _e in nvim vim vi nano; do
    command -v "$_e" >/dev/null 2>&1 && { export EDITOR="$_e" VISUAL="$_e"; break; }
done
unset _e

export LESS='-R'
: "${BAT_THEME:=Catppuccin Mocha}"   # theme.sh overrides this if stowed
export BAT_THEME BAT_PAGING="never"

# Go — only when installed
if command -v go >/dev/null 2>&1 || [[ -d /usr/local/go ]]; then
    export GOPATH="${HOME}/go"
    export PATH="${GOPATH}/bin:/usr/local/go/bin:${PATH}"
fi

# npm global bin
[[ -d "$HOME/.npm-global/bin" ]] && export PATH="$HOME/.npm-global/bin:$PATH"

# ── 8. Functions ──────────────────────────────────────────────────────────────

# extract — unpack any common archive format
extract() {
    for f in "$@"; do
        [ -f "$f" ] || { echo "'$f' not found"; continue; }
        case $f in
            *.tar.bz2|*.tbz2) tar xvjf "$f" ;;
            *.tar.gz|*.tgz)   tar xvzf "$f" ;;
            *.tar)             tar xvf  "$f" ;;
            *.bz2)             bunzip2  "$f" ;;
            *.gz)              gunzip   "$f" ;;
            *.rar)             rar x    "$f" ;;
            *.zip)             unzip    "$f" ;;
            *.Z)               uncompress "$f" ;;
            *.7z)              7z x     "$f" ;;
            *)                 echo "Cannot extract '$f'" ;;
        esac
    done
}

# up N — go up N directory levels (e.g., up 3)
up() { local d="" i; for ((i=0; i<${1:-1}; i++)); do d="../$d"; done; cd "${d:-.}"; }

# ftext — recursive case-insensitive grep with paging
ftext() { grep -iIHrn --color=always "$1" . | less -r; }

# fzf helpers
fcd() { local d; d=$(find . -type d -not -path '*/.*' 2>/dev/null | fzf +m) && cd "$d"; }
fv()  { local f; f=$(find . -type f -not -path '*/.*' 2>/dev/null | fzf +m) && nvim "$f"; }
fp()  {
    local f; f=$(find . -type f -not -path '*/.*' 2>/dev/null | fzf +m) || return
    echo -n "$f" | { command -v pbcopy &>/dev/null && pbcopy || xclip -selection clipboard; }
    echo "Copied: $f"
}

# whatsgoingon — print git status for every git repo in current directory
whatsgoingon() {
    for d in */; do
        [[ -d "$d/.git" ]] || continue
        pushd "$d" >/dev/null
        echo "$(tput bold)${d%/}$(tput sgr0)"
        git status --porcelain | grep -q . && git status -s || echo "clean"
        popd >/dev/null
    done
}

# ── 9. Shared config (.common_shell sets env; .bash_aliases sets aliases) ─────
[[ -f ~/.common_shell ]] && source ~/.common_shell
[[ -f ~/.bash_aliases ]] && source ~/.bash_aliases

# ── 10. Bash completion ───────────────────────────────────────────────────────
if ! shopt -oq posix; then
    for _f in \
        "${HOME}/.local/share/bash-completion/bash_completion" \
        /usr/share/bash-completion/bash_completion \
        /etc/bash_completion; do
        [[ -f "$_f" ]] && { source "$_f"; break; }
    done
    unset _f
fi

# ── 11. Carapace (cached init for fast startup) ───────────────────────────────
if command -v carapace >/dev/null 2>&1; then
    unset CARAPACE_BRIDGES
    complete -r tmux git docker kubectl helm 2>/dev/null
    _cc="${HOME}/.cache/carapace_init.bash"
    [[ ! -f "$_cc" || "$(command -v carapace)" -nt "$_cc" ]] && \
        carapace _carapace bash > "$_cc" 2>/dev/null
    source "$_cc"; unset _cc
fi

# ── 12. fzf ───────────────────────────────────────────────────────────────────
if command -v fzf >/dev/null 2>&1; then
    eval "$(fzf --bash 2>/dev/null)" || {
        [[ -f /usr/share/doc/fzf/examples/key-bindings.bash ]] && \
            source /usr/share/doc/fzf/examples/key-bindings.bash
        [[ -f /usr/share/doc/fzf/examples/completion.bash ]] && \
            source /usr/share/doc/fzf/examples/completion.bash
    }
    _c="${DOTFILES_FZF_COLORS:-bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8,fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc,marker:#a6e3a1,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8}"
    export FZF_DEFAULT_OPTS="--color=${_c} --layout=reverse --border --height=~40% --bind='ctrl-/:toggle-preview'"
    unset _c
    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    fi
fi

# ── 13. zoxide ────────────────────────────────────────────────────────────────
command -v zoxide >/dev/null 2>&1 && { eval "$(zoxide init bash)" 2>/dev/null; alias cdi='zi'; }

# ── 14. atuin ─────────────────────────────────────────────────────────────────
command -v atuin >/dev/null 2>&1 && eval "$(atuin init bash)"

# ── 15. direnv ────────────────────────────────────────────────────────────────
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook bash)"

# ── 16. Starship ─────────────────────────────────────────────────────────────
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"

# ── 17. Local config (secrets, machine-specific PATH, etc.) ──────────────────
[[ -f ~/.bash_local ]] && source ~/.bash_local

# ── 18. Fastfetch (login shells only, skip inside tmux) ──────────────────────
if command -v fastfetch >/dev/null 2>&1 \
    && shopt -q login_shell \
    && [[ -z "${TMUX:-}" && -z "${_FASTFETCH_RAN:-}" ]]; then
    export _FASTFETCH_RAN=1
    fastfetch
fi

# ── 19. ble.sh activation (MUST be last) ─────────────────────────────────────
[[ ${BLE_VERSION-} ]] && ble-attach

# ── Machine-specific completions ─────────────────────────────────────────────
[[ -f "$HOME/.openclaw/completions/openclaw.bash" ]] && \
    source "$HOME/.openclaw/completions/openclaw.bash"
