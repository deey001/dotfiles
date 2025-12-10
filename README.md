# Headless Server Dotfiles

A streamlined, modern dotfiles configuration designed for headless servers (Linux/macOS). Optimized for performance, ease of use, and remote development.

**Supported OS**: macOS, Debian/Ubuntu, RHEL/CentOS/Fedora, Arch Linux.

## Features

### 🚀 Modern Shell Experience
- **Starship Prompt**: Minimal, fast, and informative prompt with Tokyo Night theme showing git status, package versions, and execution time. Root user displays in red for safety.
- **Predictive Text**: `ble.sh` provides syntax highlighting, autosuggestions, and Tab autocomplete (like zsh) in pure Bash. Configured for immediate multiline execution (no `Ctrl+J` confirmation).
- **Modern Tools**:
  - `eza` (better `ls` with icons and git status)
  - `bat` / `batcat` (better `cat` with syntax highlighting and Visual Studio Dark+ theme)
  - `zoxide` (smarter `cd` navigation)
  - `fzf` (fuzzy finding for files and history)
  - `hstr` (visual history search)
  - `fastfetch` (system information display with custom config and tree-style formatting)
  - `cmatrix` (matrix screen saver)
  - `btop` (beautiful resource monitor)
  - `lazygit` (terminal UI for Git)
  - `glow` (markdown renderer)
  - `tldr` (simplified man pages)

### 🧹 Minimalist Ubuntu
- **Snap Removal**: On Ubuntu systems, `snapd` is automatically purged to ensure a lightweight, bloat-free environment.

### 📝 Neovim-Only Workflow
- **Neovim v0.11.0**: Installed from official tarball for compatibility. Replaces Vim completely.
- **Aliases**: `vi`, `vim`, and `v` all point to `nvim`.
- **LazyVim**: Pre-configured with modern plugin manager and LSP support.
- **Dynamic Editor**: `EDITOR` environment variable automatically finds nvim installation.

### 💻 Terminal Multiplexing
- **Tmux**: Pre-configured with:
  - Mouse support
  - Split/navigation keybinds
  - **Persistence**: Automatically saves and restores sessions (`tmux-resurrect` + `tmux-continuum`).
  - **Smart fastfetch**: Only displays on initial login, not in new panes.

### 🎨 Theming
- **Starship**: Tokyo Night color scheme with custom icons and formatting
- **Bat**: Visual Studio Dark+ theme for syntax highlighting
- **Nerd Fonts**: Ubuntu Nerd Font for icon support

### 🔧 Cross-Platform Compatibility
- **Distribution Detection**: Automatically detects OS and uses appropriate commands (`bat` vs `batcat`, etc.)
- **Conditional Initialization**: Only loads tools if they're installed (rbenv, zoxide, etc.)
- **Dynamic Paths**: Uses `which` to find executables for maximum portability

## Installation

1.  **Clone**:
    ```bash
    git clone https://github.com/deey001/dotfiles.git ~/dotfiles
    ```
2.  **Install**:
    ```bash
    cd ~/dotfiles && ./install.sh
    ```
    *Installs all dependencies (Neovim v0.11.0, Tmux, Starship, bat themes, fonts, etc.) and sets up symlinks.*

3.  **Finalize**:
    - **Tmux**: Press `Prefix + I` (default `Ctrl+a` then `I`) to install plugins.
    - **Neovim**: LazyVim will auto-install plugins on first launch.
    - **Reload Shell**: Run `source ~/.bashrc` or restart your terminal.

## Uninstallation

Run `./uninstall.sh` to perform a comprehensive cleanup, which supports a full **Factory Reset** of the environment. This script will:

- **Remove Symlinks**: Cleans up all dotfile symlinks (`.bashrc`, `.config/*`, etc.).
- **Remove Configurations**: Deletes config directories for `nvim`, `alacritty`, `bat`, `fastfetch`, and `base16-shell`.
- **Remove Tools**: Deletes `ble.sh` and `Ubuntu Nerd Font`.
- **Remove SSH Key**: Safely removes the specific SSH key added by the installer from `~/.ssh/authorized_keys`.
- **Interactive Package Removal**: Asks if you want to uninstall system packages (neovim, tmux, starship, etc.) to restore the system to its original state.

**Note**: The script handles distribution-specific package managers (apt, dnf, yum, pacman, brew) automatically.

## File Structure

- `.bashrc` - Main bash configuration with tool initialization
- `.bash_aliases` - Command aliases (ll, la, vi, vim, .., h, p, f, etc.)
- `.bash_exports` - Environment variables (EDITOR, BAT_THEME, PATH, history config, etc.)
- `.bash_functions` - Utility functions (extract, mkdirg, up, ftext, distribution, etc.)
- `.bash_wrappers` - Custom functions (colored man pages, whatsgoingon)
- `.bash_profile` - Bash profile for login shells
- `.tmux.conf` - Tmux configuration
- `.config/starship.toml` - Starship prompt configuration (Tokyo Night theme)
- `.config/nvim/init.lua` - Neovim LazyVim configuration
- `.config/bat/themes/` - Bat color themes (Visual Studio Dark+)
- `.config/fastfetch/config.jsonc` - Fastfetch system info configuration
- `.config/alacritty/alacritty.yml` - Alacritty terminal configuration
- `install.sh` - Installation script
- `uninstall.sh` - Uninstallation script
- `.blerc` - ble.sh configuration (disables multiline confirmation)

## SSH Key Installation

The install script automatically installs the SSH public key from `MDC_public.pub` to `~/.ssh/authorized_keys` for easy remote access.

---

Thanks to @deey001 for the initial dotfiles configuration.