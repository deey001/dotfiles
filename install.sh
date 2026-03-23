#!/bin/bash
set -euo pipefail

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
# - Backs up existing configs before installation
# ==============================================================================

# ------------------------------------------------------------------------------
# Version Configuration
# ------------------------------------------------------------------------------
# Update these versions as needed for new releases

NEOVIM_VERSION="0.11.0"
STARSHIP_VERSION="latest"  # Uses latest from starship.rs installer
LAZYGIT_VERSION="latest"   # Fetched dynamically from GitHub API
GLOW_VERSION="latest"      # Fetched dynamically from GitHub API

# ------------------------------------------------------------------------------
# Configuration Definitions
# ------------------------------------------------------------------------------

# Bootstrap: If run via curl | bash, BASH_SOURCE[0] is unbound.
# We need to clone the repo first because this script relies on local files for symlinking.
if [ -z "${BASH_SOURCE[0]:-}" ]; then
    echo "Running in one-liner mode (piped). Bootstrapping repository..."
    REPO_URL="https://github.com/deey001/dotfiles.git"
    TARGET_DIR="$HOME/dotfiles"
    
    if [ -d "$TARGET_DIR" ]; then
        echo "Target directory $TARGET_DIR already exists. Updating..."
        cd "$TARGET_DIR" && git pull
    else
        echo "Cloning repository to $TARGET_DIR..."
        git clone "$REPO_URL" "$TARGET_DIR"
        cd "$TARGET_DIR"
    fi
    # Relaunch the script from the cloned directory to ensure all paths are correct
    exec bash "$TARGET_DIR/install.sh" "$@"
fi

# Set the directory where the dotfiles are located (absolute path)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Dotfiles directory detected at: $DOTFILES_DIR"

# Create backup directory with timestamp
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

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

