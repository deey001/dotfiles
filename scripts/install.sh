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

NEOVIM_VERSION="0.11.6"
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
        echo "Target directory $TARGET_DIR already exists. Syncing with remote..."
        cd "$TARGET_DIR"
        git fetch --all
        git reset --hard origin/master
        git clean -fd
    else
        echo "Cloning repository to $TARGET_DIR..."
        git clone "$REPO_URL" "$TARGET_DIR"
        cd "$TARGET_DIR"
    fi
    # Relaunch the script from the cloned directory to ensure all paths are correct
    exec bash "$TARGET_DIR/scripts/install.sh" "$@"
fi

# Set the directory where the dotfiles are located (absolute path)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Dotfiles directory detected at: $DOTFILES_DIR"

# Architecture Detection
ARCH=$(uname -m)
OS_TYPE=$(uname -s)
echo "Detected Architecture: $ARCH ($OS_TYPE)"

# Map common architectures to tool-specific strings
case "$ARCH" in
    x86_64)
        NVIM_ARCH="x86_64"
        LAZYGIT_ARCH="x86_64"
        GLOW_ARCH="amd64"
        EZA_ARCH="x86_64-unknown-linux-gnu"
        DUST_ARCH="x86_64-unknown-linux-musl"
        DUF_ARCH="x86_64"
        ;;
    aarch64|arm64)
        NVIM_ARCH="arm64"
        LAZYGIT_ARCH="arm64"
        GLOW_ARCH="arm64"
        EZA_ARCH="aarch64-unknown-linux-gnu"
        DUST_ARCH="aarch64-unknown-linux-musl"
        DUF_ARCH="arm64"
        ;;
    *)
        echo "Warning: Unsupported architecture $ARCH. Tool installations may fail."
        NVIM_ARCH="x86_64"
        LAZYGIT_ARCH="x86_64"
        GLOW_ARCH="amd64"
        EZA_ARCH="x86_64-unknown-linux-gnu"
        DUST_ARCH="x86_64-unknown-linux-musl"
        DUF_ARCH="x86_64"
        ;;
esac

# Create backup directory with timestamp
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# ------------------------------------------------------------------------------
# Shell Detection
# ------------------------------------------------------------------------------
# Detect the user's active login shell and set flags for conditional setup.
# Both shells get configs symlinked, but only the active shell's dependencies
# are prioritized during package installation.

USER_SHELL="$(basename "$SHELL")"
case "$USER_SHELL" in
    zsh)  ACTIVE_SHELL="zsh"  ;;
    bash) ACTIVE_SHELL="bash" ;;
    *)    ACTIVE_SHELL="bash" ;;  # Default to bash for unknown shells
