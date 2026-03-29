#!/bin/bash
set -euo pipefail

# ==============================================================================
# uninstall.sh — Dotfiles Removal and Cleanup Script
# ==============================================================================
# Reverses everything done by install.sh:
#   1. Unstows all symlinked dotfiles (via GNU Stow)
#   2. Removes user-local tools from ~/.local/bin
#   3. Removes ble.sh, bash-completion upgrade, base16-shell, TPM
#   4. Optionally removes system packages (apt/dnf/pacman/brew)
#   5. Optionally removes the dotfiles repo itself
#
# USAGE:
#   bash ~/dotfiles/scripts/uninstall.sh
#   make uninstall                         # Via Makefile
#
# WHAT IS PRESERVED:
#   • ~/.bash_local — machine-specific secrets/overrides (never tracked in git)
#   • ~/.bash_history — your shell history is never touched
#   • ~/dotfiles_backup_<timestamp>/ — backups created by install.sh
#   • Other SSH keys in ~/.ssh/authorized_keys (only the MDC_public key is removed)
#   • System packages and the dotfiles repo (unless you explicitly confirm)
#
# SAFETY MEASURES:
#   - Stow only removes symlinks it owns — your real files are safe
#   - SSH authorized_keys: only the MDC_public key is removed (fixed-string grep)
#   - System packages: only removed if you confirm interactively
#   - The dotfiles directory is only removed if you confirm
#   - Manual fallback if stow isn't available: only removes known symlinks
#
# NOTE:
#   This script uses `set -euo pipefail` but wraps removals in conditionals
#   and `|| true` so missing files don't cause early exit.
# ==============================================================================

# ---- Colors for output -------------------------------------------------------
# Same color scheme as install.sh and test.sh for consistency
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ---- Resolve dotfiles directory (works even if called from elsewhere) --------
# Uses BASH_SOURCE to find the script's location, then navigates up one level
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo -e "${YELLOW}Dotfiles directory:${NC} $DOTFILES_DIR"
echo ""

# ==============================================================================
# 1. Remove Stow-managed Symlinks
# ==============================================================================
# stow --delete removes only the symlinks it created. Real files are untouched.
# .stowrc provides defaults: --dir=stow --target=~ --no-folding

echo -e "${YELLOW}[1/6] Removing stow-managed symlinks...${NC}"
if command -v stow &>/dev/null; then
    STOW_PKGS=(bash zsh git shell tmux nvim starship bat atuin fastfetch alacritty)
    cd "$DOTFILES_DIR"
    for pkg in "${STOW_PKGS[@]}"; do
        if [ -d "stow/$pkg" ]; then
            stow --delete "$pkg" 2>/dev/null && \
                echo -e "  ${GREEN}✓${NC} Unstowed: $pkg" || \
                echo -e "  ${YELLOW}⚠${NC} Skipped: $pkg (not stowed or conflict)"
        fi
    done
else
    # Fallback: manually remove known symlinks if stow isn't installed
    echo "  stow not found — removing symlinks manually..."
    _symlinks=(
        "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.bash_aliases"
        "$HOME/.bash_exports" "$HOME/.bash_functions" "$HOME/.bash_wrappers"
        "$HOME/.blerc" "$HOME/.zshrc" "$HOME/.tmux.conf" "$HOME/.inputrc"
        "$HOME/.gitconfig" "$HOME/.gitattributes" "$HOME/.editorconfig"
        "$HOME/.config/starship.toml"
        "$HOME/.config/atuin/config.toml"
        "$HOME/.config/fastfetch/config.jsonc"
        "$HOME/.config/alacritty/alacritty.toml"
        "$HOME/.config/alacritty/alacritty.yml"
    )
    for link in "${_symlinks[@]}"; do
        if [ -L "$link" ]; then
            rm -f "$link"
            echo -e "  ${GREEN}✓${NC} Removed: $link"
        fi
    done
    # Remove stow-created directories under .config (only if empty after symlink removal)
    for dir in nvim bat tmux fastfetch alacritty atuin; do
        rmdir "$HOME/.config/$dir" 2>/dev/null || true
    done
