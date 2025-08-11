#!/bin/bash

# uninstall.sh - Remove dotfiles symlinks and clean up

# Remove symlinks
echo "Removing symlinks..."
rm -f "$HOME/.bash_aliases"
rm -f "$HOME/.bash_exports"
rm -f "$HOME/.bash_profile"
rm -f "$HOME/.bash_wrappers"
rm -f "$HOME/.bashrc"
rm -f "$HOME/.tmux.conf"
rm -f "$HOME/.config/starship.toml"

# Clean up tmux plugins (optional: uncomment if desired)
# rm -rf "$HOME/.tmux/plugins"

# Optionally remove dependencies (uncomment with caution)
# if [ "$(uname)" = "Darwin" ]; then
#   brew uninstall tmux git fzf starship
# elif [ "$(uname)" = "Linux" ]; then
#   sudo apt remove -y tmux git fzf xclip wl-clipboard
#   # Starship uninstall: rm ~/.cargo/bin/starship if installed via curl
# fi

echo "Uninstall complete! You may need to restart your shell."
