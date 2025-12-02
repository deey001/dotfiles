#!/bin/bash

# install.sh - Install dotfiles, dependencies, vim, Starship, and Nerd Font

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Strict validation of .bashrc
if [ -f "$DOTFILES_DIR/.bashrc" ]; then
  if ! bash -c ". '$DOTFILES_DIR/.bashrc' 2>/dev/null"; then
    echo "Error: .bashrc contains syntax errors or causes segfault. Aborting installation."
    echo "Please fix .bashrc or comment out problematic sections (e.g., zoxide)."
    exit 1
  fi
fi

OS="$(uname)"
if [ "$OS" = "Darwin" ]; then
  # macOS
  if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  
  echo "Installing tools via Homebrew..."

  # Tmux: Terminal Multiplexer. Allows multiple terminal sessions in one window and session persistence.
  # Git: Version control system.
  # Fzf: Command-line fuzzy finder. fast, interactive search for files and history.
  # Neovim: Hyperextensible Vim-based text editor. Modern replacement for Vim.
  # Starship: Minimal, blazing-fast, and infinitely customizable prompt for any shell. Shows git status, package versions, etc.
  # Hstr: Bash history suggest box. Easily view, navigate, search, and use your command history.
  # Bat: A cat clone with syntax highlighting and Git integration.
  # Eza: A modern, maintained replacement for ls. Features colors, icons, and git status.
  # Zoxide: A smarter cd command. Remembers which directories you use most frequently.
  # Fastfetch: A neofetch-like tool for fetching system information and displaying it prettily.
  # Cmatrix: Matrix screen saver.
  # Btop: Beautiful resource monitor with graphs and colors.
  # Lazygit: Terminal UI for Git operations.
  # Glow: Markdown renderer for the terminal.
  # Tldr: Simplified man pages with practical examples.
  brew install tmux git fzf neovim starship hstr bat eza zoxide fastfetch cmatrix btop lazygit glow tldr

elif [ "$OS" = "Linux" ]; then
  if [ -f /etc/debian_version ]; then
    # Debian/Ubuntu
    sudo apt update
    echo "Installing tools via apt..."
    
    # Tmux: Terminal Multiplexer.
    # Git: Version control.
    # Fzf: Fuzzy finder.
    # Neovim: Modern Vim editor.
    # Xclip: Command line interface to the X11 clipboard (useful for clipboard sharing).
    # Bash-completion: Programmable completion for the bash shell.
    # Zoxide: Smarter cd.
    # Hstr: History search.
    # Bat: Better cat.
    # Fastfetch: System info.
    # Cmatrix: Matrix screen saver.
    # Btop: Beautiful resource monitor.
    # Lazygit: Terminal UI for Git.
    # Glow: Markdown renderer.
    # Tldr: Simplified man pages.
    # Note: eza is not always in default repos, falling back or assuming user handles it.
    sudo apt install -y tmux git fzf neovim xclip bash-completion zoxide hstr bat fastfetch cmatrix btop lazygit glow tldr
    
    # Ubuntu Minimal Cleanup
    if grep -qi "ubuntu" /etc/os-release; then
        echo "Ubuntu detected. Removing snapd for a minimal install..."
        sudo apt purge -y snapd
        sudo apt autoremove -y
        rm -rf "$HOME/snap"
        # Prevent snapd from being reinstalled
        sudo apt-mark hold snapd
    fi
    
    if [ -n "$WAYLAND_DISPLAY" ]; then
      sudo apt install -y wl-clipboard
    fi
  elif [ -f /etc/redhat-release ]; then
    # RHEL/CentOS/Fedora
    echo "Installing tools via dnf/yum..."
    
    # Tmux: Terminal Multiplexer.
    # Git: Version control.
    # Fzf: Fuzzy finder.
    # Neovim: Modern Vim editor.
    # Zoxide: Smarter cd.
    # Hstr: History search.
    # Bat: Better cat.
    # Fastfetch: System info.
    # Cmatrix: Matrix screen saver.
    # Btop: Beautiful resource monitor.
    # Lazygit: Terminal UI for Git.
    # Glow: Markdown renderer.
    # Tldr: Simplified man pages.
    if command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y git tmux fzf neovim zoxide hstr bat fastfetch cmatrix btop lazygit glow tldr
    else
        sudo yum install -y git tmux fzf neovim zoxide hstr bat fastfetch cmatrix btop lazygit glow tldr
    fi
  elif [ -f /etc/arch-release ]; then
    # Arch Linux
    echo "Installing tools via pacman..."
    
    # Tmux: Terminal Multiplexer.
    # Git: Version control.
    # Fzf: Fuzzy finder.
    # Neovim: Modern Vim editor.
    # Zoxide: Smarter cd.
    # Hstr: History search.
    # Bat: Better cat.
    # Eza: Modern ls.
    # Fastfetch: System info.
    # Cmatrix: Matrix screen saver.
    # Btop: Beautiful resource monitor.
    # Lazygit: Terminal UI for Git.
    # Glow: Markdown renderer.
    # Tldr: Simplified man pages.
    sudo pacman -Syu --noconfirm git tmux fzf neovim zoxide hstr bat eza fastfetch cmatrix btop lazygit glow tldr
  fi
  
  # Install Starship
  # The minimal, blazing-fast, and infinitely customizable prompt for any shell.
  curl -sS https://starship.rs/install.sh | sh -s -- -y