esac
echo "Detected active shell: $ACTIVE_SHELL ($SHELL)"

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
if [ -f "$DOTFILES_DIR/stow/bash/.bashrc" ]; then
    if ! bash -c ". '$DOTFILES_DIR/stow/bash/.bashrc' 2>/dev/null"; then
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
            brew install tmux git fzf neovim starship hstr carapace bat eza ripgrep fd zoxide fastfetch cmatrix btop lazygit glow tldr dust duf procs bottom
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
            echo "Updating apt and enabling universe repository..."
            # Enable universe repository (often needed for build-essential/bzip2 on minimal images)
            if command -v add-apt-repository >/dev/null 2>&1; then
                sudo add-apt-repository -y universe
            elif grep -qi "ubuntu" /etc/os-release; then
                # Fallback for minimal images without add-apt-repository
                sudo sed -i 's/main$/main universe/' /etc/apt/sources.list || true
            fi
            
            sudo apt update
            
            # 1. Install individual compiler tools first (these usually don't have dependency issues)
            echo "Installing individual compiler tools..."
            CORE_TOOLS=(make gcc g++ gawk curl xz-utils tar unzip)
            for pkg in "${CORE_TOOLS[@]}"; do
                if dpkg -s "$pkg" >/dev/null 2>&1; then
                    echo "Prerequisite $pkg is already installed."
                else
                    echo "Installing $pkg..."
                    sudo apt install -y "$pkg" || echo "Warning: Failed to install $pkg."
                fi
            done

            # 2. Try to install the meta-packages (may fail on minimal images, but we have the tools now)
            echo "Attempting to install meta-packages..."
            META_PKGS=(bzip2 build-essential)
            for pkg in "${META_PKGS[@]}"; do
                if dpkg -s "$pkg" >/dev/null 2>&1; then
                    echo "$pkg is already installed."
                else
                    echo "Installing $pkg..."
                    sudo apt install -y "$pkg" || echo "Warning: Optional $pkg failed (continuing as core tools are present)."
                fi
            done
            
            # Attempt to fix broken dependencies if any occurred
            sudo apt install -f -y
            
            echo "Installing tools via apt..."
            # Core tools (shell-agnostic)
            sudo apt install -y tmux git fzf xclip hstr bat cmatrix btop tldr ncurses-term

            # Shell-specific packages
            if [ "$ACTIVE_SHELL" = "bash" ]; then
                echo "Active shell is Bash — installing bash-completion..."
                sudo apt install -y bash-completion
                echo "Zsh plugins will also be installed for secondary shell support..."
                sudo apt install -y zsh zsh-syntax-highlighting zsh-autosuggestions 2>/dev/null || true
            else
                echo "Active shell is Zsh — installing zsh plugins..."
                sudo apt install -y zsh zsh-syntax-highlighting zsh-autosuggestions
                echo "Bash completion will also be installed for secondary shell support..."
                sudo apt install -y bash-completion 2>/dev/null || true
            fi
            
            # Install Latest Neovim (AppImage/Tarball is better than apt usually)
            echo "Installing Neovim v${NEOVIM_VERSION} for ${NVIM_ARCH}..."
            # Force clean up existing binary if it's the wrong architecture
            if [ -f /usr/local/bin/nvim ]; then
                if ! file /usr/local/bin/nvim | grep -qi "$ARCH" && ! file /usr/local/bin/nvim | grep -qi "ARM64" ; then
                    echo "Existing Neovim binary is wrong architecture. Removing..."
                    sudo rm -f /usr/local/bin/nvim
                    sudo rm -rf /usr/local/nvim-linux-*
                fi
            fi

            if [ ! -f /usr/local/bin/nvim ] || ! nvim --version 2>/dev/null | grep -q "^NVIM v${NEOVIM_VERSION}"; then
                echo "Installing/upgrading Neovim to v${NEOVIM_VERSION}..."
                rm -f "nvim-linux-${NVIM_ARCH}.tar.gz"
                rm -rf "nvim-linux-${NVIM_ARCH}"
                
                curl -LO "https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/nvim-linux-${NVIM_ARCH}.tar.gz"
                sudo tar -C /usr/local -xzf "nvim-linux-${NVIM_ARCH}.tar.gz"
                sudo ln -sf "/usr/local/nvim-linux-${NVIM_ARCH}/bin/nvim" /usr/local/bin/nvim
                rm "nvim-linux-${NVIM_ARCH}.tar.gz"
            fi
            
            # Install fastfetch from PPA (Better formatting than neofetch)
            echo "Installing fastfetch..."
            sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
            sudo apt update
            sudo apt install -y fastfetch
            
            # Install lazygit (Git TUI)
            echo "Installing lazygit..."
            LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
            curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz"
            tar xf lazygit.tar.gz lazygit
            sudo install lazygit /usr/local/bin
            rm lazygit lazygit.tar.gz
            
            # Install glow (Markdown Viewer)
            echo "Installing glow..."
            GLOW_RELEASE=$(curl -s "https://api.github.com/repos/charmbracelet/glow/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
            curl -Lo glow.deb "https://github.com/charmbracelet/glow/releases/latest/download/glow_${GLOW_RELEASE}_${GLOW_ARCH}.deb"
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
                curl -Lo eza.tar.gz "https://github.com/eza-community/eza/releases/latest/download/eza_${EZA_ARCH}.tar.gz"
                sudo tar -xzf eza.tar.gz -C /usr/local/bin
                rm eza.tar.gz
            fi

            # dust - Better du (from binary release, not in Ubuntu repos)
            if ! command -v dust >/dev/null 2>&1; then
                echo "Installing dust..."
                DUST_VERSION=$(curl -s "https://api.github.com/repos/bootandy/dust/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
                curl -Lo dust.tar.gz "https://github.com/bootandy/dust/releases/latest/download/dust-v${DUST_VERSION}-${DUST_ARCH}.tar.gz"
                tar -xzf dust.tar.gz
                sudo install "dust-v${DUST_VERSION}-${DUST_ARCH}/dust" /usr/local/bin/
                rm -rf dust.tar.gz "dust-v${DUST_VERSION}-${DUST_ARCH}"
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
            sudo $PKG_MANAGER install -y git tmux fzf neovim hstr bat fastfetch cmatrix btop lazygit glow tldr ripgrep fd-find unzip gcc gcc-c++ make gawk

            # Shell-specific packages
            if [ "$ACTIVE_SHELL" = "bash" ]; then
                echo "Active shell is Bash — zsh plugins installed as secondary..."
                sudo $PKG_MANAGER install -y zsh zsh-syntax-highlighting zsh-autosuggestions 2>/dev/null || true
            else
                echo "Active shell is Zsh — installing zsh plugins..."
                sudo $PKG_MANAGER install -y zsh zsh-syntax-highlighting zsh-autosuggestions
            fi

            # Modern tools that may need manual installation
            # zoxide
            if ! command -v zoxide >/dev/null 2>&1; then
                curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
            fi

            # eza (from binary release)
            if ! command -v eza >/dev/null 2>&1; then
                EZA_VERSION=$(curl -s "https://api.github.com/repos/eza-community/eza/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
                curl -Lo eza.tar.gz "https://github.com/eza-community/eza/releases/latest/download/eza_${EZA_ARCH}.tar.gz"
                sudo tar -xzf eza.tar.gz -C /usr/local/bin
                rm eza.tar.gz
            fi

            # dust (from binary release)
            if ! command -v dust >/dev/null 2>&1; then
                DUST_VERSION=$(curl -s "https://api.github.com/repos/bootandy/dust/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
                curl -Lo dust.tar.gz "https://github.com/bootandy/dust/releases/latest/download/dust-v${DUST_VERSION}-${DUST_ARCH}.tar.gz"
                tar -xzf dust.tar.gz
                sudo install "dust-v${DUST_VERSION}-${DUST_ARCH}/dust" /usr/local/bin/
                rm -rf dust.tar.gz "dust-v${DUST_VERSION}-${DUST_ARCH}"
            fi

            # duf (from binary release - not in RHEL repos)
            if ! command -v duf >/dev/null 2>&1; then
                DUF_VERSION=$(curl -s "https://api.github.com/repos/muesli/duf/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
                curl -Lo duf.rpm "https://github.com/muesli/duf/releases/latest/download/duf_${DUF_VERSION}_linux_${DUF_ARCH}.rpm"
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
            sudo pacman -Syu --noconfirm base-devel git tmux fzf neovim eza fastfetch btop ripgrep fd dust duf zoxide unzip gawk

            # Shell-specific packages
            if [ "$ACTIVE_SHELL" = "bash" ]; then
                echo "Active shell is Bash — zsh plugins installed as secondary..."
                sudo pacman -S --noconfirm zsh zsh-syntax-highlighting zsh-autosuggestions 2>/dev/null || true
            else
                echo "Active shell is Zsh — installing zsh plugins..."
                sudo pacman -S --noconfirm zsh zsh-syntax-highlighting zsh-autosuggestions
            fi
            
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

    # Carapace - Multi-shell completion engine
    # --------------------------------------------------------------------------
    if [ "$IS_ONLINE" = true ]; then
        if ! command -v carapace >/dev/null 2>&1; then
            echo "Installing Carapace (multi-shell completions)..."
            CARAPACE_VERSION=$(curl -s https://api.github.com/repos/carapace-sh/carapace-bin/releases/latest | grep '"tag_name"' | sed 's/.*"v\(.*\)".*/\1/')
            if [ -n "$CARAPACE_VERSION" ]; then
                CARAPACE_ARCH="$ARCH"
                [ "$CARAPACE_ARCH" = "x86_64" ] && CARAPACE_ARCH="amd64"
                [ "$CARAPACE_ARCH" = "aarch64" ] && CARAPACE_ARCH="arm64"
                curl -fsSL "https://github.com/carapace-sh/carapace-bin/releases/download/v${CARAPACE_VERSION}/carapace-bin_${CARAPACE_VERSION}_linux_${CARAPACE_ARCH}.tar.gz" | tar xz -C /tmp
                sudo mv /tmp/carapace /usr/local/bin/carapace
                echo "Carapace v${CARAPACE_VERSION} installed."
            else
                echo "Warning: Could not determine latest carapace version. Skipping."
            fi
        fi
    fi

    # Atuin - Magical Shell History
    # --------------------------------------------------------------------------
    if [ "$IS_ONLINE" = true ]; then
        if ! command -v atuin >/dev/null 2>&1; then
            echo "Installing Atuin (shell history)..."
            curl --proto '=https' --tlsv1.2 -fsSL https://setup.atuin.sh | bash 2>/dev/null || echo "Warning: Atuin install failed. Install manually: https://docs.atuin.sh"
        fi
    fi
    
else
    echo "Unsupported OS: $OS"
    exit 1
fi

# ------------------------------------------------------------------------------
# Helper Tool Installation (ble.sh, TPM)
# ------------------------------------------------------------------------------

# ble.sh — build from master source (nightly tarball was stale/broken)
if [ "$IS_ONLINE" = true ] && command -v bash >/dev/null 2>&1 && command -v make >/dev/null 2>&1; then
    if [ ! -f "$HOME/.local/share/blesh/ble.sh" ]; then
        echo "Installing ble.sh from source..."
        bash "$(dirname "$0")/install-blesh.sh" || echo "Warning: ble.sh install failed, skipping."
    fi
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

# ------------------------------------------------------------------------------
# Dotfiles Symlinking via GNU Stow
# ------------------------------------------------------------------------------

# Install stow if not present
if ! command -v stow &>/dev/null; then
    echo "Installing GNU Stow..."
    if [ "$OS" = "Darwin" ]; then
        brew install stow
    elif command -v apt &>/dev/null; then
        sudo apt install -y stow
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y stow
    elif command -v yum &>/dev/null; then
        sudo yum install -y stow
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm stow
    else
        echo "ERROR: Cannot install stow automatically. Install it manually and re-run."
        exit 1
    fi
fi

echo "Stowing dotfiles..."
echo "Active shell: $ACTIVE_SHELL"

# Backup any real (non-symlink) files that would conflict with stow
# stow's dry-run detects conflicts; we back them up first
for dotfile in .bashrc .bash_profile .bash_aliases .bash_exports .bash_functions \
               .bash_wrappers .blerc .zshrc .tmux.conf .inputrc .gitconfig .editorconfig; do
    if [ -f "$HOME/$dotfile" ] && [ ! -L "$HOME/$dotfile" ]; then
        echo "Backing up existing file: $HOME/$dotfile"
        mkdir -p "$BACKUP_DIR"
        cp -P "$HOME/$dotfile" "$BACKUP_DIR/"
        rm "$HOME/$dotfile"
    fi
done

# Core packages — deployed to all machines (servers + workstations)
STOW_PKGS=(bash zsh git shell tmux nvim starship bat atuin fastfetch)

# Workstation-only packages — skip on headless servers
if [ "$OS" = "Darwin" ] || [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
    STOW_PKGS+=(alacritty)
fi

echo "Packages: ${STOW_PKGS[*]}"

# --restow = unstow then stow (removes stale symlinks, safe for re-runs)
# .stowrc provides: --dir=stow --target=~ --no-folding
cd "$DOTFILES_DIR"
stow --restow "${STOW_PKGS[@]}"

# Rebuild bat theme cache after themes dir is symlinked
if command -v bat &>/dev/null; then
    bat cache --build
elif command -v batcat &>/dev/null; then
    batcat cache --build
fi

# Ensure tmux scripts are executable (stow preserves permissions but be explicit)
chmod +x "$DOTFILES_DIR/stow/tmux/.config/tmux/scripts/"*.sh

echo "Symlinks created via GNU Stow."

# SSH Config (handled separately — symlinks in .ssh/ can cause permission issues)
if [ ! -d "$HOME/.ssh" ]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
fi
if [ ! -d "$HOME/.ssh/sockets" ]; then
    mkdir -p "$HOME/.ssh/sockets"
    chmod 700 "$HOME/.ssh/sockets"
fi
if [ -f "$DOTFILES_DIR/.ssh/config" ]; then
    if [ -f "$HOME/.ssh/config" ] && [ ! -L "$HOME/.ssh/config" ]; then
        mkdir -p "$BACKUP_DIR"
        cp "$HOME/.ssh/config" "$BACKUP_DIR/ssh_config"
    fi
    ln -sf "$DOTFILES_DIR/.ssh/config" "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"
fi

# ------------------------------------------------------------------------------
# SSH Key Installation
# ------------------------------------------------------------------------------
SSH_KEY_SOURCE="$DOTFILES_DIR/.ssh/MDC_public.pub"
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

# Reload active shell profile
if [ "$ACTIVE_SHELL" = "bash" ]; then
    source "$HOME/.bash_profile" 2>/dev/null || true
fi

echo "=============================================================================="
echo "Installation Complete!"
echo "Notes:"
echo "1. Restart your terminal or run 'exec $ACTIVE_SHELL' to apply changes."
echo "2. If using Tmux, press 'prefix + I' to install plugins."
echo "3. For machine-specific settings, create ~/.bash_local (auto-sourced)"
if [ -d "$BACKUP_DIR" ]; then
    echo "4. Existing configs backed up to: $BACKUP_DIR"
fi
if [ "$IS_ONLINE" = false ]; then
    echo "Warning: Installation completed in OFFLINE mode. Some tools/fonts may be missing."
fi
echo "=============================================================================="

echo "INSTALLATION COMPLETE!"
echo ""
if [ "$(uname)" = "Darwin" ]; then
    echo "NOTICE FOR macOS USERS:"
    echo "Terminal.app does not allow automatic font changes via scripts."
    echo "To see icons, you MUST manually set the font:"
    echo "  1. Open Terminal Settings (Cmd + ,)"
    echo "  2. Go to Profiles -> Text -> Font"
    echo "  3. Click 'Change' and select 'JetBrainsMono Nerd Font'"
    echo ""
fi
echo "To apply shell changes immediately, please RESTART your terminal or run:"
if [ "$ACTIVE_SHELL" = "zsh" ]; then
    echo "  source ~/.zshrc   (active shell)"
    echo "  bash              (to switch to Bash temporarily)"
else
    echo "  source ~/.bashrc  (active shell)"
    echo "  zsh               (to switch to Zsh temporarily)"
fi
echo ""
echo "If icons are not showing, ensure your Terminal is set to use 'JetBrainsMono Nerd Font'."
echo "=============================================================================="
