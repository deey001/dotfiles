# ==============================================================================
# Brewfile - Homebrew Package Declaration for macOS
# ==============================================================================
# This file declares all packages and casks to be installed via Homebrew on
# macOS systems. It's used by the `brew bundle` command.
#
# WHAT IS A BREWFILE?
#   - A declarative list of Homebrew packages, casks (apps), and fonts
#   - Allows reproducible setup across multiple Macs
#   - Can be version controlled and shared
#
# USAGE:
#   1. Install Homebrew (done automatically by install.sh):
#      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
#
#   2. Install all packages from this file:
#      brew bundle --file=~/dotfiles/Brewfile
#
#   3. Check what's installed vs what's in the Brewfile:
#      brew bundle check --file=~/dotfiles/Brewfile
#
#   4. Cleanup packages not in Brewfile:
#      brew bundle cleanup --file=~/dotfiles/Brewfile
#
# EXAMPLES:
#   - Add a new formula: echo 'brew "package-name"' >> Brewfile
#   - Add a new cask: echo 'cask "app-name"' >> Brewfile
#   - Dump current packages: brew bundle dump --force
# ==============================================================================

# ------------------------------------------------------------------------------
# Core Shell & Terminal Tools
# ------------------------------------------------------------------------------

# Tmux - Terminal multiplexer for managing multiple shell sessions
brew "tmux"

# Git - Distributed version control system
brew "git"

# Neovim - Modern, extensible text editor (Vim fork)
brew "neovim"

# Starship - Fast, customizable shell prompt written in Rust
brew "starship"

# ------------------------------------------------------------------------------
# Modern CLI Replacements
# ------------------------------------------------------------------------------

# Eza - Modern replacement for 'ls' with icons and git integration
brew "eza"

# Bat - Better 'cat' with syntax highlighting and line numbers
brew "bat"

# Ripgrep - Faster 'grep' that respects .gitignore
brew "ripgrep"

# Fd - Simple, fast alternative to 'find'
brew "fd"

# Zoxide - Smarter 'cd' that learns your habits
brew "zoxide"

# Dust - More intuitive 'du' (disk usage)
brew "dust"

# Procs - Modern replacement for 'ps'
brew "procs"

# Bottom - Graphical process/resource monitor (like htop/top)
brew "bottom"

# ------------------------------------------------------------------------------
# Search & Navigation
# ------------------------------------------------------------------------------

# Fzf - Command-line fuzzy finder
brew "fzf"

# Hstr - Better bash history search
brew "hstr"

# ------------------------------------------------------------------------------
# System Information & Monitoring
# ------------------------------------------------------------------------------

# Fastfetch - Fast system information tool (neofetch alternative)
brew "fastfetch"

# Btop - Beautiful resource monitor
brew "btop"

# ------------------------------------------------------------------------------
# Developer Tools
# ------------------------------------------------------------------------------

# Lazygit - Terminal UI for git commands
brew "lazygit"

# Glow - Terminal markdown reader
brew "glow"

# Tldr - Simplified, community-driven man pages
brew "tldr"

# Jq - Command-line JSON processor
brew "jq"

# ------------------------------------------------------------------------------
# Fun Stuff
# ------------------------------------------------------------------------------

# Cmatrix - Matrix-style falling characters in terminal
brew "cmatrix"

# ------------------------------------------------------------------------------
# Fonts (Nerd Fonts)
# ------------------------------------------------------------------------------
# Nerd Fonts include icons and glyphs for powerline, devicons, etc.

# Ubuntu Nerd Font - Used by Starship prompt and terminal icons
cask "font-ubuntu-nerd-font"

# Additional recommended Nerd Fonts (uncomment if desired)
# cask "font-jetbrains-mono-nerd-font"
# cask "font-fira-code-nerd-font"
# cask "font-meslo-lg-nerd-font"

# ------------------------------------------------------------------------------
# Optional Casks (GUI Applications)
# ------------------------------------------------------------------------------
# Uncomment these if you want GUI applications installed

# Alacritty - Fast, GPU-accelerated terminal emulator
# cask "alacritty"

# iTerm2 - macOS terminal replacement
# cask "iterm2"

# WezTerm - GPU-accelerated cross-platform terminal
# cask "wezterm"

# Visual Studio Code - Popular code editor
# cask "visual-studio-code"

# Docker Desktop - Containerization platform
# cask "docker"

# ------------------------------------------------------------------------------
# Tap Additional Repositories (if needed)
# ------------------------------------------------------------------------------
# Taps allow installing packages from third-party repositories

# Example: Tap Homebrew versions for older package versions
# tap "homebrew/cask-versions"