else
  echo "Unsupported OS: $OS"
  exit 1
fi

# Install ble.sh (Bash Line Editor)
# A command line editor written in pure Bash 5.0+.
# Provides syntax highlighting, auto-suggestions, and vim modes for the command line.
if [ ! -d "$HOME/.local/share/blesh" ]; then
    echo "Installing ble.sh..."
    git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git
    make -C ble.sh install PREFIX=~/.local
    rm -rf ble.sh
fi

# Clone bash-preexec for predictive text
if [ ! -d "$HOME/.bash-preexec" ]; then
  echo "Cloning bash-preexec..."
  git clone https://github.com/rcaloras/bash-preexec.git ~/.bash-preexec
fi

# Clone base16-shell for themes
if [ ! -d "$HOME/.config/base16-shell" ]; then
  echo "Cloning base16-shell..."
  git clone https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell
fi

# Clone TPM if not present
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  echo "Cloning Tmux Plugin Manager..."
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Symlink dotfiles including starship.toml and .vimrc (backup existing .vimrc)
echo "Creating symlinks..."
ln -sf "$DOTFILES_DIR/.bash_aliases" "$HOME/.bash_aliases"
ln -sf "$DOTFILES_DIR/.bash_exports" "$HOME/.bash_exports"
ln -sf "$DOTFILES_DIR/.bash_profile" "$HOME/.bash_profile"
ln -sf "$DOTFILES_DIR/.bash_wrappers" "$HOME/.bash_wrappers"
ln -sf "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
ln -sf "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
mkdir -p "$HOME/.config"
ln -sf "$DOTFILES_DIR/.config/starship.toml" "$HOME/.config/starship.toml"
if [ -f "$HOME/.vimrc" ]; then
  mv "$HOME/.vimrc" "$HOME/.vimrc.bak"  # Backup existing .vimrc
fi
ln -sf "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"
# Symlink Neovim config
mkdir -p "$HOME/.config/nvim"
ln -sf "$DOTFILES_DIR/.config/nvim/init.vim" "$HOME/.config/nvim/init.vim"
# Symlink Alacritty config
mkdir -p "$HOME/.config/alacritty"
ln -sf "$DOTFILES_DIR/.config/alacritty/alacritty.yml" "$HOME/.config/alacritty/alacritty.yml"

# Append Starship init to .bashrc if not present
if ! grep -q "starship init bash" "$HOME/.bashrc" && [ -f /usr/local/bin/starship ]; then
  echo '# Initialize Starship prompt' >> "$HOME/.bashrc"
  echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
fi

# Install SSH Key
SSH_KEY_SOURCE="$DOTFILES_DIR/MDC_public.pub"
if [ -f "$SSH_KEY_SOURCE" ]; then
  echo "Installing SSH key..."
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  cat "$SSH_KEY_SOURCE" >> "$HOME/.ssh/authorized_keys"
  chmod 600 "$HOME/.ssh/authorized_keys"
  echo "SSH key installed."
else
  echo "Warning: SSH key ($SSH_KEY_SOURCE) not found. Skipping."
fi

# Source Bash profile
source "$HOME/.bash_profile"

echo "Start tmux and press prefix + I to install plugins."
echo "Setup complete!"
