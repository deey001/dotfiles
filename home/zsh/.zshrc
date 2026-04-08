# Source shared shell configuration
[[ -f ~/.common_shell ]] && source ~/.common_shell

# ==============================================================================
# .zshrc — Zsh Configuration
# ==============================================================================
# Provides a consistent experience with your Bash setup, including Starship,
# aliases, and advanced completion.
#
# WHEN LOADED:
#   - By Zsh for every interactive shell session
#   - NOT loaded for non-interactive scripts (use .zshenv for those)
#   - Load order: .zshenv → .zprofile (login) → .zshrc (interactive) → .zlogin
#
# SOURCES (in order):
#   1. carapace (rich CLI completions)
#   2. fzf-tab (fuzzy dropdown completion)
#   3. ~/.bash_aliases (shared with Bash — modern tool replacements)
#   4. zoxide, fzf (tool initialization)
#   5. zsh-syntax-highlighting, zsh-autosuggestions, zsh-history-substring-search
#   6. atuin (magical shell history)
#   7. starship (prompt — must be last)
#   8. ~/.zsh_local / ~/.bash_local (machine-specific overrides)
#
# DEPENDENCIES:
#   Required: Zsh 5.8+
#   Optional: starship, fzf, zoxide, eza, carapace, atuin, fastfetch, git
#   Plugins: zsh-syntax-highlighting, zsh-autosuggestions, zsh-history-substring-search
#            (installed via Homebrew on macOS or system packages on Linux)
#
# PROMPT:
#   Uses Starship (https://starship.rs) — a fast, cross-shell prompt written in Rust.
#   Config lives at ~/.config/starship.toml. Starship is preferred over Powerlevel10k
#   because it works identically across Bash, Zsh, and Fish with a single config file.
#   Alternative: Powerlevel10k (Zsh-only, richer features, requires `p10k configure`)
#
# PLUGIN MANAGEMENT:
#   Plugins are loaded directly from system paths (Homebrew/apt) rather than using
#   a plugin manager. This avoids an extra dependency and keeps startup fast.
#   Alternatives if you want managed plugins:
#     - zinit: fast, lazy-loading plugin manager (https://github.com/zdharma-continuum/zinit)
#     - antidote: lightweight, antibody successor (https://github.com/mattmc3/antidote)
#     - sheldon: Rust-based, config in TOML (https://github.com/rossmacarthur/sheldon)
# ==============================================================================

# ------------------------------------------------------------------------------
# Environment Detection
# ------------------------------------------------------------------------------
# Detect SSH sessions for conditional behavior (e.g., skip GUI-only features)
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
    export IS_SSH=1
else
    export IS_SSH=0
fi

# ------------------------------------------------------------------------------
# History Settings
# ------------------------------------------------------------------------------
# Zsh history is stored separately from Bash (~/.zsh_history vs ~/.bash_history)
HISTFILE=~/.zsh_history
HISTSIZE=10000                    # Max entries held in memory per session
SAVEHIST=10000                    # Max entries persisted to HISTFILE
setopt append_history             # Append to history file (don't overwrite)
setopt extended_history           # Save timestamp and duration for each command
setopt hist_expire_dups_first     # Expire duplicate entries first when trimming
setopt hist_ignore_dups           # Don't record consecutive duplicate commands
setopt hist_ignore_space          # Commands prefixed with space are not recorded (for secrets)
setopt hist_verify                # Show expanded history command before executing
setopt share_history              # Share history across all active Zsh sessions in real time

# ------------------------------------------------------------------------------
# Completion & UI Settings
# ------------------------------------------------------------------------------
# Initialize Zsh's built-in completion system (compinit)
autoload -Uz compinit && compinit

# Carapace — multi-shell completion engine with rich descriptions for 600+ CLI tools
# Bridges completions from other shells (fish, bash) into Zsh
if command -v carapace >/dev/null 2>&1; then
    export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
    zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
    source <(carapace _carapace zsh)
