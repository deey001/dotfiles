#!/bin/bash

echo "Removing symlinks..."
rm -f "$HOME/.bash_aliases"
rm -f "$HOME/.bash_exports"
rm -f "$HOME/.bash_profile"
rm -f "$HOME/.bash_wrappers"
rm -f "$HOME/.bashrc"
rm -f "$HOME/.tmux.conf"
rm -f "$HOME/.config/starship.toml"

echo "Uninstall complete! Restart shell."
