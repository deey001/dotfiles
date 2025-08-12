#!/bin/bash

# install.sh - Install dotfiles, dependencies, vim, Starship, and Nerd Font

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

OS="$(uname)"
if [ "$OS" = "Darwin" ]; then
  # macOS
  if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  echo "Installing tmux, git, fzf, vim, starship via Homebrew..."
  brew install tmux git fzf vim starship
  brew install --cask font-jetbrains-mono-nerd-font
elif [ "$OS" = "Linux" ]; then
  # Assume Debian-based; adjust for other distros
  sudo apt update
  echo "Installing tmux, git, fzf, vim, xclip, bash-completion, zoxide..."
  sudo apt install -y tmux git fzf vim xclip bash-completion zoxide
  if [ -n "$WAYLAND_DISPLAY" ]; then
    sudo apt install -y wl-clipboard
  fi
  # Install Starship
  curl -sS https://starship.rs/install.sh | sh -s -- -y
  # Install JetBrainsMono Nerd Font
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

# Clone TPM if not present
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  echo "Cloning Tmux Plugin Manager..."
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Symlink dotfiles including .config/starship.toml and .vimrc (backup existing .vimrc)
echo "Creating symlinks..."
ln -sf "$DOTFILES_DIR/.bash_aliases" "$HOME/.bash_aliases"
ln -sf "$DOTFILES_DIR/.bash_exports" "$HOME/.bash_exports"
ln -sf "$DOTFILES_DIR/.bash_profile" "$HOME/.bash_profile"
ln -sf "$DOTFILES_DIR/.bash_wrappers" "$HOME/.bash_wrappers"
ln -sf "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
ln -sf "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
mkdir -p "$HOME/.config"
ln -sf "$DOTFILES_DIR/.config/starship.toml" "$HOME/.config/starship.toml"  # Updated path
if [ -f "$HOME/.vimrc" ]; then
  mv "$HOME/.vimrc" "$HOME/.vimrc.bak"  # Backup existing .vimrc
fi
ln -sf "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"

# Append Starship init to .bashrc if not present
if ! grep -q "starship init bash" "$HOME/.bashrc"; then
  echo '# Initialize Starship prompt' >> "$HOME/.bashrc"
  echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
fi

# Source Bash profile
source "$HOME/.bash_profile"

echo "Start tmux and press prefix + I to install plugins."
echo "Setup complete!"