fi

# fzf-tab: replaces Zsh's default TAB completion menu with a fzf-powered dropdown
# Auto-clones on first run if not already installed
FZF_TAB_DIR="${HOME}/.local/share/fzf-tab"
if [[ ! -d "$FZF_TAB_DIR" ]] && command -v git >/dev/null 2>&1; then
    git clone --depth 1 https://github.com/Aloxaf/fzf-tab "$FZF_TAB_DIR" 2>/dev/null
fi
[[ -f "$FZF_TAB_DIR/fzf-tab.plugin.zsh" ]] && source "$FZF_TAB_DIR/fzf-tab.plugin.zsh"

# Case-insensitive and partial completion (e.g., "readme" matches "README.md")
# 'm:{a-zA-Z}={A-Za-z}' — case insensitive
# 'r:|[._-]=*' — partial match at word boundaries (e.g., "f.b" → "foo.bar")
# 'l:|=* r:|=*' — substring matching from either end
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Use LS_COLORS to colorize completion listings (files, dirs, symlinks, etc.)
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Group completions by type (commands, files, options, etc.) with labeled headers
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:warnings' format '%F{red}No matches found%f'

# fzf-tab appearance — colors come from the active theme's DOTFILES_FZFTAB_COLORS.
# Fallback to Catppuccin Mocha hex values if no theme is stowed yet.
zstyle ':fzf-tab:complete:*' fzf-preview ''
# Show directory contents preview when completing `cd` arguments
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color=always $realpath 2>/dev/null || ls $realpath'
# fzf-tab color flags — sourced from DOTFILES_FZFTAB_COLORS (set by theme.sh via .common_shell)
_fzftab_colors="${DOTFILES_FZFTAB_COLORS:-bg+:#313244,fg+:#cdd6f4,hl:#f38ba8,hl+:#f38ba8,info:#cba6f7,prompt:#cba6f7,pointer:#f5e0dc,marker:#a6e3a1,spinner:#f5e0dc,header:#89b4fa}"
zstyle ':fzf-tab:*' fzf-flags --height=~40% --layout=reverse --border --color="${_fzftab_colors}"
unset _fzftab_colors
# Use < and > keys to switch between completion groups
zstyle ':fzf-tab:*' switch-group '<' '>'

# Show completion menu immediately on ambiguous match
setopt complete_in_word           # Complete from both ends of a word
setopt always_to_end              # Move cursor to end of word after completion
setopt auto_menu                  # Show completion menu on second TAB
setopt auto_cd                    # Type a directory name to cd into it (no cd needed)

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
# Load shared alias file — contains eza/ls, git, navigation, and all other aliases.
# Defined once in .bash_aliases and sourced by both Bash and Zsh.
# No need to re-define eza/ls here; .bash_aliases handles the eza guard.
[ -f ~/.bash_aliases ] && source ~/.bash_aliases

# ------------------------------------------------------------------------------
# Modern Tool Initialization
# ------------------------------------------------------------------------------

