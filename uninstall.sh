#!/bin/bash

# uninstall.sh - Remove dotfiles symlinks and clean up Starship/vim

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Remove symlinks
echo "Removing symlinks..."
rm -f "$HOME/.bash_aliases"
rm -f "$HOME/.bash_exports"
rm -f "$HOME/.bash_functions"
rm -f "$HOME/.bash_profile"
rm -f "$HOME/.bash_wrappers"
rm -f "$HOME/.blerc"
rm -f "$HOME/.bashrc"
rm -f "$HOME/.zshrc"
rm -f "$HOME/.tmux.conf"
rm -f "$HOME/.gitconfig"
rm -f "$HOME/.inputrc"
rm -f "$HOME/.ssh/config"
rm -f "$HOME/.config/starship.toml"
rm -f "$HOME/.config/nvim/init.lua"
rm -f "$HOME/.config/alacritty/alacritty.yml"
rm -f "$HOME/.config/alacritty/alacritty.toml"

# Remove configurations
rm -rf "$HOME/.config/alacritty"
rm -rf "$HOME/.config/nvim"
rm -rf "$HOME/.config/bat"
rm -rf "$HOME/.config/fastfetch"
rm -rf "$HOME/.config/base16-shell"
rm -rf "$HOME/.config/tmux"

# Remove ble.sh
echo "Removing ble.sh..."
rm -rf "$HOME/.local/share/blesh"

# Remove JetBrainsMono Nerd Font (Linux)
if [ -d "$HOME/.local/share/fonts/JetBrainsMono" ]; then
    echo "Removing JetBrainsMono Nerd Font..."
    rm -rf "$HOME/.local/share/fonts/JetBrainsMono"
    if command -v fc-cache > /dev/null 2>&1; then
      fc-cache -f -v
    fi
fi

# Clean up tmux plugins
echo "Removing tmux plugins..."
rm -rf "$HOME/.tmux/plugins"

# Remove cloned repos
echo "Removing cloned repositories..."
rm -rf "$HOME/.bash-preexec"

# Remove SSH Key
SSH_KEY_SOURCE="$DOTFILES_DIR/MDC_public.pub"
if [ -f "$SSH_KEY_SOURCE" ] && [ -f "$HOME/.ssh/authorized_keys" ]; then
    echo "Removing SSH key..."
    # Use grep to remove the key (fixed string matching)
    if grep -qFf "$SSH_KEY_SOURCE" "$HOME/.ssh/authorized_keys"; then
        grep -vFf "$SSH_KEY_SOURCE" "$HOME/.ssh/authorized_keys" > "$HOME/.ssh/authorized_keys.tmp"
        mv "$HOME/.ssh/authorized_keys.tmp" "$HOME/.ssh/authorized_keys"
        chmod 600 "$HOME/.ssh/authorized_keys"
        echo "SSH key removed."
    fi
fi

# Interactive Package Removal
read -p "Do you want to remove installed packages (neovim, tmux, starship, etc)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ "$(uname)" = "Darwin" ]; then
        brew uninstall tmux git fzf neovim starship hstr bat eza fastfetch cmatrix btop lazygit glow tldr ripgrep fd dust duf zoxide
    elif [ -f /etc/debian_version ]; then
        sudo apt remove -y tmux fzf hstr bat cmatrix btop tldr fastfetch lazygit glow ripgrep fd-find duf zoxide
        # Remove manual neovim install
        sudo rm -f /usr/local/bin/nvim
        sudo rm -rf /usr/local/nvim-linux-x86_64
        # Remove manual binary installs
        sudo rm -f /usr/local/bin/eza /usr/local/bin/dust
    elif [ -f /etc/redhat-release ]; then
         if command -v dnf > /dev/null 2>&1; then
            sudo dnf remove -y git tmux fzf neovim hstr bat fastfetch cmatrix btop lazygit glow tldr ripgrep fd-find unzip duf zoxide
        else
            sudo yum remove -y git tmux fzf neovim hstr bat fastfetch cmatrix btop lazygit glow tldr ripgrep fd-find unzip duf zoxide
        fi
        # Remove manual binary installs
        sudo rm -f /usr/local/bin/eza /usr/local/bin/dust
    elif [ -f /etc/arch-release ]; then
        sudo pacman -Rns --noconfirm base-devel git tmux fzf neovim hstr bat eza fastfetch cmatrix btop lazygit glow tldr ripgrep fd dust duf zoxide unzip
    fi

    # Uninstall Starship binary
    if command -v starship >/dev/null 2>&1; then
        echo "Removing Starship binary..."
        sudo rm -f "$(command -v starship)"
    fi
fi

# Remove dotfiles directory itself (optional)
read -p "Do you want to remove the $DOTFILES_DIR directory? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$DOTFILES_DIR"
fi

echo "UNINSTALL COMPLETE."
echo "Please RESTART your terminal to revert all changes."
echo "=============================================================================="
