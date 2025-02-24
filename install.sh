#!/bin/bash

# Find all dot files then if the original file exists, create a backup
# Once backed up to {file}.dtbak symlink the new dotfile in place
for file in $(find . -maxdepth 1 -name ".*" -type f  -printf "%f\n" ); do
    if [ -e ~/$file ]; then
        mv -f ~/$file{,.dtbak}
    fi
    ln -s $PWD/$file ~/$file
done

# Check if vim-addon installed, if not, install it automatically
if hash vim-addon 2>/dev/null; then
    echo "vim-addon (vim-scripts) installed"
else
    echo "vim-addon (vim-scripts) not installed, installing"
    apt install sudo && sudo apt update && sudo apt -y install vim-scripts curl net-tools tmux neofetch
fi

# SSH key setup
SSH_KEY_SOURCE="MDC_public.pub"
SSH_DIR="$HOME/.ssh"
SSH_KEY_DEST="$SSH_DIR/authorized_keys"

# Ensure the .ssh directory exists
echo "Setting up SSH key..."
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Check if the SSH key file exists in the current directory
if [ -f "$SSH_KEY_SOURCE" ]; then
    echo "Copying SSH key to $SSH_KEY_DEST..."
    cat "$SSH_KEY_SOURCE" >> "$SSH_KEY_DEST"
    chmod 600 "$SSH_KEY_DEST"
    echo "SSH key successfully added."
else
    echo "Error: $SSH_KEY_SOURCE not found in the current directory."
    exit 1
fi

echo "Installed"

source ~/.bashrc