# Function: backup_file
# Description: Backs up a file or directory before symlinking.
# Args: $1 - Path to backup
backup_file() {
    local file="$1"
    if [ -e "$file" ] && [ ! -L "$file" ]; then
        echo "Backing up existing file: $file"
        mkdir -p "$BACKUP_DIR"
        # Use -P to preserve attributes, and create parent dirs in backup
        cp -rP "$file" "$BACKUP_DIR/"
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

        echo "Installing packages via Homebrew Bundle..."
        # Use Brewfile for declarative package management
        if [ -f "$DOTFILES_DIR/Brewfile" ]; then
            brew bundle --file="$DOTFILES_DIR/Brewfile"
        else
            echo "Warning: Brewfile not found. Installing packages individually..."
            brew install tmux git fzf neovim starship hstr bat eza ripgrep fd zoxide fastfetch cmatrix btop lazygit glow tldr dust duf procs bottom
            brew install --cask font-jetbrains-mono-nerd-font
        fi
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
            sudo apt install -y curl xz-utils tar unzip build-essential gawk
            
            echo "Installing tools via apt..."
            # Core tools from repositories
            # xclip/wl-clipboard: Used for clipboard integration (copy/paste)
            sudo apt install -y tmux git fzf xclip bash-completion hstr bat cmatrix btop tldr zsh zsh-syntax-highlighting zsh-autosuggestions
            
            # Install Latest Neovim (AppImage/Tarball is better than apt usually)
            echo "Installing Neovim v${NEOVIM_VERSION}..."
            if [ ! -f /usr/local/bin/nvim ]; then
                curl -LO "https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/nvim-linux-x86_64.tar.gz"
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
            GLOW_RELEASE=$(curl -s "https://api.github.com/repos/charmbracelet/glow/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
            curl -Lo glow.deb "https://github.com/charmbracelet/glow/releases/latest/download/glow_${GLOW_RELEASE}_amd64.deb"
            sudo dpkg -i glow.deb
            rm glow.deb

            # Install additional modern tools (ripgrep, dust, procs, bottom, zoxide, eza, duf, fd-find)
            echo "Installing additional modern tools..."
            # Core modern tools from apt (available in Ubuntu repos)
            sudo apt install -y ripgrep fd-find duf

            # zoxide - Smarter cd
            if ! command -v zoxide >/dev/null 2>&1; then
                curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
            fi

            # eza - Modern ls (from binary release)
            if ! command -v eza >/dev/null 2>&1; then
                EZA_VERSION=$(curl -s "https://api.github.com/repos/eza-community/eza/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
                curl -Lo eza.tar.gz "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz"
                sudo tar -xzf eza.tar.gz -C /usr/local/bin
                rm eza.tar.gz
            fi

            # dust - Better du (from binary release, not in Ubuntu repos)
            if ! command -v dust >/dev/null 2>&1; then
                echo "Installing dust..."
                DUST_VERSION=$(curl -s "https://api.github.com/repos/bootandy/dust/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
                curl -Lo dust.tar.gz "https://github.com/bootandy/dust/releases/latest/download/dust-v${DUST_VERSION}-x86_64-unknown-linux-musl.tar.gz"
                tar -xzf dust.tar.gz
                sudo install dust-v${DUST_VERSION}-x86_64-unknown-linux-musl/dust /usr/local/bin/
                rm -rf dust.tar.gz dust-v${DUST_VERSION}-x86_64-unknown-linux-musl
            fi

            # Create fd symlink (Debian/Ubuntu installs fd-find as 'fdfind')
            if command -v fdfind >/dev/null 2>&1 && [ ! -f "$HOME/.local/bin/fd" ]; then
                mkdir -p "$HOME/.local/bin"
                ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
                echo "Created fd symlink at ~/.local/bin/fd"
            fi

            # Clean up Snap (Ubuntu specific optimization for servers)
            if grep -qi "ubuntu" /etc/os-release; then
                echo "Optimizing Ubuntu: Removing snapd..."
                sudo apt purge -y snapd
                sudo apt autoremove -y
                rm -rf "$HOME/snap"
                sudo apt-mark hold snapd
            fi
            
            # Wayland support for clipboard
            if [ -n "${WAYLAND_DISPLAY:-}" ]; then
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
            # Install EPEL for RHEL/CentOS to get more packages
            if grep -qi "centos\|rhel" /etc/redhat-release; then
                sudo $PKG_MANAGER install -y epel-release
            fi

            # Core tools + Build tools for Treesitter
            sudo $PKG_MANAGER install -y git tmux fzf neovim hstr bat fastfetch cmatrix btop lazygit glow tldr ripgrep fd-find unzip gcc gcc-c++ make gawk zsh zsh-syntax-highlighting zsh-autosuggestions

            # Modern tools that may need manual installation
            # zoxide
            if ! command -v zoxide >/dev/null 2>&1; then
                curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
            fi

            # eza (from binary release)
            if ! command -v eza >/dev/null 2>&1; then
                EZA_VERSION=$(curl -s "https://api.github.com/repos/eza-community/eza/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
                curl -Lo eza.tar.gz "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz"
                sudo tar -xzf eza.tar.gz -C /usr/local/bin
                rm eza.tar.gz
            fi

            # dust (from binary release)
            if ! command -v dust >/dev/null 2>&1; then
                DUST_VERSION=$(curl -s "https://api.github.com/repos/bootandy/dust/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
                curl -Lo dust.tar.gz "https://github.com/bootandy/dust/releases/latest/download/dust-v${DUST_VERSION}-x86_64-unknown-linux-musl.tar.gz"
                tar -xzf dust.tar.gz
                sudo install dust-v${DUST_VERSION}-x86_64-unknown-linux-musl/dust /usr/local/bin/
                rm -rf dust.tar.gz dust-v${DUST_VERSION}-x86_64-unknown-linux-musl
            fi

            # duf (from binary release - not in RHEL repos)
            if ! command -v duf >/dev/null 2>&1; then
                DUF_VERSION=$(curl -s "https://api.github.com/repos/muesli/duf/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
                curl -Lo duf.rpm "https://github.com/muesli/duf/releases/latest/download/duf_${DUF_VERSION}_linux_x86_64.rpm"
                sudo rpm -i duf.rpm || sudo $PKG_MANAGER install -y duf.rpm
                rm duf.rpm
            fi

            # Create fd symlink if needed
            if command -v fdfind >/dev/null 2>&1 && [ ! -f "$HOME/.local/bin/fd" ]; then
                mkdir -p "$HOME/.local/bin"
                ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
            fi
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
            # Arch has most modern tools in official repos or AUR
            # base-devel provides compilers (gcc, make, etc) for Treesitter
            sudo pacman -Syu --noconfirm base-devel git tmux fzf neovim eza fastfetch btop ripgrep fd dust duf zoxide unzip gawk zsh zsh-syntax-highlighting zsh-autosuggestions
            
            # These might be in AUR or newly moved to extra, so try them separately
            echo "Attempting to install optional modern tools (hstr, lazygit, glow, tldr, etc)..."
            OPTIONAL_TOOLS=(hstr lazygit glow tldr)
            
            # Detect AUR helper
            AUR_HELPER=""
            if command -v yay >/dev/null 2>&1; then AUR_HELPER="yay"; elif command -v paru >/dev/null 2>&1; then AUR_HELPER="paru"; fi

            for tool in "${OPTIONAL_TOOLS[@]}"; do
                if ! command -v "$tool" >/dev/null 2>&1; then
                    echo "Installing $tool..."
                    if [ -n "$AUR_HELPER" ]; then
                        $AUR_HELPER -S --noconfirm "$tool"
                    else
                        sudo pacman -S --noconfirm "$tool" || echo "Warning: $tool not found in official repositories and no AUR helper (yay/paru) detected."
                    fi
                fi
            done
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
        if [ ! -d "$FONT_DIR/JetBrainsMono" ]; then
            echo "Installing JetBrainsMono Nerd Font..."
            mkdir -p "$FONT_DIR"
            cd "$FONT_DIR"
            curl -fLo JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
            unzip -q -o JetBrainsMono.zip -d JetBrainsMono
            rm JetBrainsMono.zip
            cd - > /dev/null
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
    # Remove existing ble.sh dir if it exists from a failed attempt
    rm -rf ble.sh
    git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git
    # On macOS, brew installs gawk to /opt/homebrew/bin/gawk usually.
    # We ensure it's in the path for the build.
    make -C ble.sh install PREFIX=~/.local
    rm -rf ble.sh
fi

# Base16 Shell - Color Themes
if [ "$IS_ONLINE" = true ] && [ ! -d "$HOME/.config/base16-shell" ]; then
    echo "Cloning base16-shell for color themes..."
    rm -rf "$HOME/.config/base16-shell"
    git clone https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell
fi

# Tmux Plugin Manager (TPM)
if [ "$IS_ONLINE" = true ] && [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "Cloning Tmux Plugin Manager..."
    rm -rf "$HOME/.tmux/plugins/tpm"
    mkdir -p "$HOME/.tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# ------------------------------------------------------------------------------
# Dotfiles Symlinking & Setup
# ------------------------------------------------------------------------------

echo "Creating symlinks for dotfiles..."
# Links the source files from the git repo to the home directory
# Backup existing configs before creating symlinks
backup_file "$HOME/.bash_aliases"
backup_file "$HOME/.bash_exports"
backup_file "$HOME/.bash_functions"
backup_file "$HOME/.bash_profile"
backup_file "$HOME/.bash_wrappers"
backup_file "$HOME/.bashrc"
backup_file "$HOME/.zshrc"
backup_file "$HOME/.tmux.conf"
backup_file "$HOME/.blerc"
backup_file "$HOME/.inputrc"
backup_file "$HOME/.gitconfig"

# -f forces the link, -s makes it symbolic
ln -sf "$DOTFILES_DIR/.bash_aliases" "$HOME/.bash_aliases"
ln -sf "$DOTFILES_DIR/.bash_exports" "$HOME/.bash_exports"
ln -sf "$DOTFILES_DIR/.bash_functions" "$HOME/.bash_functions"
ln -sf "$DOTFILES_DIR/.bash_profile" "$HOME/.bash_profile"
ln -sf "$DOTFILES_DIR/.bash_wrappers" "$HOME/.bash_wrappers"
ln -sf "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
ln -sf "$DOTFILES_DIR/.blerc" "$HOME/.blerc"
ln -sf "$DOTFILES_DIR/.inputrc" "$HOME/.inputrc"
ln -sf "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"

# Config directory setups
mkdir -p "$HOME/.config"
ln -sf "$DOTFILES_DIR/.config/starship.toml" "$HOME/.config/starship.toml"

# Alacritty Setup
mkdir -p "$HOME/.config/alacritty"
ln -sf "$DOTFILES_DIR/.config/alacritty/alacritty.yml" "$HOME/.config/alacritty/alacritty.yml"

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

# Run Neovim health check if online
if [ "$IS_ONLINE" = true ] && command -v nvim >/dev/null 2>&1; then
    echo "Syncing Neovim plugins (Internet required)..."
    # --headless "+Lazy! sync" +qa
    # Using 'sync' instead of 'checkhealth' to pre-install everything
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || echo "Plugin sync completed."
fi

# Fastfetch Config
mkdir -p "$HOME/.config/fastfetch"
ln -sf "$DOTFILES_DIR/.config/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"

# SSH Config Template
if [ ! -d "$HOME/.ssh" ]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
fi
if [ -f "$DOTFILES_DIR/.ssh/config" ]; then
    backup_file "$HOME/.ssh/config"
    ln -sf "$DOTFILES_DIR/.ssh/config" "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"
fi

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

# Reload Bash Profile
source "$HOME/.bash_profile" 2>/dev/null || true

echo "=============================================================================="
echo "Installation Complete!"
echo "Notes:"
echo "1. Restart your terminal or run 'exec bash' to apply changes."
echo "2. If using Tmux, press 'prefix + I' to install plugins."
echo "3. For machine-specific settings, create ~/.bash_local (auto-sourced)"
if [ -d "$BACKUP_DIR" ]; then
    echo "4. Existing configs backed up to: $BACKUP_DIR"
fi
if [ "$IS_ONLINE" = false ]; then
    echo "Warning: Installation completed in OFFLINE mode. Some tools/fonts may be missing."
fi
echo "=============================================================================="

# Reload the shell to apply changes immediately
echo "Reloading shell..."
exec $SHELL -l
