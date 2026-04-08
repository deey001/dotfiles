#!/bin/bash
# ==============================================================================
# install.sh — The "One-Liner" Dotfiles Bootstrapper
# ==============================================================================
# WHY: This script provides a single, automated entry point to transform a
#      fresh OS install into a fully-configured development environment.
#
# WHERE: Installs tools to /usr/bin (via system pkg managers) and ~/.local/bin.
#        Symlinks configs from ~/dotfiles/stow/ into $HOME.
#
# WHEN: Run this on any new machine, or after pulling changes to the repo.
#       It is safe to run multiple times (idempotent).
# HOW: 1. Detects OS and Architecture.
#      2. Installs system dependencies from meta/packages/*.txt.
#      3. Downloads latest binaries for tools not in system repos (Neovim).
#      4. Uses GNU Stow to link configuration files into your home directory.
# ==============================================================================

# Determine if we are running from a local clone or piped from curl
# We do this before 'set -u' to avoid "unbound variable" errors
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]] || [[ "${BASH_SOURCE[0]:-}" == "" ]]; then
    # Script is being piped to bash (e.g., curl | bash) or run directly
    DOTFILES_DIR="$HOME/dotfiles"
    if [ ! -d "$DOTFILES_DIR" ]; then
        echo "--- Dotfiles repository not found at $DOTFILES_DIR. Cloning... ---"
        git clone https://github.com/deey001/dotfiles.git "$DOTFILES_DIR"
    fi
else
    # Script is being sourced or run from a local clone
    DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

ARCH=$(uname -m)
OS_RAW="$(uname)"

set -euo pipefail

# ── 1. Configuration & Versions ──────────────────────────────────────────────
NEOVIM_VERSION="0.11.6"
STARSHIP_VERSION="1.23.0"
LAZYGIT_VERSION="0.48.0"
BASH_COMPLETION_VERSION="2.12.0"

# Normalize OS string
case "$OS_RAW" in
    Darwin)         OS="Darwin" ;;
    Linux)          OS="Linux" ;;
    MINGW*|MSYS*|CYGWIN*) OS="Windows" ;;
    *)              OS="Unknown" ;;
esac

case "$ARCH" in
    x86_64)         NVIM_ARCH="x86_64" ;;
    aarch64|arm64)  NVIM_ARCH="arm64" ;;
    *)              NVIM_ARCH="x86_64" ;;
esac

_cleanup_dirs=()
trap 'for dir in "${_cleanup_dirs[@]}"; do rm -rf "$dir"; done' EXIT

# ── 3. Helper Functions ───────────────────────────────────────────────────────
install_package_list() {
    local list_file="$1"
    local install_cmd="$2"
    if [ ! -f "$list_file" ]; then
        echo "Error: Package list $list_file missing!"
        return 1
    fi
    echo "--- Installing system dependencies from $(basename "$list_file") ---"
    local pkgs
    pkgs=$(grep -v '^#' "$list_file" | grep -v '^$' | tr '\n' ' ')
    if [ -n "$pkgs" ]; then
        $install_cmd $pkgs
    fi
}

# ── 4. System Package Installation ────────────────────────────────────────────
if [ "$OS" = "Darwin" ]; then
    echo "--- Detected macOS ---"
    command -v brew &>/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    [ -f "$DOTFILES_DIR/Brewfile" ] && brew bundle --file="$DOTFILES_DIR/Brewfile"
elif [ "$OS" = "Linux" ]; then
    if [ -f /etc/debian_version ]; then
        echo "--- Detected Debian/Ubuntu ---"
        sudo apt update
        install_package_list "$DOTFILES_DIR/meta/packages/ubuntu.txt" "sudo apt install -y"
        
        # Neovim (Manual Install because Apt version is usually ancient)
        if [ ! -f "$HOME/.local/bin/nvim" ] || ! "$HOME/.local/bin/nvim" --version | grep -q "v${NEOVIM_VERSION}"; then
            echo "--- Installing Neovim v${NEOVIM_VERSION} ---"
            _tmp=$(mktemp -d); _cleanup_dirs+=("$_tmp")
            curl -fsSL "https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/nvim-linux-${NVIM_ARCH}.tar.gz" -o "$_tmp/nvim.tar.gz"
            tar -xzf "$_tmp/nvim.tar.gz" -C "$_tmp"
            mkdir -p "$HOME/.local/bin"
            rm -rf "$HOME/.local/nvim-linux"
            mv "$_tmp/nvim-linux-${NVIM_ARCH}" "$HOME/.local/nvim-linux"
            ln -sf "$HOME/.local/nvim-linux/bin/nvim" "$HOME/.local/bin/nvim"
        fi
    elif [ -f /etc/arch-release ]; then
        echo "--- Detected Arch Linux ---"
        install_package_list "$DOTFILES_DIR/meta/packages/arch.txt" "sudo pacman -Syu --noconfirm"
    fi
elif [ "$OS" = "Windows" ]; then
    echo "--- Detected Windows (Git Bash/MSYS) ---"
    echo "Running in Windows Bash environment. Only stowing configurations."
    echo "Use scripts/install.ps1 in PowerShell for full Windows local setup (fonts, tools)."
fi

# ── 5. GNU Stow (The Linker) ──────────────────────────────────────────────────
if command -v stow &>/dev/null; then
    echo "--- Symlinking Configurations via GNU Stow ---"
    STOW_PKGS=(bash zsh git shell tmux config)
    
    cd "$DOTFILES_DIR"
    for pkg in "${STOW_PKGS[@]}"; do
        echo "  Stowing: $pkg"
        stow -R --dir=stow --target="$HOME" "$pkg"
    done
else
    echo "Warning: GNU Stow not found. Skipping configuration symlinking."
    if [ "$OS" = "Windows" ]; then
        echo "Tip: You can install stow on Windows via 'pacman -S stow' in Git Bash / MSYS2."
    fi
fi

echo "======================================================================"
echo "INSTALLATION PROCESS FINISHED!"
echo "Please restart your shell or run: source ~/.bashrc"
echo "======================================================================"
