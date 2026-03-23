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
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' # Case-insensitive completion
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # Colorized completion
setopt complete_in_word
setopt auto_cd

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

# FZF (Fuzzy Finder)
if [ -f ~/.fzf.zsh ]; then
    source ~/.fzf.zsh
elif [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
    source /usr/share/doc/fzf/examples/key-bindings.zsh
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
