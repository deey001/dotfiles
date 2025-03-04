#!/bin/bash

# Find all dot files then if the original file exists, create a backup
# Once backed up to {file}.dtbak symlink the new dotfile in place
for file in $(find . -maxdepth 1 -name ".*" -type f -printf "%f\n" ); do
    if [ -e ~/$file ]; then
        mv -f ~/$file{,.dtbak}
    fi
    ln -s $PWD/$file ~/$file
done

# Check if vim-scripts installed, if not, install it automatically
# Using 'command -v' instead of 'hash' as it's more portable
if command -v vim >/dev/null 2>&1 && rpm -q vim-scripts >/dev/null 2>&1; then
    echo "vim-scripts installed"
else
    echo "vim-scripts not installed, installing"
    # Using dnf (RHEL 8+) instead of apt; falling back to yum for RHEL 7
    if command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y vim-enhanced vim-scripts curl net-tools tmux neofetch
    else
        sudo yum install -y vim-enhanced vim-scripts curl net-tools tmux neofetch
    fi
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
    # Add SELinux context for RHEL/CentOS
    if command -v restorecon >/dev/null 2>&1; then
        restorecon -R "$SSH_DIR"
    fi
    echo "SSH key successfully added."
else
    echo "Error: $SSH_KEY_SOURCE not found in the current directory."
    exit 1
fi

echo "Installed"

# Source bashrc if it exists
[ -f ~/.bashrc ] && source ~/.bashrc
