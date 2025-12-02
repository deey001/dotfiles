# Headless Server Dotfiles

A streamlined, modern dotfiles configuration designed for headless servers (Linux/macOS). Optimized for performance, ease of use, and remote development.

**Supported OS**: macOS, Debian/Ubuntu, RHEL/CentOS/Fedora, Arch Linux.

## Features

### 🚀 Modern Shell Experience
- **Starship Prompt**: Minimal, fast, and informative prompt showing git status, package versions, and execution time.
- **Predictive Text**: `ble.sh` provides syntax highlighting and autosuggestions (like zsh) in pure Bash.
- **Modern Tools**:
  - `eza` (better `ls` with icons and git status)
  - `bat` (better `cat` with syntax highlighting)
  - `zoxide` (smarter `cd` navigation)
  - `fzf` (fuzzy finding for files and history)
  - `hstr` (visual history search)
  - `cmatrix` (matrix screen saver)
  - `btop` (beautiful resource monitor)
  - `lazygit` (terminal UI for Git)
  - `glow` (markdown renderer)
  - `tldr` (simplified man pages)

### 🧹 Minimalist Ubuntu
- **Snap Removal**: On Ubuntu systems, `snapd` is automatically purged to ensure a lightweight, bloat-free environment.

### 📝 Neovim-Only Workflow
- **Neovim**: Replaces Vim completely. Aliases `vi` and `vim` point to `nvim`.
- **Plugins**: Pre-configured with Packer, Treesitter (syntax), Telescope (fuzzy find), LSP, and Autocomplete.

### 💻 Terminal Multiplexing
- **Tmux**: Pre-configured with:
  - Mouse support
  - Split/navigation keybinds
  - **Persistence**: Automatically saves and restores sessions (`tmux-resurrect` + `tmux-continuum`).

## Installation

1.  **Clone**:
    ```bash
    git clone https://github.com/deey001/dotfiles.git ~/dotfiles
    ```
2.  **Install**:
    ```bash
    cd ~/dotfiles && ./install.sh
    ```
    *Installs all dependencies (Neovim, Tmux, Starship, etc.) and sets up symlinks.*

3.  **Finalize**:
    - **Tmux**: Press `Prefix + I` (default `Ctrl+a` then `I`) to install plugins.
    - **Neovim**: Open `nvim` and run `:PackerSync` (if not auto-triggered).

## Uninstallation
Run `./uninstall.sh` to remove symlinks. This will remove all symlinks created by the install script.