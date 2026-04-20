#!/bin/bash
# ==============================================================================
# uninstall.sh — remove stow-managed dotfile symlinks from $HOME
# ==============================================================================
# Does NOT delete ~/dotfiles, system packages, or ble.sh.
# Non-stow extras (theme.sh symlink) removed explicitly.
# ==============================================================================
set -euo pipefail

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
NC=$'\033[0m'

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "${YELLOW}Target:${NC} $DOTFILES_DIR"

# ── 1. Unstow via GNU Stow ────────────────────────────────────────────────────
# Stow's -D reverses whatever -R / default would create; no manual list needed.
if command -v stow >/dev/null 2>&1; then
    echo "--- Unstowing: home ---"
    stow -D --dir="$DOTFILES_DIR" --target="$HOME" home
else
    echo "${RED}Warning:${NC} GNU Stow not found — cannot unstow."
    echo "  Install stow and re-run, or remove symlinks manually."
    exit 1
fi

# ── 2. Non-stow artifacts ─────────────────────────────────────────────────────
# theme.sh is a direct symlink created by install.sh / make theme-*, not stow.
theme_link="$HOME/.config/dotfiles/theme.sh"
if [ -L "$theme_link" ]; then
    rm -f "$theme_link"
    echo "  ${GREEN}✓${NC} removed $theme_link"
fi

echo "Done. Repo and system packages preserved."
