#!/bin/bash

# uninstall.sh - Remove dotfiles symlinks and clean up Starship/vim

# Remove symlinks
echo "Removing symlinks..."
rm -f "$HOME/.bash_aliases"
rm -f "$HOME/.bash_exports"
rm -f "$HOME/.bash_profile"
rm -f "$HOME/.bash_wrappers"
rm -f "$HOME/.bashrc"
rm -f "$HOME/.tmux.conf"
rm -f "$HOME/.config/starship.toml"
rm -f "$HOME/.config/nvim/init.vim"
rm -f "$HOME/.config/alacritty/alacritty.yml"

# Remove Starship init from .bashrc (if present)
sed -i '/# Initialize Starship prompt/d' "$HOME/.bashrc"
sed -i '/eval "$(starship init bash)"/d' "$HOME/.bashrc"

# Remove ble.sh
echo "Removing ble.sh..."
rm -rf "$HOME/.local/share/blesh"

# Remove Ubuntu Nerd Font (Linux)
if [ -f "$HOME/.local/share/fonts/UbuntuNerdFont-Regular.ttf" ]; then
    echo "Removing Ubuntu Nerd Font..."
    rm -f "$HOME/.local/share/fonts/UbuntuNerdFont-Regular.ttf"
    # Update font cache if possible
    if command -v fc-cache >/dev/null 2>&1; then
      fc-cache -f -v
    fi
fi

# Optional: Uninstall Starship binary (uncomment if desired)
# command -v starship &> /dev/null && curl -sS https://starship.rs/install.sh | sh -s -- --uninstall

# Optional: Uninstall vim and new tools (uncomment with caution)
# if [ "$(uname)" = "Darwin" ]; then
#   brew uninstall vim neovim hstr bat exa zoxide fastfetch alacritty
# elif [ "$(uname)" = "Linux" ]; then
#   sudo apt remove -y vim neovim hstr bat exa fastfetch alacritty
# fi

# Clean up tmux plugins (optional: uncomment if desired)
# rm -rf "$HOME/.tmux/plugins"

# Remove cloned repos
echo "Removing cloned repositories..."
rm -rf "$HOME/.bash-preexec"
rm -rf "$HOME/.config/base16-shell"

echo "Uninstall complete! You may need to restart your shell."
