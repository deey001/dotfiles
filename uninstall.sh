#!/bin/bash

# uninstall.sh - Remove dotfiles symlinks and clean up Starship

# Remove symlinks
echo "Removing symlinks..."
rm -f "$HOME/.bash_aliases"
rm -f "$HOME/.bash_exports"
rm -f "$HOME/.bash_profile"
rm -f "$HOME/.bash_wrappers"
rm -f "$HOME/.bashrc"
rm -f "$HOME/.tmux.conf"
rm -f "$HOME/.config/starship.toml"

# Remove Starship init from .bashrc (if present)
sed -i '/# Initialize Starship prompt/d' "$HOME/.bashrc"
sed -i '/eval "$(starship init bash)"/d' "$HOME/.bashrc"

# Optional: Uninstall Starship binary (uncomment if desired)
# command -v starship &> /dev/null && curl -sS https://starship.rs/install.sh | sh -s -- --uninstall

# Clean up tmux plugins (optional: uncomment if desired)
# rm -rf "$HOME/.tmux/plugins"

echo "Uninstall complete! You may need to restart your shell."
