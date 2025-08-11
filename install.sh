#!/bin/bash

# install.sh - Install dotfiles and dependencies

# Set repo path
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install dependencies including Starship
OS="$(uname)"
if [ "$OS" = "Darwin" ]; then
  # macOS
  if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  echo "Installing tmux, git, fzf, starship via Homebrew..."
  brew install tmux git fzf starship
elif [ "$OS" = "Linux" ]; then
  # Assume Debian-based; adjust for other distros
  sudo apt update
  echo "Installing tmux, git, fzf, xclip..."
  sudo apt install -y tmux git fzf xclip
  if [ -n "$WAYLAND_DISPLAY" ]; then
    sudo apt install -y wl-clipboard
  fi
  # Install Starship
  curl -sS https://starship.rs/install.sh | sh -s -- -y
else
  echo "Unsupported OS: $OS"
  exit 1
fi

# Clone TPM if not present
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  echo "Cloning Tmux Plugin Manager..."
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Symlink dotfiles including starship.toml
echo "Creating symlinks..."
ln -sf "$DOTFILES_DIR/.bash_aliases" "$HOME/.bash_aliases"
ln -sf "$DOTFILES_DIR/.bash_exports" "$HOME/.bash_exports"
ln -sf "$DOTFILES_DIR/.bash_profile" "$HOME/.bash_profile"
ln -sf "$DOTFILES_DIR/.bash_wrappers" "$HOME/.bash_wrappers"
ln -sf "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
ln -sf "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
mkdir -p "$HOME/.config"
ln -sf "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"

# Source Bash profile
source "$HOME/.bash_profile"

# For tmux: Start tmux and install plugins
echo "Start tmux and press prefix + I to install plugins."
echo "Setup complete!"
