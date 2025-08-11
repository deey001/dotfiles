#!/bin/bash

# Script to install dependencies, fonts, and symlink dotfiles.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

OS="$(uname)"
if [ "$OS" = "Darwin" ]; then
  if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  brew install tmux git fzf bash-completion@2
  brew install --cask font-jetbrains-mono-nerd-font
elif [ "$OS" = "Linux" ]; then
  sudo apt update
  sudo apt install -y tmux git fzf xclip fontconfig bash-completion
  if [ -n "$WAYLAND_DISPLAY" ]; then
    sudo apt install -y wl-clipboard
  fi
  mkdir -p ~/.local/share/fonts
  cd ~/.local/share/fonts
  curl -OL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
  tar xvf JetBrainsMono.tar.xz
  rm JetBrainsMono.tar.xz
  fc-cache -fv
  fc-list | grep JetBrainsMono
else
  echo "Unsupported OS: $OS"
  exit 1
fi

if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

echo "Creating symlinks..."
ln -sf "$DOTFILES_DIR/.bash_aliases" "$HOME/.bash_aliases"
ln -sf "$DOTFILES_DIR/.bash_exports" "$HOME/.bash_exports"
ln -sf "$DOTFILES_DIR/.bash_profile" "$HOME/.bash_profile"
ln -sf "$DOTFILES_DIR/.bash_wrappers" "$HOME/.bash_wrappers"
ln -sf "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
ln -sf "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"

source "$HOME/.bash_profile"

echo "Start tmux and press prefix + I to install plugins."
echo "Setup complete!"
