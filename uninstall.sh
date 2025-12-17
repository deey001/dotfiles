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
rm -f "$HOME/.tmux.conf"
rm -f "$HOME/.config/starship.toml"
rm -f "$HOME/.config/nvim/init.lua"
rm -f "$HOME/.config/alacritty/alacritty.yml"

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

# Remove Ubuntu Nerd Font (Linux)
if [ -f "$HOME/.local/share/fonts/UbuntuNerdFont-Regular.ttf" ]; then
    echo "Removing Ubuntu Nerd Font..."
    rm -f "$HOME/.local/share/fonts/UbuntuNerdFont-Regular.ttf"
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
        brew uninstall tmux git fzf neovim starship hstr bat eza fastfetch cmatrix btop lazygit glow tldr
    elif [ -f /etc/debian_version ]; then
        sudo apt remove -y tmux fzf hstr bat cmatrix btop tldr fastfetch lazygit glow
        # Remove manual neovim install
        sudo rm -f /usr/local/bin/nvim
        sudo rm -rf /usr/local/nvim-linux-x86_64
    elif [ -f /etc/redhat-release ]; then
         if command -v dnf > /dev/null 2>&1; then
            sudo dnf remove -y git tmux fzf neovim hstr bat fastfetch cmatrix btop lazygit glow tldr
        else
            sudo yum remove -y git tmux fzf neovim hstr bat fastfetch cmatrix btop lazygit glow tldr
        fi
    elif [ -f /etc/arch-release ]; then
        sudo pacman -Rns --noconfirm git tmux fzf neovim hstr bat eza fastfetch cmatrix btop lazygit glow tldr
    fi

    # Uninstall Starship binary
    if command -v starship >/dev/null 2>&1; then
        echo "Removing Starship binary..."
        sudo rm -f "$(command -v starship)"
    fi
fi

echo "Uninstall complete. A system restart is recommended."
