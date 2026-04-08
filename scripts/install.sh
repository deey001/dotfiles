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
#
# HOW: 1. Detects OS and Architecture.
#      2. Installs system dependencies from meta/packages/*.txt.
#      3. Downloads latest binaries for tools not in system repos (Neovim).
#      4. Uses GNU Stow to link configuration files into your home directory.
# ==============================================================================
set -euo pipefail

# ── 1. Configuration & Versions ──────────────────────────────────────────────
# Pinned versions ensure that the "One-Liner" install is reproducible and
# won't break if an upstream project releases a buggy update.
NEOVIM_VERSION="0.11.6"
STARSHIP_VERSION="1.23.0"
LAZYGIT_VERSION="0.48.0"
BASH_COMPLETION_VERSION="2.12.0"

# ── 2. Environment Detection ─────────────────────────────────────────────────
ARCH=$(uname -m)
OS="$(uname)"
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_cleanup_dirs=()
trap 'for dir in "${_cleanup_dirs[@]}"; do rm -rf "$dir"; done' EXIT

case "$ARCH" in
    x86_64)         NVIM_ARCH="x86_64" ;;
    aarch64|arm64)  NVIM_ARCH="arm64" ;;
    *)              NVIM_ARCH="x86_64" ;;
esac

# ── 3. Helper Functions ───────────────────────────────────────────────────────
# install_package_list: Reads a distro-specific .txt file and passes it to
# the system package manager. This keeps the logic separate from the data.
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
fi

# ── 5. GNU Stow (The Linker) ──────────────────────────────────────────────────
# Stow creates symlinks in $HOME that point back to ~/dotfiles/stow/.
# This allows you to edit files in the repo and have them update instantly.
command -v stow &>/dev/null || {
    echo "Installing GNU Stow..."
    [ -f /etc/debian_version ] && sudo apt install -y stow
    [ -f /etc/arch-release ] && sudo pacman -S --noconfirm stow
}

echo "--- Symlinking Configurations via GNU Stow ---"
STOW_PKGS=(bash zsh git shell tmux config)
# Only stow GUI configs if we are on a desktop environment
# (Note: wezterm is now part of 'config', but we keep this check for logic clarity if needed later)


cd "$DOTFILES_DIR"
for pkg in "${STOW_PKGS[@]}"; do
    echo "  Stowing: $pkg"
    stow -R --dir=stow --target="$HOME" "$pkg"
done

echo "======================================================================"
echo "INSTALLATION COMPLETE!"
echo "Please restart your shell or run: source ~/.bashrc"
echo "======================================================================"
