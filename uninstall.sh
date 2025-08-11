#!/bin/bash

# Script to remove symlinks created by install.sh.

echo "Removing symlinks..."
rm -f "$HOME/.bash_aliases"
rm -f "$HOME/.bash_exports"
rm -f "$HOME/.bash_profile"
rm -f "$HOME/.bash_wrappers"
rm -f "$HOME/.bashrc"
rm -f "$HOME/.tmux.conf"

echo "Uninstall complete! Restart shell."