# Zoxide — smarter cd that learns your most-visited directories
# Usage: z <partial-path> (e.g., "z proj" → cd ~/code/my-project)
if command -v zoxide > /dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# FZF (Fuzzy Finder) — Ctrl+R for history, Ctrl+T for files, Alt+C for cd
# `fzf --zsh` (fzf 0.48+) generates both key bindings and completion;
# older installs fall back to sourcing individual scripts
if command -v fzf >/dev/null 2>&1; then
    eval "$(fzf --zsh 2>/dev/null)" || {
        [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
        [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && source /usr/share/doc/fzf/examples/key-bindings.zsh
    }
    # FZF_DEFAULT_OPTS: DOTFILES_FZF_COLORS is set by the active theme (via .common_shell).
    # Fallback to Catppuccin Mocha values if no theme is stowed yet.
    _fzf_colors="${DOTFILES_FZF_COLORS:-bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8,fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc,marker:#a6e3a1,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8}"
    export FZF_DEFAULT_OPTS="--color=${_fzf_colors} --layout=reverse --border --height=~40%"
    unset _fzf_colors
fi

# ------------------------------------------------------------------------------
# Zsh Plugins (Syntax Highlighting & Autosuggestions)
# ------------------------------------------------------------------------------
# These provide the "ble.sh" experience for Zsh:
#   - syntax-highlighting: colorizes commands as you type (red=invalid, green=valid)
#   - autosuggestions: ghost-text suggestions from history (accept with →)
#   - history-substring-search: type partial command + Up/Down to filter history
#
# Loaded from standard paths for Homebrew (macOS) and system packages (Linux).
# Order matters: syntax-highlighting should load BEFORE autosuggestions.
#
# Suggested additional plugins (not currently installed):
# - zsh-completions: extra completion definitions for 200+ tools
#     brew install zsh-completions  (then add to fpath before compinit)
# - zsh-you-should-use: reminds you of existing aliases when you type the full command
#     brew install zsh-you-should-use
# - zsh-autopair: auto-close brackets, quotes, and parentheses
#     https://github.com/hlissner/zsh-autopair

# Syntax Highlighting — colorizes commands as you type
# Checks Homebrew (ARM macOS), Homebrew (Intel macOS), and Linux system paths
if [ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [ -f /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Autosuggestions — shows ghost-text from history as you type
# Accept with → (forward-char) or Alt+→ (forward-word)
if [ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [ -f /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# History substring search — enhanced Up/Down that filters by typed prefix
# Type partial command then Up/Down to cycle through matching history only
# This overrides the basic history-search bindings defined earlier when available
if [ -f /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh ]; then
    source /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh
elif [ -f /usr/local/share/zsh-history-substring-search/zsh-history-substring-search.zsh ]; then
    source /usr/local/share/zsh-history-substring-search/zsh-history-substring-search.zsh
elif [ -f /usr/share/zsh-history-substring-search/zsh-history-substring-search.zsh ]; then
    source /usr/share/zsh-history-substring-search/zsh-history-substring-search.zsh
fi
# Bind Up/Down to substring search if the plugin loaded successfully
# typeset -f checks if the function exists (plugin loaded)
if typeset -f history-substring-search-up > /dev/null 2>&1; then
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
fi

# Atuin — magical shell history: stores history in a SQLite database with
# context (directory, hostname, exit code). Replaces Ctrl+R with a TUI.
# https://atuin.sh
if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init zsh)"
fi

# ------------------------------------------------------------------------------
# Starship Prompt (Must be initialized LAST)
# ------------------------------------------------------------------------------
# Starship overrides the PROMPT/RPROMPT variables, so it must come after all
# other plugins and tools to avoid being clobbered. Config: ~/.config/starship.toml
if command -v starship > /dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# ------------------------------------------------------------------------------
# Local Configuration (Machine-specific overrides — not tracked in git)
# ------------------------------------------------------------------------------
# ~/.zsh_local: Zsh-specific local settings
# ~/.bash_local: Shared local settings (tokens, secrets, PATH additions)
# Create from templates/.bash_local.template if needed
[ -f ~/.zsh_local ] && source ~/.zsh_local
[ -f ~/.bash_local ] && source ~/.bash_local

# ------------------------------------------------------------------------------
# Login Summary (once per session, not inside tmux)
# ------------------------------------------------------------------------------
# Show system info via fastfetch on first interactive login
# Skipped inside tmux to avoid cluttering every new pane/window
# _FASTFETCH_RAN guard ensures it only runs once per terminal session
if command -v fastfetch >/dev/null 2>&1 \
    && [[ -z "${TMUX:-}" ]] \
    && [[ -z "${_FASTFETCH_RAN:-}" ]]; then
    export _FASTFETCH_RAN=1
    fastfetch
fi
