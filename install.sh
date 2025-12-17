#!/bin/bash

# ==============================================================================
# install.sh - Dotfiles Installation and Setup Script
# ==============================================================================
# This script handles the installation of dotfiles, system dependencies, and 
# configuration for both online and air-gapped environments.
#
# Key Features:
# - Detects OS (macOS, Linux: Debian/Ubuntu, RHEL/Fedora, Arch)
# - Detects Network Status (Online vs. Air-gapped)
# - Installs core tools: Tmux, Neovim, Git, Starship, etc.
# - Sets up correct symlinks for dotfiles
# - Configures fonts (Nerd Fonts)
# ==============================================================================

# ------------------------------------------------------------------------------
# Configuration Definitions
# ------------------------------------------------------------------------------

# Set the directory where the dotfiles are located (absolute path)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Dotfiles directory detected at: $DOTFILES_DIR"

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------

# Function: check_internet
# Description: Checks if the system has internet access by pinging a reliable host.
# Returns: 0 if online, 1 if offline (air-gapped).
check_internet() {
    echo "Checking internet connectivity..."
    if ping -c 1 8.8.8.8 &> /dev/null; then
        echo "Status: ONLINE"
        return 0
    else
        echo "Status: OFFLINE (Air-gapped mode)"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Pre-installation Checks
# ------------------------------------------------------------------------------

# Check for internet connection to determine installation mode
if check_internet; then
    IS_ONLINE=true
else
    IS_ONLINE=false
fi

# Strict validation of .bashrc before linking
# This prevents breaking the shell if the new .bashrc has fatal errors.
if [ -f "$DOTFILES_DIR/.bashrc" ]; then
    if ! bash -c ". '$DOTFILES_DIR/.bashrc' 2>/dev/null"; then
        echo "CRITICAL ERROR: .bashrc contains syntax errors or causes a segfault."
        echo "Aborting installation to prevent shell lockout."
        echo "Please fix .bashrc or comment out problematic sections."
        exit 1
    fi
fi

# ------------------------------------------------------------------------------
# Package Installation (OS Dependent)
# ------------------------------------------------------------------------------

OS="$(uname)"
echo "Detected Operating System: $OS"

if [ "$OS" = "Darwin" ]; then
    # ==========================================================================
    # macOS Installation
    # ==========================================================================
    if [ "$IS_ONLINE" = true ]; then
        # Install Homebrew if not present
        if ! command -v brew &> /dev/null; then
            echo "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        
        echo "Installing tools via Homebrew..."
        # Tmux: Terminal Multiplexer for session management
        # Git: Distributed version control system
        # Fzf: Command-line fuzzy finder suitable for scripts
        # Neovim: Hyperextensible Vim-based text editor
        # Starship: Customizable shell prompt
        # Hstr: Bash history suggest box
        # Bat: Cat clone with syntax highlighting
        # Eza: Modern replacement for ls
        # Fastfetch: System information fetching tool
        # Cmatrix: Falling matrix code screensaver
        # Btop: Resource monitor that shows usage and stats
        # Lazygit: Simple terminal UI for git commands
        # Glow: Terminal based markdown reader
        # Tldr: Simplified man pages
        brew install tmux git fzf neovim starship hstr bat eza fastfetch cmatrix btop lazygit glow tldr
        
        # Install Nerd Font for icons in terminal
        brew install --cask font-ubuntu-nerd-font
    else
        echo "Skipping Homebrew packages (Offline Mode)"
    fi

elif [ "$OS" = "Linux" ]; then
    # ==========================================================================
    # Linux Installation
    # ==========================================================================
    
    # --------------------------------------------------------------------------
    # Debian / Ubuntu
    # --------------------------------------------------------------------------
    if [ -f /etc/debian_version ]; then
        if [ "$IS_ONLINE" = true ]; then
            sudo apt update
            # Install build prerequisites
            sudo apt install -y curl xz-utils tar build-essential
            
            echo "Installing tools via apt..."
            # Core tools from repositories
            # xclip/wl-clipboard: Used for clipboard integration (copy/paste)
            sudo apt install -y tmux git fzf xclip bash-completion hstr bat cmatrix btop tldr
            
            # Install Latest Neovim (AppImage/Tarball is better than apt usually)
            echo "Installing latest Neovim..."
            if [ ! -f /usr/local/bin/nvim ]; then
                curl -LO https://github.com/neovim/neovim/releases/download/v0.11.0/nvim-linux-x86_64.tar.gz
                sudo tar -C /usr/local -xzf nvim-linux-x86_64.tar.gz
                sudo ln -sf /usr/local/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
                rm nvim-linux-x86_64.tar.gz
            fi
            
            # Install fastfetch from PPA (Better formatting than neofetch)
            echo "Installing fastfetch..."
            sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
            sudo apt update
            sudo apt install -y fastfetch
            
            # Install lazygit (Git TUI)
            echo "Installing lazygit..."
            LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
            curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
            tar xf lazygit.tar.gz lazygit
            sudo install lazygit /usr/local/bin
            rm lazygit lazygit.tar.gz
            
            # Install glow (Markdown Viewer)
            echo "Installing glow..."
            GLOW_VERSION=$(curl -s "https://api.github.com/repos/charmbracelet/glow/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
            curl -Lo glow.deb "https://github.com/charmbracelet/glow/releases/latest/download/glow_${GLOW_VERSION}_amd64.deb"
            sudo dpkg -i glow.deb
            rm glow.deb
            
            # Clean up Snap (Ubuntu specific optimization for servers)
            if grep -qi "ubuntu" /etc/os-release; then
                echo "Optimizing Ubuntu: Removing snapd..."
                sudo apt purge -y snapd
                sudo apt autoremove -y
                rm -rf "$HOME/snap"
                sudo apt-mark hold snapd
            fi
            
            # Wayland support for clipboard
            if [ -n "$WAYLAND_DISPLAY" ]; then
                sudo apt install -y wl-clipboard
            fi
        else
            echo "Offline Mode: Attempting to install available packages from cache/CD..."
            sudo apt install -y tmux git fzf xclip bash-completion hstr bat cmatrix btop || echo "Some packages failed to install in offline mode."
        fi

    # --------------------------------------------------------------------------
    # RHEL / CentOS / Fedora
    # --------------------------------------------------------------------------
    elif [ -f /etc/redhat-release ]; then
        echo "Installing tools via dnf/yum..."
        PKG_MANAGER="yum"
        command -v dnf > /dev/null 2>&1 && PKG_MANAGER="dnf"
        
        if [ "$IS_ONLINE" = true ]; then
            sudo $PKG_MANAGER install -y git tmux fzf neovim hstr bat fastfetch cmatrix btop lazygit glow tldr
        else
            echo "Offline Mode: Installing what is available..."
            sudo $PKG_MANAGER install -y git tmux fzf neovim hstr bat || true
        fi

    # --------------------------------------------------------------------------
    # Arch Linux
    # --------------------------------------------------------------------------
    elif [ -f /etc/arch-release ]; then
        echo "Installing tools via pacman..."
        if [ "$IS_ONLINE" = true ]; then
            sudo pacman -Syu --noconfirm git tmux fzf neovim hstr bat eza fastfetch cmatrix btop lazygit glow tldr
        else
            echo "Offline Mode: Updating skipped."
        fi
    fi
    
    # --------------------------------------------------------------------------
    # Fonts (Linux)
    # --------------------------------------------------------------------------
    # Only install fonts if online, otherwise assume they are pre-bundled or installed manually
    if [ "$IS_ONLINE" = true ]; then
        FONT_DIR="$HOME/.local/share/fonts"
        if [ ! -f "$FONT_DIR/UbuntuNerdFont-Regular.ttf" ]; then
            echo "Installing Ubuntu Nerd Font..."
            mkdir -p "$FONT_DIR"
            curl -fLo "$FONT_DIR/UbuntuNerdFont-Regular.ttf" \
              https://github.com/ryanoasis/nerd-fonts/releases/latest/download/UbuntuNerdFont-Regular.ttf
            if command -v fc-cache >/dev/null 2>&1; then
                fc-cache -f -v
            fi
        fi
    fi

    # --------------------------------------------------------------------------
    # Starship Prompt Installation
    # --------------------------------------------------------------------------
    if [ "$IS_ONLINE" = true ]; then
        if ! command -v starship >/dev/null 2>&1; then
            echo "Installing Starship..."
            curl -sS https://starship.rs/install.sh | sh -s -- -y
        fi
    fi
    
else
    echo "Unsupported OS: $OS"
    exit 1
fi

# ------------------------------------------------------------------------------
# Helper Tool Installation (ble.sh, TPM)
# ------------------------------------------------------------------------------

# ble.sh (Bash Line Editor) - Highlighting and Auto-suggestions
if [ "$IS_ONLINE" = true ] && [ ! -d "$HOME/.local/share/blesh/ble.sh" ]; then
    echo "Installing ble.sh (Bash Line Editor)..."
    git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git
    make -C ble.sh install PREFIX=~/.local
    rm -rf ble.sh
fi

# Base16 Shell - Color Themes
if [ "$IS_ONLINE" = true ] && [ ! -d "$HOME/.config/base16-shell" ]; then
    echo "Cloning base16-shell for color themes..."
    git clone https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell
fi

# Tmux Plugin Manager (TPM)
if [ "$IS_ONLINE" = true ] && [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "Cloning Tmux Plugin Manager..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# ------------------------------------------------------------------------------
# Dotfiles Symlinking & Setup
# ------------------------------------------------------------------------------

echo "Creating symlinks for dotfiles..."
# Links the source files from the git repo to the home directory
# -f forces the link, -s makes it symbolic
ln -sf "$DOTFILES_DIR/.bash_aliases" "$HOME/.bash_aliases"
ln -sf "$DOTFILES_DIR/.bash_exports" "$HOME/.bash_exports"
ln -sf "$DOTFILES_DIR/.bash_functions" "$HOME/.bash_functions"
ln -sf "$DOTFILES_DIR/.bash_profile" "$HOME/.bash_profile"
ln -sf "$DOTFILES_DIR/.bash_wrappers" "$HOME/.bash_wrappers"
ln -sf "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
ln -sf "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
ln -sf "$DOTFILES_DIR/.blerc" "$HOME/.blerc"

# Config directory setups
mkdir -p "$HOME/.config"
ln -sf "$DOTFILES_DIR/.config/starship.toml" "$HOME/.config/starship.toml"

# Symlink Tmux Config & Scripts
# This puts the scripts in ~/.config/tmux/scripts/ which is cleaner than ~/.local/bin
mkdir -p "$HOME/.config/tmux"
ln -sf "$DOTFILES_DIR/.config/tmux/scripts" "$HOME/.config/tmux/scripts"
# Ensure the script is executable (in the source repo)
chmod +x "$DOTFILES_DIR/.config/tmux/scripts/get_network_status.sh"

# Bat (Better Cat) Theme Setup
mkdir -p "$HOME/.config/bat"
ln -sf "$DOTFILES_DIR/.config/bat/themes" "$HOME/.config/bat/themes"
if command -v bat > /dev/null 2>&1; then
    bat cache --build
elif command -v batcat > /dev/null 2>&1; then
    batcat cache --build
fi

# Neovim Setup
mkdir -p "$HOME/.config/nvim"
ln -sf "$DOTFILES_DIR/.config/nvim/init.lua" "$HOME/.config/nvim/init.lua"
echo "Neovim configured with LazyVim. Plugins will auto-install on first run (Internet required)."

# Fastfetch Config
mkdir -p "$HOME/.config/fastfetch"
ln -sf "$DOTFILES_DIR/.config/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"

# Alacritty Config
mkdir -p "$HOME/.config/alacritty"
ln -sf "$DOTFILES_DIR/.config/alacritty/alacritty.yml" "$HOME/.config/alacritty/alacritty.yml"

# ------------------------------------------------------------------------------
# SSH Key Installation
# ------------------------------------------------------------------------------
SSH_KEY_SOURCE="$DOTFILES_DIR/MDC_public.pub"
if [ -f "$SSH_KEY_SOURCE" ]; then
    echo "Installing SSH key to authorized_keys..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    # Append key only if it doesn't exist
    if ! grep -q -F "$(cat "$SSH_KEY_SOURCE")" "$HOME/.ssh/authorized_keys" 2>/dev/null; then
        cat "$SSH_KEY_SOURCE" >> "$HOME/.ssh/authorized_keys"
        chmod 600 "$HOME/.ssh/authorized_keys"
        echo "SSH key added."
    else
        echo "SSH key already present."
    fi
else
    echo "Warning: SSH key ($SSH_KEY_SOURCE) not found. Skipping."
fi

# ------------------------------------------------------------------------------
# Final Initialization
# ------------------------------------------------------------------------------

# Ensure Starship init is in .bashrc (Redundancy check)
if ! grep -q "starship init bash" "$HOME/.bashrc" && [ -f /usr/local/bin/starship ]; then
    echo '# Initialize Starship prompt' >> "$HOME/.bashrc"
    echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
fi

# Reload Bash Profile
source "$HOME/.bash_profile"

echo "=============================================================================="
echo "Installation Complete!"
echo "Notes:"
echo "1. Restart your terminal or run 'exec bash' to apply changes."
echo "2. If using Tmux, press 'prefix + I' to install plugins."
if [ "$IS_ONLINE" = false ]; then
    echo "Warning: Installation completed in OFFLINE mode. Some tools/fonts may be missing."
fi
echo "=============================================================================="
