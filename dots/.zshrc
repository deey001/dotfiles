# ==============================================================================
# .zshrc - Zsh Configuration File
# ==============================================================================
# Provides a consistent experience with your Bash setup, including Starship,
# aliases, and advanced completion.
# ==============================================================================

# ------------------------------------------------------------------------------
# Environment Detection
# ------------------------------------------------------------------------------
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    export IS_SSH=1
else
    export IS_SSH=0
fi

# ------------------------------------------------------------------------------
# History Settings
# ------------------------------------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt append_history
setopt extended_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_verify
setopt share_history

# ------------------------------------------------------------------------------
# Completion & UI Settings
# ------------------------------------------------------------------------------
autoload -Uz compinit && compinit

# Carapace - rich completions with descriptions for CLI tools (works across shells)
if command -v carapace >/dev/null 2>&1; then
    export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
    zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
    source <(carapace _carapace zsh)
fi

# fzf-tab: vertical dropdown completion powered by fzf
FZF_TAB_DIR="${HOME}/.local/share/fzf-tab"
if [[ ! -d "$FZF_TAB_DIR" ]] && command -v git >/dev/null 2>&1; then
    git clone --depth 1 https://github.com/Aloxaf/fzf-tab "$FZF_TAB_DIR" 2>/dev/null
fi
[[ -f "$FZF_TAB_DIR/fzf-tab.plugin.zsh" ]] && source "$FZF_TAB_DIR/fzf-tab.plugin.zsh"

# Case-insensitive and partial completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Colorized completion lists
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Group completions by type with headers
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:warnings' format '%F{red}No matches found%f'

# fzf-tab appearance
zstyle ':fzf-tab:complete:*' fzf-preview ''
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color=always $realpath 2>/dev/null || ls $realpath'
zstyle ':fzf-tab:*' fzf-flags --height=~40% --layout=reverse --border --color=bg+:#313244,fg+:#cdd6f4,hl:#f38ba8,hl+:#f38ba8,info:#cba6f7,prompt:#cba6f7,pointer:#f5e0dc,marker:#a6e3a1,spinner:#f5e0dc,header:#89b4fa
zstyle ':fzf-tab:*' switch-group '<' '>'

# Show completion menu immediately on ambiguous match
setopt complete_in_word
setopt always_to_end
setopt auto_menu
setopt auto_cd

# Key bindings for completion menu navigation
bindkey '^I'   complete-word              # TAB: trigger completion (fzf-tab intercepts)
bindkey '^[[Z' reverse-menu-complete      # Shift-TAB: cycle backward

# Accept autosuggestion with Right arrow
bindkey '^[[C' forward-char               # Right arrow: accept one char of suggestion
bindkey '^F'   forward-char               # Ctrl+F: accept one char
bindkey '^[f'  forward-word               # Alt+F: accept one word
bindkey '^[[1;3C' forward-word            # Alt+Right: accept one word

# History search with arrow keys (type prefix then Up/Down)
bindkey '^[[A' history-search-backward    # Up: search history backward
bindkey '^[[B' history-search-forward     # Down: search history forward

# ------------------------------------------------------------------------------
# Aliases & Functions (Shared with Bash)
# ------------------------------------------------------------------------------
# Standard ls/eza logic for Zsh
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --color=auto --icons'
    alias ll='eza -alF --icons'
    alias la='eza -A --icons'
    alias l='eza -CF --icons'
fi

# Load common files
[ -f ~/.bash_aliases ] && source ~/.bash_aliases
[ -f ~/.bash_functions ] && source ~/.bash_functions

# ------------------------------------------------------------------------------
# Modern Tool Initialization
# ------------------------------------------------------------------------------

# Zoxide (Smart CD)
if command -v zoxide > /dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# FZF (Fuzzy Finder) - key bindings and completion
if command -v fzf >/dev/null 2>&1; then
    eval "$(fzf --zsh 2>/dev/null)" || {
        [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
        [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
    }
    export FZF_DEFAULT_OPTS=" \
        --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
        --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
        --color=marker:#a6e3a1,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
        --layout=reverse --border --height=~40%"
fi

# ------------------------------------------------------------------------------
# Zsh Plugins (Syntax Highlighting & Autosuggestions)
# ------------------------------------------------------------------------------
# These provide the "ble.sh" experience for Zsh. 
# Locations are standardized for Homebrew (macOS) and Linux packages.

# Syntax Highlighting
if [ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [ -f /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Autosuggestions
if [ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [ -f /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# History substring search (type partial command, Up/Down filters by it)
if [ -f /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh ]; then
    source /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh
elif [ -f /usr/local/share/zsh-history-substring-search/zsh-history-substring-search.zsh ]; then
    source /usr/local/share/zsh-history-substring-search/zsh-history-substring-search.zsh
elif [ -f /usr/share/zsh-history-substring-search/zsh-history-substring-search.zsh ]; then
    source /usr/share/zsh-history-substring-search/zsh-history-substring-search.zsh
fi
if typeset -f history-substring-search-up > /dev/null 2>&1; then
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
fi

# Atuin (Magical Shell History - replaces Ctrl+R)
if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init zsh)"
fi

# ------------------------------------------------------------------------------
# Starship Prompt (Must be initialized last)
# ------------------------------------------------------------------------------
if command -v starship > /dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# ------------------------------------------------------------------------------
# Local Configuration
# ------------------------------------------------------------------------------
[ -f ~/.zsh_local ] && source ~/.zsh_local
[ -f ~/.bash_local ] && source ~/.bash_local

# ------------------------------------------------------------------------------
# Login Summary
# ------------------------------------------------------------------------------
if [[ -z "$TMUX" ]] && command -v fastfetch > /dev/null 2>&1; then
    fastfetch
fi
