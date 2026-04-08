#!/bin/bash
# ==============================================================================
# uninstall.sh — Dotfiles Removal & Cleanup
# ==============================================================================
# WHY: This script reverses the actions of install.sh. Use it if you want to
#      stop using these dotfiles or if you are preparing a machine for decommissioning.
#
# WHERE: Removes symlinks from $HOME. Does NOT delete the ~/dotfiles repository.
#
# WHEN: Run this before deleting the dotfiles folder or when switching to a
#       different dotfiles manager.
#
# HOW: 1. Uses GNU Stow's "delete" (-D) flag to safely remove managed symlinks.
#      2. Manually scrubs any lingering symlinks defined in the cleanup list.
#      3. Reverts the system back to its original state (shell-wise).
# ==============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo -e "${YELLOW}Target Dotfiles Directory:${NC} $DOTFILES_DIR"

# ── 1. Unstow Packages ───────────────────────────────────────────────────────
# This is the safest way to remove the dotfiles. Stow will only remove the
# links it created, leaving your actual files and other manual links alone.
if command -v stow &>/dev/null; then
    echo "--- Unstowing all packages via GNU Stow ---"
    # Core dotfile packages
    STOW_PKGS=(bash zsh git shell tmux config)
    for pkg in "${STOW_PKGS[@]}"; do
        echo "  Unstowing: $pkg"
        stow -D --dir="$DOTFILES_DIR/stow" --target="$HOME" "$pkg" 2>/dev/null || true
    done
    # Theme packages — only one is typically stowed at a time; try both to be safe
    for theme_pkg in theme-catppuccin-mocha theme-catppuccin-latte; do
        if stow --no --dir="$DOTFILES_DIR/stow" --target="$HOME" "$theme_pkg" 2>/dev/null; then
            echo "  Unstowing: $theme_pkg"
            stow -D --dir="$DOTFILES_DIR/stow" --target="$HOME" "$theme_pkg" 2>/dev/null || true
        fi
    done
else
    echo -e "${RED}Warning:${NC} GNU Stow not found. Falling back to manual cleanup."
fi

# ── 2. Manual Scrutiny ───────────────────────────────────────────────────────
# We explicitly list key files to ensure no broken symlinks are left behind
# if Stow was partially successful or if manual links were created.
echo "--- Cleaning up lingering symlinks in $HOME ---"
_symlinks=(
    "$HOME/.bashrc" 
    "$HOME/.bash_profile" 
    "$HOME/.bash_aliases"
    "$HOME/.blerc" 
    "$HOME/.zshrc" 
    "$HOME/.tmux.conf" 
    "$HOME/.inputrc"
    "$HOME/.gitconfig" 
    "$HOME/.common_shell"
    "$HOME/.config/starship.toml"
    "$HOME/.config/dotfiles/theme.sh"   # active theme selector (stowed by theme-* package)
)

for link in "${_symlinks[@]}"; do
    if [ -L "$link" ]; then
        rm -f "$link"
        echo -e "  ${GREEN}✓${NC} Removed symlink: $link"
    fi
done

echo "======================================================================"
echo "UNINSTALLATION COMPLETE!"
echo "Note: System packages (like tmux, git) and the ~/dotfiles folder"
echo "were preserved. You can delete the repo folder manually if desired."
echo "======================================================================"
