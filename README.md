# Headless Server Dotfiles

A streamlined, modern dotfiles configuration designed for headless servers (Linux/macOS). Optimized for performance, ease of use, and remote development.

**Supported OS**: macOS, Debian/Ubuntu, RHEL/CentOS/Fedora, Arch Linux.

## Features

### 🚀 Modern Shell Experience
- **Starship Prompt**: Minimal, fast, and informative prompt with Tokyo Night theme showing git status, package versions, and execution time. Root user displays in red for safety.
- **Predictive Text**: `ble.sh` provides syntax highlighting, autosuggestions, and Tab autocomplete (like zsh) in pure Bash. Configured for immediate multiline execution (no `Ctrl+J` confirmation).
- **Enhanced Readline**: `.inputrc` configuration with intelligent tab completion, case-insensitive matching, and history search
- **Environment Detection**: Automatically detects SSH sessions, WSL, Docker containers, and Tmux for adaptive behavior
- **Modern CLI Tools** (with fallback aliases to original commands):
  - `eza` - Better `ls` with icons and git status (alias: `oldls` for original)
  - `bat`/`batcat` - Better `cat` with syntax highlighting and Visual Studio Dark+ theme (alias: `oldcat`)
  - `zoxide` - Smarter `cd` that learns your navigation patterns (alias: `cd`)
  - `fzf` - Fuzzy finder for files and command history
  - `ripgrep` (`rg`) - Faster grep that respects .gitignore
  - `fd` - Faster find with simpler syntax (alias: `oldfind`)
  - `dust` - Better `du` with tree visualization (alias: `olddu`)
  - `duf` - Better `df` with colorful output (alias: `olddf`)
  - `procs` - Modern `ps` with colors and tree view (alias: `oldps`)
  - `btop` - Beautiful resource monitor (alias: `oldtop`)
  - `bottom` - Alternative resource monitor
  - `hstr` - Visual history search with reverse-i-search
  - `fastfetch` - System information display with custom config
  - `cmatrix` - Matrix-style screensaver
  - `lazygit` - Terminal UI for Git operations
  - `glow` - Beautiful markdown renderer
  - `tldr` - Simplified man pages with practical examples

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

### Windows Users: Local Setup First! ⚠️

**If you're connecting from Windows (PuTTY/Windows Terminal), run the local setup FIRST** to install Nerd Fonts and configure your terminal. Otherwise, icons won't display!

#### One-Liner Install (Recommended) ⚡

Open **PowerShell as Administrator** and run:

```powershell
irm "https://raw.githubusercontent.com/deey001/dotfiles/master/install.ps1" | iex
```

**Interactive menu with options:**
- `[1]` Install Nerd Fonts only
- `[2]` Configure Windows Terminal only
- `[3]` Configure PuTTY Default Settings (works with KeePass!)
- `[4]` Full Setup (fonts + all terminals)
- `[5]` Install dotfiles on remote server
- `[6]` Complete workflow (local + remote)
- `[7]` Remove configuration (reset to default)
- `[8]` Restore from backup

**Features:**
- ✅ Color-coded status indicators
- ✅ Detects installed components automatically
- ✅ Modifies PuTTY Default Settings (all KeePass connections inherit)
- ✅ No individual session configuration needed
- ✅ Idempotent (safe to run multiple times)
- ✅ **Automatic backups before any changes**
- ✅ **Restore previous settings anytime**

#### Option 2: Download and Run

1.  **Download**: Clone or download this repo to your Windows machine
2.  **Run**: Right-click `setup-windows.bat` → **Run as Administrator**
3.  **Follow Prompts**: Uses the same interactive menu

#### Option 3: Manual Setup

