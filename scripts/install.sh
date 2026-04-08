#!/bin/bash
# ==============================================================================
# install.sh — Simplified "One-Liner" Dotfiles Bootstrapper
# ==============================================================================

# 1. Determine if we are running from a local clone or piped from curl
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]] || [[ "${BASH_SOURCE[0]:-}" == "" ]]; then
    DOTFILES_DIR="$HOME/dotfiles"
    if [ ! -d "$DOTFILES_DIR" ]; then
        echo "--- Cloning dotfiles repository... ---"
        git clone https://github.com/deey001/dotfiles.git "$DOTFILES_DIR"
    fi
else
    DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

set -euo pipefail

# 2. Environment Detection
ARCH=$(uname -m)
OS_RAW="$(uname)"

case "$OS_RAW" in
    Darwin)         OS="Darwin" ;;
    Linux)          OS="Linux" ;;
    MINGW*|MSYS*|CYGWIN*) OS="Windows" ;;
    *)              OS="Unknown" ;;
esac

# 3. Helper Functions
install_package_list() {
    local list_file="$1"
    local install_cmd="$2"
    if [ ! -f "$list_file" ]; then return 1; fi
    echo "--- Installing system dependencies from $(basename "$list_file") ---"
    local pkgs
    pkgs=$(grep -v '^#' "$list_file" | grep -v '^$' | tr '\n' ' ')
    if [ -n "$pkgs" ]; then $install_cmd $pkgs; fi
}

# 4. System Package Installation
if [ "$OS" = "Darwin" ]; then
    echo "--- Detected macOS ---"
    command -v brew &>/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    [ -f "$DOTFILES_DIR/Brewfile" ] && brew bundle --file="$DOTFILES_DIR/Brewfile"
elif [ "$OS" = "Linux" ]; then
    if [ -f /etc/debian_version ]; then
        echo "--- Detected Debian/Ubuntu ---"
        sudo apt update
        install_package_list "$DOTFILES_DIR/meta/packages/ubuntu.txt" "sudo apt install -y"
        # Add Neovim from repo (will install latest available in apt)
        sudo apt install -y neovim
    elif [ -f /etc/arch-release ]; then
        echo "--- Detected Arch Linux ---"
        install_package_list "$DOTFILES_DIR/meta/packages/arch.txt" "sudo pacman -Syu --noconfirm"
    elif [ -f /etc/redhat-release ]; then
        echo "--- Detected RHEL/Fedora/CentOS ---"
        if command -v dnf &>/dev/null; then
            install_package_list "$DOTFILES_DIR/meta/packages/rhel.txt" "sudo dnf install -y"
        else
            install_package_list "$DOTFILES_DIR/meta/packages/rhel.txt" "sudo yum install -y"
        fi
    fi
fi

# 5. GNU Stow (The Linker)
command -v stow &>/dev/null || {
    echo "Installing GNU Stow..."
    [ -f /etc/debian_version ] && sudo apt install -y stow
    [ -f /etc/arch-release ] && sudo pacman -S --noconfirm stow
    [ -f /etc/redhat-release ] && { command -v dnf &>/dev/null && sudo dnf install -y stow || sudo yum install -y stow; }
}

echo "--- Symlinking Configurations via GNU Stow ---"
STOW_PKGS=(bash zsh git shell tmux config)

cd "$DOTFILES_DIR"
for pkg in "${STOW_PKGS[@]}"; do
    echo "  Stowing: $pkg"
    stow -R --dir=stow --target="$HOME" "$pkg"
done

echo "======================================================================"
echo "INSTALLATION PROCESS FINISHED!"
echo "======================================================================"