fi
echo ""

# ==============================================================================
# 2. Remove User-Local Tools (installed to ~/.local/bin by install.sh)
# ==============================================================================
# These are pre-built binaries that install.sh downloaded — no sudo needed.

echo -e "${YELLOW}[2/6] Removing user-local tools from ~/.local/bin...${NC}"
LOCAL_TOOLS=(nvim starship lazygit glow eza dust duf carapace atuin zoxide)
for tool in "${LOCAL_TOOLS[@]}"; do
    if [ -f "$HOME/.local/bin/$tool" ]; then
        rm -f "$HOME/.local/bin/$tool"
        echo -e "  ${GREEN}✓${NC} Removed: ~/.local/bin/$tool"
    fi
done

# Remove Neovim runtime (extracted tarball lives alongside the binary)
if [ -d "$HOME/.local/nvim-linux" ]; then
    rm -rf "$HOME/.local/nvim-linux"
    echo -e "  ${GREEN}✓${NC} Removed: ~/.local/nvim-linux/"
fi

# Remove fd symlink (Debian/Ubuntu creates this for fdfind)
if [ -L "$HOME/.local/bin/fd" ]; then
    rm -f "$HOME/.local/bin/fd"
    echo -e "  ${GREEN}✓${NC} Removed: ~/.local/bin/fd symlink"
fi
echo ""

# ==============================================================================
# 3. Remove Shell Enhancements & Data
# ==============================================================================

echo -e "${YELLOW}[3/6] Removing shell enhancements...${NC}"

# ble.sh (Bash Line Editor)
if [ -d "$HOME/.local/share/blesh" ]; then
    rm -rf "$HOME/.local/share/blesh"
    echo -e "  ${GREEN}✓${NC} Removed: ble.sh (~/.local/share/blesh/)"
fi

# bash-completion upgrade (installed to ~/.local/share by install.sh)
if [ -d "$HOME/.local/share/bash-completion" ]; then
    rm -rf "$HOME/.local/share/bash-completion"
    echo -e "  ${GREEN}✓${NC} Removed: bash-completion upgrade (~/.local/share/bash-completion/)"
fi

# base16-shell color themes
if [ -d "$HOME/.config/base16-shell" ]; then
    rm -rf "$HOME/.config/base16-shell"
    echo -e "  ${GREEN}✓${NC} Removed: base16-shell"
fi

# Tmux Plugin Manager (TPM) and plugins
if [ -d "$HOME/.tmux/plugins" ]; then
    rm -rf "$HOME/.tmux/plugins"
    echo -e "  ${GREEN}✓${NC} Removed: tmux plugins (~/.tmux/plugins/)"
fi

# JetBrainsMono Nerd Font (Linux only — macOS uses Homebrew cask)
if [ -d "$HOME/.local/share/fonts/JetBrainsMono" ]; then
    rm -rf "$HOME/.local/share/fonts/JetBrainsMono"
    echo -e "  ${GREEN}✓${NC} Removed: JetBrainsMono Nerd Font"
    command -v fc-cache >/dev/null 2>&1 && fc-cache -f 2>/dev/null
fi

# Carapace completion cache
rm -f "$HOME/.cache/carapace_init.bash" "$HOME/.cache/carapace_init.zsh" 2>/dev/null

# Connectivity cache
rm -f "$HOME/.cache/is_online" 2>/dev/null

echo ""

# ==============================================================================
# 4. Remove SSH Key & Sockets
# ==============================================================================

echo -e "${YELLOW}[4/6] Cleaning up SSH...${NC}"