1.  **Install Font Manually**:
    - Download [UbuntuMono Nerd Font](https://github.com/ryanoasis/nerd-fonts/releases/latest/download/UbuntuMono.zip)
    - Extract and install all `.ttf` files (right-click → Install)

2.  **Configure Terminal**:
    - **Windows Terminal**: Settings → Profiles → Defaults → Font Face → "UbuntuMono Nerd Font"
    - **PuTTY**: Window → Appearance → Font → "UbuntuMono Nerd Font"

3.  **Connect and Install** (see Quick Install below)

---

### Quick Install (Server-Side)

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

## Modern CLI Tools Usage Guide

All modern tools are automatically installed by `install.sh` and are available immediately after installation. Each tool replaces a standard Unix command with a modern, feature-rich alternative. The original commands are still accessible via `old*` aliases.

### 📁 File Listing: `eza` (replaces `ls`)

**What it does**: Modern replacement for `ls` with icons, git status, and colors.

**Why use it**: Shows file icons, git modification status, and uses colors to distinguish file types at a glance.

**Examples**:
```bash
# Basic listing with icons (same as 'ls')
eza

# Long format with all files (same as 'ls -la')
ll

# List with git status indicators
eza --git

# Tree view of directory structure
eza --tree --level=2

# Sort by modification time
eza -l --sort=modified

# Use original ls if needed
oldls -la
```

**Auto-configured**: The `cd` command automatically shows an `eza` listing when you change directories.

---

### 📄 File Viewing: `bat` (replaces `cat`)

**What it does**: Display file contents with syntax highlighting, line numbers, and git integration.

**Why use it**: Makes reading code files easier with automatic language detection and syntax highlighting.

**Examples**:
```bash
# View a file with syntax highlighting (same as 'cat')
cat file.js

# View with line numbers
bat -n file.py

# Show git modifications
bat --diff file.sh

# Plain output without decorations
bat --style=plain config.json

# Use original cat if needed
oldcat file.txt
```

**Theme**: Pre-configured with "Visual Studio Dark+" theme (set in `.bash_exports`).

---

### 🚀 Smart Navigation: `zoxide` (replaces `cd`)

**What it does**: Learns your most-used directories and lets you jump to them with partial names.

**Why use it**: No need to type full paths. After visiting a directory once, jump to it from anywhere.

**Examples**:
```bash
# First time: use full path
cd ~/Projects/dotfiles

# Later: jump using just part of the name
cd dot        # Goes to ~/Projects/dotfiles

# Jump to most frecent directory matching "config"
cd conf       # Might go to ~/.config

# Interactive selection if multiple matches
cd -i proj    # Shows menu of matching directories

# List all tracked directories with scores
zoxide query -l

# Remove a directory from database
zoxide remove ~/old/path
```

**How it learns**: Every `cd` command is tracked. Directories you visit frequently rank higher.

---

### 🔍 File Search: `fd` (replaces `find`)

**What it does**: Fast, user-friendly file finder with sensible defaults.

**Why use it**: Simpler syntax than `find`, respects `.gitignore`, and much faster.

**Examples**:
```bash
# Find all .js files (same as complex 'find' command)
fd '\.js$'

# Find by name (case-insensitive by default)
fd readme

# Find in specific directory
fd config /etc

# Find and execute command
fd '\.txt$' --exec wc -l

# Find hidden files too
fd -H config

# Search only directories
fd -t d dotfiles

# Use original find if needed
oldfind . -name "*.txt"
```

**Note**: On Debian/Ubuntu, installed as `fdfind` but symlinked to `fd` at `~/.local/bin/fd`.

---

### 📊 Disk Usage: `dust` (replaces `du`)

**What it does**: Visualize disk usage with a tree display and percentages.

**Why use it**: Instantly see which directories consume the most space.

**Examples**:
```bash
# Show disk usage of current directory (same as 'du')
dust

# Limit tree depth
dust -d 2

# Show only top 15 entries
dust -n 15

# Reverse sort (smallest first)
dust -r

# Show apparent size instead of disk usage
dust -b

# Use original du if needed
olddu -sh *
```

**Visual**: Shows bars and percentages, making it easy to spot large directories.

---

### 💾 Disk Space: `duf` (replaces `df`)

**What it does**: Display disk usage with colors, sorting, and filtering.

**Why use it**: Cleaner output with colors and automatic filtering of pseudo filesystems.

**Examples**:
```bash
# Show all mounted filesystems (same as 'df')
duf

# Show only local filesystems (hides tmpfs, devtmpfs, etc.)
duf --only local

# Sort by usage
duf --sort usage

# Show specific filesystem
duf /home

# JSON output for scripting
duf --json

# Use original df if needed
olddf -h
```

**Auto-filtered**: Hides clutter like `/dev`, `/proc`, `/sys` by default.

---

### ⚙️ Process Viewer: `procs` (replaces `ps`)

**What it does**: Modern process viewer with colors, tree view, and better defaults.

**Why use it**: Easier to read, supports filtering, and shows process tree relationships.

**Examples**:
```bash
# Show all processes (same as 'ps aux')
procs

# Filter by name
procs firefox

# Show process tree
procs --tree

# Sort by CPU usage
procs --sortd cpu

# Sort by memory
procs --sortd mem

# Watch mode (refresh every 2 seconds)
procs --watch

# Use original ps if needed
oldps aux
```

**Colored output**: Different colors for users, states, and resource usage.

---

### 📈 System Monitor: `btop` (replaces `top`)

**What it does**: Beautiful, interactive resource monitor with mouse support.

**Why use it**: Modern interface with graphs, colors, and easy navigation.

**Examples**:
```bash
# Launch system monitor (same as 'top')
btop

# Inside btop:
# - Arrow keys: Navigate
# - F2: Options menu
# - Mouse: Click to interact
# - q: Quit
```

**Features**: CPU/memory graphs, network stats, disk I/O, process management.

**Alternative**: `bottom` is also installed (run with `btm` command).

---

### 🔎 Code Search: `ripgrep` (use as `rg`)

**What it does**: Blazing-fast search that respects `.gitignore` and shows colored matches.

**Why use it**: Much faster than `grep`, automatically skips hidden files and git-ignored paths.

**Examples**:
```bash
# Search for pattern in current directory
rg "function"

# Search with case-insensitive
rg -i "error"

# Search specific file types
rg -t js "import"

# Search and show context (3 lines before/after)
rg -C 3 "TODO"

# Search hidden files too
rg --hidden "secret"

# List file types
rg --type-list
```

**Note**: The `grep` alias still uses traditional grep with colors for compatibility.

---

### 📜 Command History: `hstr`

**What it does**: Visual, searchable command history browser.

**Why use it**: Quickly find and re-run previous commands with interactive search.

**Examples**:
```bash
# Launch history search (alias: hh)
hstr

# Inside hstr:
# - Type to filter commands
# - Arrow keys to navigate
# - Enter to select and run
# - Tab to select and edit
# - Ctrl-/ to toggle regex search
```

**Keybinding**: Can also be bound to `Ctrl-r` for reverse-i-search replacement.

---

### 🔧 Git Interface: `lazygit`

**What it does**: Terminal UI for git with keyboard shortcuts and visual interface.

**Why use it**: Manage branches, commits, diffs, and merges without memorizing git commands.

**Examples**:
```bash
# Launch in current repository
lazygit

# Inside lazygit:
# - 1-5: Switch between panels (Status, Files, Branches, Commits, Stash)
# - Space: Stage/unstage files
# - c: Commit
# - p: Pull
# - P: Push
# - x: Show command menu
# - q: Quit
```

**Features**: Interactive rebasing, cherry-picking, stashing, and conflict resolution.

---

### 📖 Quick Help: `tldr`

**What it does**: Community-driven man pages with practical examples.

**Why use it**: Get straight to examples without reading lengthy man pages.

**Examples**:
```bash
# Get examples for tar command
tldr tar

# Get examples for git
tldr git-commit

# Update tldr cache
tldr --update

# List all available pages
tldr --list
```

**Philosophy**: "Too Long; Didn't Read" - simplified, example-focused documentation.

---

### 📝 Markdown Viewer: `glow`

**What it does**: Render markdown files beautifully in the terminal.

**Why use it**: Read README files, documentation, and notes with proper formatting.

**Examples**:
```bash
# Render a markdown file
glow README.md

# Pager mode (like less)
glow -p CHANGELOG.md

# Fetch and render from URL
glow https://raw.githubusercontent.com/user/repo/main/README.md

# Interactive file browser
glow .
```

**Use cases**: Reading GitHub READMEs locally, previewing markdown before committing.

---

### 🎨 System Info: `fastfetch`

**What it does**: Display system information with logo and stats.

**Why use it**: Quick system overview on login or for screenshots.

**Examples**:
```bash
# Show system info
fastfetch

# Use different logo
fastfetch --logo arch

# JSON output
fastfetch --format json

# Show specific modules
fastfetch --config none --structure Title:Separator:OS:Kernel:Uptime
```

**Auto-run**: Configured to display on login shells (not in tmux panes).

---

### 🎬 Matrix Effect: `cmatrix`

**What it does**: Fun Matrix-style falling characters screensaver.

**Why use it**: Look cool or use as a screensaver.

**Examples**:
```bash
# Start the Matrix
cmatrix

# Asynchronous scroll
cmatrix -a

# Bold characters
cmatrix -b

# Custom color (green, red, blue, yellow, etc.)
cmatrix -C blue

# Quit with Ctrl-C
```

**Just for fun**: Not a productivity tool, but great for impressing people.

---

### 🔄 Accessing Original Commands

All replaced commands are still accessible via `old*` aliases:

```bash
oldcat file.txt     # Use original cat
oldfind . -name "*" # Use original find
olddu -sh *         # Use original du
olddf -h            # Use original df
oldps aux           # Use original ps
oldtop              # Use original top
```

This ensures scripts and workflows that depend on original command behavior still work.

---

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

## Technical Implementation Details

### Modern Tools Installation

All modern CLI tools are installed automatically by [install.sh](install.sh) with cross-platform support:

#### macOS (Homebrew)
- **Package Manager**: Uses [Brewfile](Brewfile) for declarative package management
- **Tools**: All modern tools available via `brew install`
- **Fonts**: Ubuntu Nerd Font via `brew install --cask font-ubuntu-nerd-font`

#### Debian/Ubuntu (apt)
- **Core Tools**: Installed from official repositories (`ripgrep`, `fd-find`, `duf`)
- **Binary Releases**: Tools not in repos installed from GitHub releases:
  - `zoxide` - From official install script
  - `eza` - Latest x86_64 Linux tarball
  - `dust` - Latest x86_64 musl tarball
- **Font Fix**: Ubuntu Nerd Font downloaded as `.zip` and extracted to `~/.local/share/fonts/Ubuntu/`
- **fd Symlink**: `fdfind` → `~/.local/bin/fd` (added to PATH in [.bash_exports:5](.bash_exports#L5))

#### RHEL/CentOS/Fedora (dnf/yum)
- **EPEL Repository**: Automatically enabled for RHEL/CentOS to access more packages
- **Core Tools**: Installed from EPEL repositories when available
- **Binary Releases**: Same as Ubuntu for tools not in repos
- **duf Installation**: Uses `.rpm` package from GitHub releases

#### Arch Linux (pacman)
- **All in One**: All modern tools available in official repos
- **Single Command**: `pacman -Syu` installs everything

### Alias System

All modern tools have conditional aliases in [.bash_aliases](.bash_aliases#L33-L82):

```bash
# Example: duf replaces df, but keeps original accessible
if command -v duf >/dev/null 2>&1; then
    alias df='duf'      # Modern command
    alias olddf='/bin/df'  # Original command
fi
```

**Why this approach?**
- ✅ Modern tools work seamlessly (just type `df` to get `duf`)
- ✅ Original commands still accessible (`olddf` for scripts)
- ✅ Graceful degradation (if tool not installed, uses original)
- ✅ No conflicts with system scripts that depend on original behavior

### PATH Configuration

The [.bash_exports:5](.bash_exports#L5) adds `~/.local/bin` to PATH:

```bash
export PATH="$PATH:$HOME/bin:$HOME/.local/bin"
```

**Why needed?**
- Ubuntu installs `fd-find` as `/usr/bin/fdfind` (naming conflict)
- Install script creates symlink: `~/.local/bin/fd` → `/usr/bin/fdfind`
- This PATH entry makes the `fd` command work system-wide

### Theme Configuration

- **bat theme**: Set to "Visual Studio Dark+" in [.bash_exports:42](.bash_exports#L42)
- **Starship theme**: Tokyo Night colors in [.config/starship.toml](.config/starship.toml)
- **Nerd Font**: Ubuntu Nerd Font for icons (installed on all platforms)

### Auto-listing on `cd`

The [.bash_functions](.bash_functions#L150-L156) overrides `cd` to auto-list:

```bash
cd() {
    if [ -n "$1" ]; then
        builtin cd "$@" && if command -v eza > /dev/null 2>&1; then eza -lha --icons; else ls -lhsA; fi
    else
        builtin cd ~ && if command -v eza > /dev/null 2>&1; then eza -lha --icons; else ls -lhsA; fi
    fi
}
```

**Why?** Automatically shows directory contents after changing directories (saves typing `ls`).

---

Thanks to @deey001 for the initial dotfiles configuration.