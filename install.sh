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
  # Fastfetch: A neofetch-like tool for fetching system information and displaying it prettily.
  # Cmatrix: Matrix screen saver.
  # Btop: Beautiful resource monitor with graphs and colors.
  # Lazygit: Terminal UI for Git operations.
  # Glow: Markdown renderer for the terminal.
  # Tldr: Simplified man pages with practical examples.
  brew install tmux git fzf neovim starship hstr bat eza fastfetch cmatrix btop lazygit glow tldr
  brew install --cask font-ubuntu-nerd-font

elif [ "$OS" = "Linux" ]; then
  if [ -f /etc/debian_version ]; then
    # Debian/Ubuntu
    sudo apt update
    echo "Installing tools via apt..."
    
    # Install Neovim from official tarball (most reliable method)
    echo "Installing latest Neovim..."
    if [ ! -f /usr/local/bin/nvim ]; then
        curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
        sudo tar -C /usr/local -xzf nvim-linux64.tar.gz
        sudo ln -sf /usr/local/nvim-linux64/bin/nvim /usr/local/bin/nvim
        rm nvim-linux64.tar.gz
    fi
    
    # Tmux: Terminal Multiplexer.
    # Git: Version control.
    # Fzf: Fuzzy finder.
    # Xclip: Command line interface to the X11 clipboard (useful for clipboard sharing).
    # Bash-completion: Programmable completion for the bash shell.
    # Hstr: History search.
    # Bat: Better cat.
    # Cmatrix: Matrix screen saver.
    # Btop: Beautiful resource monitor.
    # Tldr: Simplified man pages.
    sudo apt install -y tmux git fzf xclip bash-completion hstr bat cmatrix btop tldr
    
    # Install fastfetch from PPA
    echo "Installing fastfetch from PPA..."
    sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
    sudo apt update
    sudo apt install -y fastfetch
    
    # Install lazygit from GitHub releases
    echo "Installing lazygit from GitHub..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm lazygit lazygit.tar.gz
    
    # Install glow from GitHub releases
    echo "Installing glow from GitHub..."
    GLOW_VERSION=$(curl -s "https://api.github.com/repos/charmbracelet/glow/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo glow.deb "https://github.com/charmbracelet/glow/releases/latest/download/glow_${GLOW_VERSION}_amd64.deb"
    sudo dpkg -i glow.deb
    rm glow.deb
    
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
    # Hstr: History search.
    # Bat: Better cat.
    # Fastfetch: System info.
    # Cmatrix: Matrix screen saver.
    # Btop: Beautiful resource monitor.
    # Lazygit: Terminal UI for Git.
    # Glow: Markdown renderer.
    # Tldr: Simplified man pages.
    if command -v dnf > /dev/null 2>&1; then
        sudo dnf install -y git tmux fzf neovim hstr bat fastfetch cmatrix btop lazygit glow tldr
    else
        sudo yum install -y git tmux fzf neovim hstr bat fastfetch cmatrix btop lazygit glow tldr
    fi
  elif [ -f /etc/arch-release ]; then
    # Arch Linux
    echo "Installing tools via pacman..."
    
    # Tmux: Terminal Multiplexer.
    # Git: Version control.
    # Fzf: Fuzzy finder.
    # Neovim: Modern Vim editor.
    # Hstr: History search.
    # Bat: Better cat.
    # Eza: Modern ls.
    # Fastfetch: System info.
    # Cmatrix: Matrix screen saver.
    # Btop: Beautiful resource monitor.
    # Lazygit: Terminal UI for Git.
    # Glow: Markdown renderer.
    # Tldr: Simplified man pages.
    sudo pacman -Syu --noconfirm git tmux fzf neovim hstr bat eza fastfetch cmatrix btop lazygit glow tldr
  fi
  
  # Install Ubuntu Nerd Font (Linux)
  FONT_DIR="$HOME/.local/share/fonts"
  if [ ! -f "$FONT_DIR/UbuntuNerdFont-Regular.ttf" ]; then
    echo "Installing Ubuntu Nerd Font..."
    mkdir -p "$FONT_DIR"
    curl -fLo "$FONT_DIR/UbuntuNerdFont-Regular.ttf" \
      https://github.com/ryanoasis/nerd-fonts/releases/latest/download/UbuntuNerdFont-Regular.ttf
    if command -v fc-cache >/dev/null 2>&1; then
      fc-cache -f -v
    fi
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

# Symlink dotfiles including starship.toml
echo "Creating symlinks..."
ln -sf "$DOTFILES_DIR/.bash_aliases" "$HOME/.bash_aliases"
ln -sf "$DOTFILES_DIR/.bash_exports" "$HOME/.bash_exports"
ln -sf "$DOTFILES_DIR/.bash_profile" "$HOME/.bash_profile"
ln -sf "$DOTFILES_DIR/.bash_wrappers" "$HOME/.bash_wrappers"
ln -sf "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
ln -sf "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
mkdir -p "$HOME/.config"
ln -sf "$DOTFILES_DIR/.config/starship.toml" "$HOME/.config/starship.toml"

# Symlink Neovim config
mkdir -p "$HOME/.config/nvim"
ln -sf "$DOTFILES_DIR/.config/nvim/init.lua" "$HOME/.config/nvim/init.lua"

# LazyVim will auto-install on first run
echo "Neovim configured with LazyVim. Plugins will install on first launch."


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
