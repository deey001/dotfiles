# ==============================================================================
# .zshrc — Zsh Configuration
# ==============================================================================
# Load order: .zshenv → .zprofile (login) → .zshrc (interactive) → .zlogin
#
# SOURCES (in order):
#   1. .common_shell   — shared env vars + theme (sets EDITOR, PAGER, LANG, etc.)
#   2. .bash_aliases   — all aliases, shared with Bash
#   3. carapace        — rich completions for 600+ CLI tools
#   4. fzf-tab         — fzf-powered completion dropdown
#   5. zoxide, fzf     — smarter cd + fuzzy finder
#   6. zsh plugins     — syntax-highlighting, autosuggestions, history-substring-search
#   7. atuin           — SQLite-backed shell history
#   8. starship        — cross-shell prompt (MUST be last)
#   9. .zsh_local / .bash_local — machine-specific overrides (not in git)
# ==============================================================================

# ── Shared environment (theme, EDITOR, PAGER, LANG, mkcd) ────────────────────
[[ -f ~/.common_shell ]] && source ~/.common_shell

# ── History ───────────────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt append_history extended_history hist_expire_dups_first \
       hist_ignore_dups hist_ignore_space hist_verify share_history

# ── Completion ────────────────────────────────────────────────────────────────
# Fast compinit: full security check at most once per 24h; skip otherwise.
# compaudit is the slowest step in a cold zsh startup.
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# Carapace — multi-shell completion engine (600+ tools, bridges fish/bash completions).
# Cached init — avoids spawning carapace on every shell startup.
if command -v carapace >/dev/null 2>&1; then
    export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
    zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
    _cc="${HOME}/.cache/carapace_init.zsh"
    [[ ! -f "$_cc" || "$(command -v carapace)" -nt "$_cc" ]] && \
        carapace _carapace zsh > "$_cc" 2>/dev/null
    source "$_cc"
    unset _cc
fi

# fzf-tab — replaces TAB menu with fzf dropdown; auto-clones on first run
FZF_TAB_DIR="${HOME}/.local/share/fzf-tab"
if [[ ! -d "$FZF_TAB_DIR" ]] && command -v git >/dev/null 2>&1; then
    git clone --depth 1 https://github.com/Aloxaf/fzf-tab "$FZF_TAB_DIR" 2>/dev/null
fi
[[ -f "$FZF_TAB_DIR/fzf-tab.plugin.zsh" ]] && source "$FZF_TAB_DIR/fzf-tab.plugin.zsh"

# Completion appearance & matching
# Case-insensitive + partial match at word boundaries (e.g. "f.b" → "foo.bar")
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:warnings' format '%F{red}No matches found%f'

# fzf-tab colors — DOTFILES_FZFTAB_COLORS set by theme.sh; fallback = Catppuccin Mocha
_fzftab_c="${DOTFILES_FZFTAB_COLORS:-bg+:#313244,fg+:#cdd6f4,hl:#f38ba8,hl+:#f38ba8,info:#cba6f7,prompt:#cba6f7,pointer:#f5e0dc,marker:#a6e3a1,spinner:#f5e0dc,header:#89b4fa}"
zstyle ':fzf-tab:complete:*'   fzf-preview ''
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color=always $realpath 2>/dev/null || ls $realpath'
zstyle ':fzf-tab:*' fzf-flags --height=~40% --layout=reverse --border --color="${_fzftab_c}"
zstyle ':fzf-tab:*' switch-group '<' '>'
unset _fzftab_c

setopt complete_in_word always_to_end auto_menu auto_cd

# ── Key bindings ──────────────────────────────────────────────────────────────
bindkey '^I'      complete-word             # TAB: completion (fzf-tab intercepts)
bindkey '^[[Z'    reverse-menu-complete     # Shift-TAB: cycle backward
bindkey '^[[C'    forward-char              # Right: accept autosuggestion char
bindkey '^F'      forward-char              # Ctrl+F: same
bindkey '^[f'     forward-word              # Alt+F: accept one word
bindkey '^[[1;3C' forward-word              # Alt+Right: accept one word
bindkey '^[[A'    history-search-backward   # Up: search history by prefix
bindkey '^[[B'    history-search-forward    # Down: search history by prefix

# ── Aliases (shared with Bash) ────────────────────────────────────────────────
[[ -f ~/.bash_aliases ]] && source ~/.bash_aliases

# ── zoxide — smarter cd ───────────────────────────────────────────────────────
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# ── fzf — fuzzy finder ────────────────────────────────────────────────────────
if command -v fzf >/dev/null 2>&1; then
    eval "$(fzf --zsh 2>/dev/null)" || {
        [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
        [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]] && \
            source /usr/share/doc/fzf/examples/key-bindings.zsh
    }
    # DOTFILES_FZF_COLORS set by theme.sh; fallback = Catppuccin Mocha
    _fzf_c="${DOTFILES_FZF_COLORS:-bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8,fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc,marker:#a6e3a1,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8}"
    export FZF_DEFAULT_OPTS="--color=${_fzf_c} --layout=reverse --border --height=~40%"
    unset _fzf_c
    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    fi
fi

# ── Zsh plugins ───────────────────────────────────────────────────────────────
# Helper: source a plugin from the first path that exists
# Checks Homebrew (ARM macOS), Homebrew (Intel macOS), and system (Linux)
_zsh_plugin() {
    local name=$1
    local dirs=(/opt/homebrew/share /usr/local/share /usr/share)
    for d in "${dirs[@]}"; do
        [[ -f "$d/$name/$name.zsh" ]] && { source "$d/$name/$name.zsh"; return 0; }
    done
    return 1
}

# Order matters: syntax-highlighting → autosuggestions → history-substring-search
_zsh_plugin zsh-syntax-highlighting
_zsh_plugin zsh-autosuggestions
if _zsh_plugin zsh-history-substring-search; then
    # Override the basic Up/Down bindings set above with the richer substring search
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
fi
unset -f _zsh_plugin

# ── atuin — SQLite shell history ──────────────────────────────────────────────
command -v atuin >/dev/null 2>&1 && eval "$(atuin init zsh)"

# ── direnv — per-directory env vars ──────────────────────────────────────────
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

# ── Starship prompt (MUST be last) ────────────────────────────────────────────
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# ── Local config (not tracked in git) ────────────────────────────────────────
[[ -f ~/.zsh_local  ]] && source ~/.zsh_local
[[ -f ~/.bash_local ]] && source ~/.bash_local

# ── Fastfetch login summary (skip inside tmux) ───────────────────────────────
if command -v fastfetch >/dev/null 2>&1 \
    && [[ -z "${TMUX:-}" && -z "${_FASTFETCH_RAN:-}" ]]; then
    export _FASTFETCH_RAN=1
    fastfetch
fi
