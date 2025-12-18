# Headless Server Dotfiles

A streamlined, modern dotfiles configuration designed for headless servers (Linux/macOS). Optimized for performance, ease of use, and remote development.

**Supported OS**: macOS, Debian/Ubuntu, RHEL/CentOS/Fedora, Arch Linux.

## Features

### 🚀 Modern Shell Experience
- **Starship Prompt**: Minimal, fast, and informative prompt with Tokyo Night theme showing git status, package versions, and execution time. Root user displays in red for safety.
- **Predictive Text**: `ble.sh` provides syntax highlighting, autosuggestions, and Tab autocomplete (like zsh) in pure Bash. Configured for immediate multiline execution (no `Ctrl+J` confirmation).
- **Enhanced Readline**: `.inputrc` configuration with intelligent tab completion, case-insensitive matching, and history search
- **Environment Detection**: Automatically detects SSH sessions, WSL, Docker containers, and Tmux for adaptive behavior
- **Modern Tools**:
  - `eza` (better `ls` with icons and git status)
  - `bat` / `batcat` (better `cat` with syntax highlighting and Visual Studio Dark+ theme)
  - `zoxide` (smarter `cd` navigation)
  - `fzf` (fuzzy finding for files and history)
  - `ripgrep` (faster grep)
  - `fd` (faster find)
  - `dust` (better du)
  - `procs` (modern ps)
  - `bottom` (alternative resource monitor)
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
  - Mouse support (toggle with `Prefix + m/M`)
  - Split/navigation keybinds
  - **Pane Synchronization**: Type in all panes at once (`Prefix + S`)
  - **Persistence**: Automatically saves and restores sessions (`tmux-resurrect` + `tmux-continuum`)
  - **Smart fastfetch**: Only displays on initial login, not in new panes
  - **Network Status Bar**: Real-time LAN/VPN/WAN IP display with ISP detection (cached for performance)
  - History limit of 50,000 lines

### 📋 Copy/Paste Workflow (Keyboard Only)
1.  **Enter Copy Mode**: Press `Prefix + [` (Default: `Ctrl-a` then `[`).
    *   You will see a yellow indicator in the top right.
2.  **Navigate**: Use arrow keys (or `h`,`j`,`k`,`l`) to move the cursor to where you want to start copying.
3.  **Start Selection**: Press `v` (visual mode) to begin highlighting text.
4.  **Copy**: Press `y` (yank).
    *   This copies the text to the system clipboard (Windows/Mac) via OSC 52.
    *   It also exits copy mode automatically.
5.  **Paste**: Use `Ctrl+v` (Windows) or `Cmd+v` (Mac) to paste anywhere.


### 🎨 Theming
- **Starship**: Tokyo Night color scheme with custom icons and formatting
- **Bat**: Visual Studio Dark+ theme for syntax highlighting
- **Nerd Fonts**: Ubuntu Nerd Font for icon support

### 🔧 Cross-Platform Compatibility
- **Distribution Detection**: Automatically detects OS and uses appropriate commands (`bat` vs `batcat`, etc.)
- **Conditional Initialization**: Only loads tools if they're installed (rbenv, zoxide, etc.)
- **Dynamic Paths**: Uses `which` to find executables for maximum portability

### 🔐 Configuration & Security
- **Git Configuration**: Pre-configured `.gitconfig` with aliases, colors, and best practices
- **SSH Config Template**: Connection multiplexing, keep-alive, and host shortcuts
- **Secret Management**: `.bash_local` support for machine-specific and private settings
- **Backup on Install**: Existing configs are automatically backed up before installation
- **EditorConfig**: Consistent code formatting across different editors

### 🛠️ Developer Experience
- **Makefile**: Simple commands for installation, testing, and updates
- **Version-Locked Tools**: Critical tools (Neovim) locked to specific versions for stability
- **Testing Suite**: Validation script to verify installation and configuration
- **Brewfile**: Declarative package management for macOS
- **Comprehensive Documentation**: Every config file includes detailed comments and usage examples

## Installation

### Quick Install

1.  **Clone**:
    ```bash
    git clone https://github.com/deey001/dotfiles.git ~/dotfiles
    ```
2.  **Install**:
    ```bash
    cd ~/dotfiles && ./install.sh
    ```
    *Installs all dependencies (Neovim v0.11.0, Tmux, Starship, bat themes, fonts, etc.) and sets up symlinks. Existing configs are backed up automatically.*

