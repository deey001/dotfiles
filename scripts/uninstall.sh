#!/bin/bash
# ==============================================================================
# uninstall.sh — Dotfiles Removal & Cleanup
# ==============================================================================
# Reverses install.sh: removes managed symlinks from $HOME via GNU Stow,
# then scrubs any remaining known symlinks manually.
# Does NOT delete ~/dotfiles or any system packages.
# ==============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo -e "${YELLOW}Target:${NC} $DOTFILES_DIR"

# ── 1. Unstow Packages ───────────────────────────────────────────────────────
if command -v stow &>/dev/null; then
    echo "--- Unstowing packages ---"
    echo "  Unstowing: home"
    stow -D --dir="$DOTFILES_DIR" --target="$HOME" home 2>/dev/null || true
else
    echo -e "${RED}Warning:${NC} GNU Stow not found — falling back to manual cleanup."
fi

# ── 2. Remove Known Symlinks ─────────────────────────────────────────────────
echo "--- Removing symlinks ---"
_links=(
    "$HOME/.bashrc"
    "$HOME/.bash_profile"
    "$HOME/.bash_aliases"
    "$HOME/.blerc"
    "$HOME/.zshrc"
    "$HOME/.config/tmux/tmux.conf"
    "$HOME/.inputrc"
    "$HOME/.gitconfig"
    "$HOME/.common_shell"
    "$HOME/.config/starship.toml"
    "$HOME/.config/dotfiles/theme.sh"
)
for link in "${_links[@]}"; do
    if [ -L "$link" ]; then
        rm -f "$link"
        echo -e "  ${GREEN}✓${NC} $link"
    fi
done

echo "======================================================================"
echo "Done. System packages and ~/dotfiles were preserved."
echo "======================================================================"