# Remove the dotfiles SSH key from authorized_keys (preserves all other keys).
# Uses -F (fixed string) to avoid regex metacharacters in the key being misinterpreted.
SSH_KEY_SOURCE="$DOTFILES_DIR/.ssh/MDC_public.pub"
if [ -f "$SSH_KEY_SOURCE" ] && [ -f "$HOME/.ssh/authorized_keys" ]; then
    if grep -qFf "$SSH_KEY_SOURCE" "$HOME/.ssh/authorized_keys"; then
        grep -vFf "$SSH_KEY_SOURCE" "$HOME/.ssh/authorized_keys" > "$HOME/.ssh/authorized_keys.tmp"
        mv "$HOME/.ssh/authorized_keys.tmp" "$HOME/.ssh/authorized_keys"
        chmod 600 "$HOME/.ssh/authorized_keys"
        echo -e "  ${GREEN}✓${NC} SSH key removed from authorized_keys"
    else
        echo "  SSH key not found in authorized_keys — skipping"
    fi
else
    echo "  No SSH key to remove"
fi

# Remove SSH config symlink (stow doesn't manage this — install.sh does it manually)
if [ -L "$HOME/.ssh/config" ]; then
    rm -f "$HOME/.ssh/config"
    echo -e "  ${GREEN}✓${NC} Removed: ~/.ssh/config symlink"
fi

# Remove SSH multiplexing sockets directory
if [ -d "$HOME/.ssh/sockets" ]; then
    rm -rf "$HOME/.ssh/sockets"
    echo -e "  ${GREEN}✓${NC} Removed: ~/.ssh/sockets/"
fi

echo ""

# ==============================================================================
# 5. Optional: Remove System Packages
# ==============================================================================
# These were installed via apt/dnf/pacman/brew. Requires confirmation because
# other users or software on the system may depend on them.

echo -e "${YELLOW}[5/6] System packages${NC}"
read -p "Remove installed system packages (neovim, tmux, starship, etc)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    OS="$(uname)"
    if [ "$OS" = "Darwin" ]; then
        echo "Removing Homebrew packages..."
        brew uninstall --ignore-dependencies tmux git fzf neovim starship hstr carapace \
            bat eza ripgrep fd zoxide fastfetch cmatrix btop lazygit glow tldr dust duf procs bottom 2>/dev/null || true
        brew uninstall --cask font-jetbrains-mono-nerd-font 2>/dev/null || true

    elif [ -f /etc/debian_version ]; then
        echo "Removing apt packages..."
        sudo apt remove -y tmux fzf xclip hstr bat cmatrix btop tldr ncurses-term \
            bash-completion zsh zsh-syntax-highlighting zsh-autosuggestions \
            ripgrep fd-find duf fastfetch 2>/dev/null || true
        sudo apt autoremove -y 2>/dev/null || true

    elif [ -f /etc/redhat-release ]; then
        PKG_MANAGER="yum"
        command -v dnf >/dev/null 2>&1 && PKG_MANAGER="dnf"
        echo "Removing $PKG_MANAGER packages..."
        sudo $PKG_MANAGER remove -y git tmux fzf neovim hstr bat fastfetch cmatrix btop \
            lazygit glow tldr ripgrep fd-find zsh zsh-syntax-highlighting zsh-autosuggestions 2>/dev/null || true

    elif [ -f /etc/arch-release ]; then
        echo "Removing pacman packages..."
        sudo pacman -Rns --noconfirm git tmux fzf neovim eza fastfetch btop ripgrep fd \
            dust duf zoxide zsh zsh-syntax-highlighting zsh-autosuggestions 2>/dev/null || true
    fi
    echo -e "  ${GREEN}✓${NC} System packages removed"
else
    echo "  Skipped — system packages left in place"
fi
echo ""

# ==============================================================================
# 6. Optional: Remove Dotfiles Directory
# ==============================================================================

echo -e "${YELLOW}[6/6] Dotfiles directory${NC}"
read -p "Remove the dotfiles directory ($DOTFILES_DIR)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$DOTFILES_DIR"
    echo -e "  ${GREEN}✓${NC} Removed: $DOTFILES_DIR"
else
    echo "  Kept: $DOTFILES_DIR"
fi

echo ""
echo "=============================================================================="
echo -e "${GREEN}UNINSTALL COMPLETE.${NC}"
echo "Please RESTART your terminal to revert all shell changes."
echo "=============================================================================="