3.  **Finalize**:
    - **Tmux**: Press `Prefix + I` (default `Ctrl+a` then `I`) to install plugins.
    - **Neovim**: LazyVim will auto-install plugins on first launch.
    - **Reload Shell**: Run `source ~/.bashrc` or restart your terminal.

### Using Makefile

Alternatively, use the Makefile for easier management:
```bash
cd ~/dotfiles
make install      # Install dotfiles
make test         # Validate installation
make update       # Update from git and reinstall
make help         # Show all available commands
```

## Uninstallation

Run `./uninstall.sh` to perform a comprehensive cleanup, which supports a full **Factory Reset** of the environment. This script will:

- **Remove Symlinks**: Cleans up all dotfile symlinks (`.bashrc`, `.config/*`, etc.).
- **Remove Configurations**: Deletes config directories for `nvim`, `alacritty`, `bat`, `fastfetch`, and `base16-shell`.
- **Remove Tools**: Deletes `ble.sh` and `Ubuntu Nerd Font`.
- **Remove SSH Key**: Safely removes the specific SSH key added by the installer from `~/.ssh/authorized_keys`.
- **Interactive Package Removal**: Asks if you want to uninstall system packages (neovim, tmux, starship, etc.) to restore the system to its original state.

**Note**: The script handles distribution-specific package managers (apt, dnf, yum, pacman, brew) automatically.

## File Structure

### Shell Configuration
- `.bashrc` - Main bash configuration with tool initialization
- `.bash_aliases` - Command aliases (ll, la, vi, vim, .., h, p, f, etc.)
- `.bash_exports` - Environment variables (EDITOR, BAT_THEME, PATH, history config, etc.)
- `.bash_functions` - Utility functions (extract, mkdirg, up, ftext, distribution, etc.)
- `.bash_wrappers` - Custom functions (colored man pages, whatsgoingon)
- `.bash_profile` - Bash profile for login shells
- `.bash_local` - Machine-specific settings (not tracked in git)
- `.inputrc` - Readline configuration with enhanced completion
- `.blerc` - ble.sh configuration (disables multiline confirmation)

### Application Configs
- `.tmux.conf` - Tmux configuration
- `.gitconfig` - Git global configuration
- `.ssh/config` - SSH client configuration template
- `.editorconfig` - Editor formatting rules
- `.config/starship.toml` - Starship prompt configuration (Tokyo Night theme)
- `.config/nvim/init.lua` - Neovim LazyVim configuration
- `.config/bat/themes/` - Bat color themes (Visual Studio Dark+)
- `.config/fastfetch/config.jsonc` - Fastfetch system info configuration
- `.config/alacritty/alacritty.yml` - Alacritty terminal configuration
- `.config/tmux/scripts/` - Tmux status bar scripts

### Management Scripts
- `install.sh` - Installation script with version management
- `uninstall.sh` - Comprehensive uninstallation script
- `test.sh` - Validation and testing script
- `Makefile` - Convenient management commands
- `Brewfile` - macOS package declarations

## Troubleshooting

### 📋 Clipboard Copy Not Working
If the `y` key copy method fails (e.g., text copies inside tmux but doesn't reach your Windows/Mac clipboard):
1.  **Check Terminal Support**: Your terminal **MUST** support **OSC 52**.
    *   **Recommended**: Windows Terminal, Alacritty, iTerm2, WezTerm.
    *   **PuTTY**: Requires "Allow terminal to access clipboard" enabled in settings. If it still fails, PuTTY is likely blocking the escape sequence strictly.
2.  **Test Manually**: Run `~/.config/tmux/scripts/test_copy.sh`.
    *   If this script fails to copy text to your local clipboard, the issue is **Client-Side (Your Terminal)**, not the server setup.

### 📶 Network Icons Missing
- Ensure you have installed a **Nerd Font** (e.g., Ubuntu Nerd Font) on your **local machine** (Windows/Mac) and set it as the terminal font.
- The server installs the font for Linux desktop usage, but your Putty/Terminal needs the font installed locally to render icons.

## SSH Key Installation
The install script automatically installs the SSH public key from `MDC_public.pub` to `~/.ssh/authorized_keys` for easy remote access.

---

Thanks to @deey001 for the initial dotfiles configuration.