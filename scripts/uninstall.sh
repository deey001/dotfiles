#!/bin/bash
# Remove the symlinks created by install.sh and restore the files it backed up
# on its first run. Packages and the repo itself are left alone.
set -euo pipefail
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

stow -D --dir="$DOTFILES_DIR" --target="$HOME" home
echo "Symlinks removed."

# The oldest backup holds the files that existed before the dotfiles were installed.
backup=$(find "$HOME/.dotfiles-backup" -mindepth 1 -maxdepth 1 -type d 2> /dev/null | sort | head -1)
if [[ -n $backup ]]; then
  (cd "$backup" && find . -type f -o -type l) | sed 's|^\./||' | while IFS= read -r rel; do
    if [[ -e $HOME/$rel || -L $HOME/$rel ]]; then
      echo "  kept existing ~/$rel (backup left in $backup)"
    else
      mkdir -p "$HOME/$(dirname "$rel")"
      mv "$backup/$rel" "$HOME/$rel"
      echo "  restored ~/$rel"
    fi
  done
  find "$backup" -type d -empty -delete
fi
