#!/bin/bash
set -euo pipefail

# ==============================================================================
# install.sh - Dotfiles Installation and Setup Script
# ==============================================================================
# This script handles the installation of dotfiles, system dependencies, and
# configuration for both online and air-gapped environments.
#
# Key Features:
# - Detects OS (macOS, Linux: Debian/Ubuntu, RHEL/Fedora, Arch)
# - Detects Network Status (Online vs. Air-gapped)
# - Installs core tools: Tmux, Neovim, Git, Starship, etc.
# - Sets up correct symlinks for dotfiles
# - Configures fonts (Nerd Fonts)
# - Backs up existing configs before installation
#
# Tools installed by this script:
#   Core:      git, tmux, neovim, bash-completion, stow
#   Prompt:    starship (cross-shell prompt)
#   Shell:     ble.sh (bash autosuggestions), fzf (fuzzy finder), atuin (history)
#   Nav:       zoxide (smart cd), carapace (completions)
#   Modern:    eza (ls), bat (cat), ripgrep (grep), fd (find), dust (du), duf (df), glow (markdown)
#   Git:       lazygit (TUI)
#   Fonts:     JetBrainsMono Nerd Font
#   Theme:     base16-shell, Catppuccin Mocha
# ==============================================================================

# ------------------------------------------------------------------------------
# Version Configuration
# ------------------------------------------------------------------------------
# Pinned versions for reproducibility — no GitHub API calls at install time.
# To check for updates, visit the GitHub releases page for each tool:

# https://github.com/neovim/neovim/releases
NEOVIM_VERSION="0.11.6"
# https://github.com/starship/starship/releases
STARSHIP_VERSION="1.23.0"
# https://github.com/jesseduffield/lazygit/releases
LAZYGIT_VERSION="0.48.0"
# https://github.com/charmbracelet/glow/releases
GLOW_VERSION="2.1.0"
# https://github.com/carapace-sh/carapace-bin/releases
CARAPACE_VERSION="1.3.0"
# https://github.com/atuinsh/atuin/releases
ATUIN_VERSION="18.4.0"
# https://github.com/eza-community/eza/releases
EZA_VERSION="0.20.22"
# https://github.com/bootandy/dust/releases
DUST_VERSION="1.1.2"
# https://github.com/muesli/duf/releases
DUF_VERSION="0.8.1"
# https://github.com/scop/bash-completion/releases
BASH_COMPLETION_VERSION="2.14.0"
# https://github.com/ajeetdsouza/zoxide/releases
ZOXIDE_VERSION="0.9.6"

# ------------------------------------------------------------------------------
# Configuration Definitions
# ------------------------------------------------------------------------------

# Bootstrap: When run via `curl | bash`, BASH_SOURCE[0] is unbound because
# stdin is a pipe, not a file. We detect this to enter "one-liner mode":
# clone the repo first (the script needs local files for symlinking), then
# re-launch ourselves from the cloned copy so all relative paths work.
if [ -z "${BASH_SOURCE[0]:-}" ]; then
    echo "Running in one-liner mode (piped). Bootstrapping repository..."
    REPO_URL="https://github.com/deey001/dotfiles.git"
    TARGET_DIR="$HOME/dotfiles"
    
    # If the repo already exists, hard-reset to remote to ensure a clean state
    if [ -d "$TARGET_DIR" ]; then
        echo "Target directory $TARGET_DIR already exists. Syncing with remote..."
        cd "$TARGET_DIR"
        git fetch --all
        git reset --hard origin/master
        git clean -fd
    else
        echo "Cloning repository to $TARGET_DIR..."
        git clone "$REPO_URL" "$TARGET_DIR"
        cd "$TARGET_DIR"
    fi
    # exec replaces this process with the cloned script — ensures we never
    # continue running the piped (potentially incomplete) copy from stdin.
    exec bash "$TARGET_DIR/scripts/install.sh" "$@"
fi

# Set the directory where the dotfiles are located (absolute path)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Dotfiles directory detected at: $DOTFILES_DIR"

# Architecture Detection
ARCH=$(uname -m)
OS_TYPE=$(uname -s)
echo "Detected Architecture: $ARCH ($OS_TYPE)"

# Map uname architectures to tool-specific download strings.
# Each tool uses its own naming convention in release URLs:
#   - Neovim/lazygit use raw uname strings (x86_64, arm64)
#   - Go-based tools (glow, carapace, duf) use Go's GOARCH (amd64, arm64)
#   - Rust-based tools (eza, dust) use Rust target triples (x86_64-unknown-linux-gnu)
# We pre-compute all variants here so download URLs stay readable below.
case "$ARCH" in
    x86_64)
        NVIM_ARCH="x86_64"
        LAZYGIT_ARCH="x86_64"
        GLOW_ARCH="amd64"                         # Go convention
        EZA_ARCH="x86_64-unknown-linux-gnu"        # Rust glibc target triple
        DUST_ARCH="x86_64-unknown-linux-musl"      # Rust musl target (static binary)
        DUF_ARCH="x86_64"
        ;;
    aarch64|arm64)
        NVIM_ARCH="arm64"
        LAZYGIT_ARCH="arm64"
        GLOW_ARCH="arm64"                          # Go convention
        EZA_ARCH="aarch64-unknown-linux-gnu"        # Rust glibc target triple
        DUST_ARCH="aarch64-unknown-linux-musl"      # Rust musl target (static binary)
        DUF_ARCH="arm64"
        ;;
    *)
        # Fallback to x86_64 — downloads will likely fail but won't break the script
        echo "Warning: Unsupported architecture $ARCH. Tool installations may fail."
        NVIM_ARCH="x86_64"
        LAZYGIT_ARCH="x86_64"
        GLOW_ARCH="amd64"
        EZA_ARCH="x86_64-unknown-linux-gnu"
        DUST_ARCH="x86_64-unknown-linux-musl"
        DUF_ARCH="x86_64"
        ;;
esac

# Create backup directory with timestamp
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# ------------------------------------------------------------------------------
# Shell Detection
# ------------------------------------------------------------------------------
# Detect the user's active login shell and set flags for conditional setup.
# Both shells get configs symlinked, but only the active shell's dependencies
# are prioritized during package installation.

USER_SHELL="$(basename "$SHELL")"
case "$USER_SHELL" in
    zsh)  ACTIVE_SHELL="zsh"  ;;
    bash) ACTIVE_SHELL="bash" ;;
    *)    ACTIVE_SHELL="bash" ;;  # Default to bash for unknown shells
esac
echo "Detected active shell: $ACTIVE_SHELL ($SHELL)"

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------

# Function: check_internet
# Description: Checks if the system has internet access by sending a single
#              ICMP ping to Google's public DNS (8.8.8.8). Uses ping instead
#              of curl/wget because those may not be installed yet.
# Args:    None
# Returns: 0 if online, 1 if offline (air-gapped mode).
check_internet() {
    echo "Checking internet connectivity..."
    if ping -c 1 8.8.8.8 &> /dev/null; then
        echo "Status: ONLINE"
        return 0
    else
        echo "Status: OFFLINE (Air-gapped mode)"
        return 1
    fi
}

# Function: backup_file
# Description: Backs up a real file or directory before it gets replaced by a
#              symlink. Only backs up regular files/dirs — skips existing
#              symlinks (which are safe to overwrite).
# Args:    $1 - Absolute path to the file or directory to back up
# Returns: Nothing. Creates $BACKUP_DIR on first use.
backup_file() {
    local file="$1"
    # Only back up real files/dirs, not existing symlinks (which are ours)
    if [ -e "$file" ] && [ ! -L "$file" ]; then
        echo "Backing up existing file: $file"
        mkdir -p "$BACKUP_DIR"
        # Use -P to preserve attributes, and create parent dirs in backup
        cp -rP "$file" "$BACKUP_DIR/"
    fi
}

# Cleanup trap: tool installs below create temp directories (mktemp -d) and
# register them in _cleanup_dirs[]. This EXIT trap ensures they're removed
# whether the script succeeds, fails, or is interrupted (Ctrl-C).
_cleanup_dirs=()
cleanup() {
    for dir in "${_cleanup_dirs[@]:-}"; do
        [[ -n "$dir" && -d "$dir" ]] && rm -rf "$dir"
    done
}
trap cleanup EXIT

# ------------------------------------------------------------------------------
# Pre-installation Checks
# ------------------------------------------------------------------------------

# Ensure ~/.local/bin exists — all user-local tool installs (neovim, lazygit,
# starship, etc.) go here to avoid needing sudo. This dir is added to PATH
# by .bash_exports.
mkdir -p "$HOME/.local/bin"

# Check for internet connection to determine installation mode
if check_internet; then
    IS_ONLINE=true
else
    IS_ONLINE=false
fi

# Strict validation of .bashrc before linking — sources the file in a subshell
# to catch syntax errors or segfaults. This prevents a broken .bashrc from
# being symlinked into $HOME, which would lock the user out of their shell.
if [ -f "$DOTFILES_DIR/stow/bash/.bashrc" ]; then
    if ! bash -c ". '$DOTFILES_DIR/stow/bash/.bashrc' 2>/dev/null"; then
        echo "CRITICAL ERROR: .bashrc contains syntax errors or causes a segfault."
        echo "Aborting installation to prevent shell lockout."
        echo "Please fix .bashrc or comment out problematic sections."
        exit 1
    fi
fi

# ------------------------------------------------------------------------------
# Package Installation (OS Dependent)
# ------------------------------------------------------------------------------

OS="$(uname)"
echo "Detected Operating System: $OS"

if [ "$OS" = "Darwin" ]; then
    # ==========================================================================
    # macOS Installation
    # ==========================================================================
    # On macOS, Homebrew handles all packages declaratively via the Brewfile.
    # No manual tool installs needed — brew bundle covers everything.
    if [ "$IS_ONLINE" = true ]; then
        # Install Homebrew if not present
        if ! command -v brew &> /dev/null; then
            echo "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi

        echo "Installing packages via Homebrew Bundle..."
        # Use Brewfile for declarative package management
        if [ -f "$DOTFILES_DIR/Brewfile" ]; then
            brew bundle --file="$DOTFILES_DIR/Brewfile"
        else
            echo "Warning: Brewfile not found at $DOTFILES_DIR/Brewfile."
            echo "Skipping Homebrew package installation."
        fi
    else
        echo "Skipping Homebrew packages (Offline Mode)"
    fi

elif [ "$OS" = "Linux" ]; then
    # ==========================================================================
    # Linux Installation
    # ==========================================================================
    
    # --------------------------------------------------------------------------
    # Debian / Ubuntu
    # --------------------------------------------------------------------------
    # Strategy: install compiler prereqs individually first (resilient on minimal
    # Docker images), then meta-packages, then grouped tool installs.
    if [ -f /etc/debian_version ]; then
        if [ "$IS_ONLINE" = true ]; then
            echo "Updating apt and enabling universe repository..."
            # Enable universe repository — needed on Ubuntu minimal images for
            # packages like build-essential and bzip2 that live outside "main".
            if command -v add-apt-repository >/dev/null 2>&1; then
                sudo add-apt-repository -y universe
            elif grep -qi "ubuntu" /etc/os-release; then
                # Fallback for minimal images without add-apt-repository
                sudo sed -i 's/main$/main universe/' /etc/apt/sources.list || true
            fi
            
            sudo apt update
            
            # 1. Install individual compiler/build prereqs one at a time.
            # These are needed for: Neovim Treesitter (gcc/g++/make), ble.sh (gawk),
            # downloading tools (curl), and extracting archives (xz-utils/tar/unzip).
            # Installing individually avoids meta-package dependency issues on
            # minimal Docker/cloud images.
            echo "Installing individual compiler tools..."
            CORE_TOOLS=(make gcc g++ gawk curl xz-utils tar unzip)
            for pkg in "${CORE_TOOLS[@]}"; do
                if dpkg -s "$pkg" >/dev/null 2>&1; then
                    echo "Prerequisite $pkg is already installed."
                else
                    echo "Installing $pkg..."
                    sudo apt install -y "$pkg" || echo "Warning: Failed to install $pkg."
                fi
            done

            # 2. Meta-packages (build-essential, bzip2) — may fail on minimal images
            # where libc-dev or dpkg-dev aren't available, but the individual tools
            # from step 1 provide enough coverage to continue.
            echo "Attempting to install meta-packages..."
            META_PKGS=(bzip2 build-essential)
            for pkg in "${META_PKGS[@]}"; do
                if dpkg -s "$pkg" >/dev/null 2>&1; then
                    echo "$pkg is already installed."
                else
                    echo "Installing $pkg..."
                    sudo apt install -y "$pkg" || echo "Warning: Optional $pkg failed (continuing as core tools are present)."
                fi
            done
            
            # Attempt to fix broken dependencies if any occurred
            sudo apt install -f -y
            
            echo "Installing tools via apt..."
            # Core tools (shell-agnostic):
            #   tmux       - terminal multiplexer
            #   git        - version control (may already exist from bootstrap)
            #   fzf        - fuzzy finder (used by shell keybindings and nvim)
            #   xclip      - X11 clipboard integration for tmux/neovim yank
            #   hstr       - bash history search replacement (Ctrl-R alternative)
            #   bat        - cat replacement with syntax highlighting (Debian: "bat")
            #   cmatrix    - cosmetic terminal screensaver
            #   btop       - htop replacement (resource monitor)
            #   tldr       - simplified man pages
            #   ncurses-term - extra terminal definitions (e.g. tmux-256color)
            sudo apt install -y tmux git fzf xclip hstr bat cmatrix btop tldr ncurses-term

            # Shell-specific packages: prioritize active shell, install the other
            # shell's plugins as secondary (allowed to fail silently with || true).
            if [ "$ACTIVE_SHELL" = "bash" ]; then
                echo "Active shell is Bash — installing bash-completion..."
                sudo apt install -y bash-completion
                echo "Zsh plugins will also be installed for secondary shell support..."
                sudo apt install -y zsh zsh-syntax-highlighting zsh-autosuggestions 2>/dev/null || true
            else
                echo "Active shell is Zsh — installing zsh plugins..."
                sudo apt install -y zsh zsh-syntax-highlighting zsh-autosuggestions
                echo "Bash completion will also be installed for secondary shell support..."
                sudo apt install -y bash-completion 2>/dev/null || true
            fi

            # ── bash-completion upgrade from source ──────────────────────────
            # BUG: bash-completion 2.11 (shipped in Ubuntu 22.04 / Debian Bookworm)
            # has a bug with bash 5.2+ that causes:
            #   "read: '': not a valid identifier"
            # The fix landed in bash-completion 2.12+.
            #
            # WHAT WE DO: download the release tarball and do a pure file copy
            # into ~/.local/share/bash-completion/ — no compilation needed since
            # bash-completion is entirely shell scripts.
            #
            # HOW IT'S PICKED UP: .bashrc section 11 sources
            # ~/.local/share/bash-completion/bash_completion before the system one,
            # so the fixed version takes priority.
            #
            # Detection: check the local install first, then pkg-config, then dpkg.
            _bc_local_file="$HOME/.local/share/bash-completion/bash_completion"
            _bc_ver=""
            if [ -r "$_bc_local_file" ]; then
                _bc_ver=$(grep -m1 -Eo 'BASH_COMPLETION_VERSINFO=\([0-9]+ [0-9]+' "$_bc_local_file" \
                    | awk -F'[() ]+' '{print $2 "." $3}')
            fi
            if [ -z "$_bc_ver" ]; then
                _bc_ver=$(pkg-config --modversion bash-completion 2>/dev/null || \
                          dpkg -l bash-completion 2>/dev/null | awk '/^ii/{print $3}' | head -1 | cut -d: -f2 | cut -d- -f1 || \
                          echo "0")
            fi
            _bc_major=$(echo "$_bc_ver" | cut -d. -f1)
            _bc_minor=$(echo "$_bc_ver" | cut -d. -f2)
            if [ "${_bc_major:-0}" -lt 2 ] || { [ "${_bc_major:-0}" -eq 2 ] && [ "${_bc_minor:-0}" -lt 12 ]; }; then
                echo "bash-completion ${_bc_ver} < 2.12 detected — upgrading from source..."
                _bc_tmpdir=$(mktemp -d)
                _cleanup_dirs+=("$_bc_tmpdir")
                if curl -fsSL "https://github.com/scop/bash-completion/releases/download/${BASH_COMPLETION_VERSION}/bash-completion-${BASH_COMPLETION_VERSION}.tar.xz" \
                    -o "$_bc_tmpdir/bc.tar.xz"; then
                    tar -xJf "$_bc_tmpdir/bc.tar.xz" -C "$_bc_tmpdir"
                    # Pure file copy — no compilation needed (bash-completion is shell scripts)
                    mkdir -p "$HOME/.local/share/bash-completion/completions"
                    mkdir -p "$HOME/.local/share/bash-completion/helpers"
                    cp "$_bc_tmpdir/bash-completion-${BASH_COMPLETION_VERSION}/bash_completion" \
                       "$HOME/.local/share/bash-completion/"
                    cp -r "$_bc_tmpdir/bash-completion-${BASH_COMPLETION_VERSION}/completions/"* \
                       "$HOME/.local/share/bash-completion/completions/" 2>/dev/null || true
                    if [[ -d "$_bc_tmpdir/bash-completion-${BASH_COMPLETION_VERSION}/helpers" ]]; then
                        cp -r "$_bc_tmpdir/bash-completion-${BASH_COMPLETION_VERSION}/helpers/"* \
                           "$HOME/.local/share/bash-completion/helpers/" 2>/dev/null || true
                    fi
                    echo "bash-completion ${BASH_COMPLETION_VERSION} installed to ~/.local/share/bash-completion/"
                else
                    echo "Warning: bash-completion download failed (ble.sh may not work correctly)"
                fi
            else
                echo "bash-completion ${_bc_ver} >= 2.12 ✓"
            fi
            unset _bc_ver _bc_major _bc_minor _bc_local_file
            
            # ── Neovim (from GitHub release tarball) ─────────────────────────
            # We install from the official tarball rather than apt because the
            # apt version is often outdated and our LazyVim config needs 0.10+.
            # Install target: ~/.local/nvim-linux/ with a symlink in ~/.local/bin/
            # Version check: skip download if the correct version is already present.
            echo "Installing Neovim v${NEOVIM_VERSION} for ${NVIM_ARCH}..."
            if [ ! -f "$HOME/.local/bin/nvim" ] || ! "$HOME/.local/bin/nvim" --version 2>/dev/null | grep -q "^NVIM v${NEOVIM_VERSION}"; then
                echo "Installing/upgrading Neovim to v${NEOVIM_VERSION}..."
                _nvim_tmpdir=$(mktemp -d)
                _cleanup_dirs+=("$_nvim_tmpdir")
                # Download from: https://github.com/neovim/neovim/releases
                curl -fsSL "https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/nvim-linux-${NVIM_ARCH}.tar.gz" \
                    -o "$_nvim_tmpdir/nvim.tar.gz"
                tar -xzf "$_nvim_tmpdir/nvim.tar.gz" -C "$_nvim_tmpdir"
                rm -rf "$HOME/.local/nvim-linux"
                mv "$_nvim_tmpdir/nvim-linux-${NVIM_ARCH}" "$HOME/.local/nvim-linux"
                ln -sf "$HOME/.local/nvim-linux/bin/nvim" "$HOME/.local/bin/nvim"
                echo "Neovim v${NEOVIM_VERSION} installed to ~/.local/"
            fi
            
            # ── fastfetch (system info display) ──────────────────────────────
            # Installed from PPA because the Ubuntu repos lag behind significantly.
            echo "Installing fastfetch..."
            sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch
            sudo apt update
            sudo apt install -y fastfetch
            
            # ── lazygit (Git TUI client) ──────────────────────────────────────
            # Only installs if not already present (no version upgrade check).
            # Install target: ~/.local/bin/ (no sudo needed).
            # Download from: https://github.com/jesseduffield/lazygit/releases
            if ! command -v lazygit >/dev/null 2>&1; then
                echo "Installing lazygit v${LAZYGIT_VERSION}..."
                _lazygit_tmpdir=$(mktemp -d)
                _cleanup_dirs+=("$_lazygit_tmpdir")
                if curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz" \
                    -o "$_lazygit_tmpdir/lazygit.tar.gz"; then
                    tar -xzf "$_lazygit_tmpdir/lazygit.tar.gz" -C "$_lazygit_tmpdir"
                    install -m 755 "$_lazygit_tmpdir/lazygit" "$HOME/.local/bin/"
                    echo "lazygit v${LAZYGIT_VERSION} installed to ~/.local/bin/"
                else
                    echo "Warning: lazygit download failed."
                fi
            fi
            
            # ── glow (terminal Markdown renderer) ─────────────────────────────
            # Download from: https://github.com/charmbracelet/glow/releases
            if ! command -v glow >/dev/null 2>&1; then
                echo "Installing glow v${GLOW_VERSION}..."
                _glow_tmpdir=$(mktemp -d)
                _cleanup_dirs+=("$_glow_tmpdir")
                if curl -fsSL "https://github.com/charmbracelet/glow/releases/download/v${GLOW_VERSION}/glow_${GLOW_VERSION}_Linux_${GLOW_ARCH}.tar.gz" \
                    -o "$_glow_tmpdir/glow.tar.gz"; then
                    tar -xzf "$_glow_tmpdir/glow.tar.gz" -C "$_glow_tmpdir"
                    install -m 755 "$_glow_tmpdir/glow" "$HOME/.local/bin/"
                    echo "glow v${GLOW_VERSION} installed to ~/.local/bin/"
                else
                    echo "Warning: glow download failed."
                fi
            fi

            # ── Additional modern CLI replacements ────────────────────────────
            echo "Installing additional modern tools..."
            # These are available in Ubuntu repos — installed via apt:
            #   ripgrep  - modern grep replacement (rg)
            #   fd-find  - modern find replacement (installed as "fdfind" on Debian)
            #   duf      - modern df replacement (disk usage)
            sudo apt install -y ripgrep fd-find duf

            # ── zoxide (smart cd replacement) ────────────────────────────────
            # Direct binary download — not available in older Ubuntu repos.
            # Uses Rust musl static binary for portability.
            # Zoxide uses raw uname arch strings (x86_64, aarch64).
            if ! command -v zoxide >/dev/null 2>&1; then
                echo "Installing Zoxide v${ZOXIDE_VERSION}..."
                _zoxide_tmpdir=$(mktemp -d)
                _cleanup_dirs+=("$_zoxide_tmpdir")
                ZOXIDE_ARCH="$ARCH"
                [[ "$ZOXIDE_ARCH" == "aarch64" ]] && ZOXIDE_ARCH="aarch64"
                [[ "$ZOXIDE_ARCH" == "x86_64" ]] && ZOXIDE_ARCH="x86_64"
                curl -fsSL "https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-${ZOXIDE_ARCH}-unknown-linux-musl.tar.gz" \
                    -o "$_zoxide_tmpdir/zoxide.tar.gz" && \
                tar -xzf "$_zoxide_tmpdir/zoxide.tar.gz" -C "$_zoxide_tmpdir" && \
                install -m 755 "$_zoxide_tmpdir/zoxide" "$HOME/.local/bin/" && \
                echo "Zoxide installed to ~/.local/bin/" || \
                echo "Warning: Zoxide install failed."
            fi

            # ── eza (modern ls replacement) ───────────────────────────────────
            # Not in Ubuntu repos — direct binary download.
            # Uses Rust glibc target triple (e.g. x86_64-unknown-linux-gnu).
            # Download from: https://github.com/eza-community/eza/releases
            if ! command -v eza >/dev/null 2>&1; then
                echo "Installing eza v${EZA_VERSION}..."
                _eza_tmpdir=$(mktemp -d)
                _cleanup_dirs+=("$_eza_tmpdir")
                if curl -fsSL "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_${EZA_ARCH}.tar.gz" \
                    -o "$_eza_tmpdir/eza.tar.gz"; then
                    tar -xzf "$_eza_tmpdir/eza.tar.gz" -C "$_eza_tmpdir"
                    install -m 755 "$_eza_tmpdir/eza" "$HOME/.local/bin/"
                    echo "eza v${EZA_VERSION} installed to ~/.local/bin/"
                else
                    echo "Warning: eza download failed."
                fi
            fi

            # ── dust (modern du replacement) ──────────────────────────────────
            # Not in Ubuntu repos — direct binary download.
            # Uses Rust musl static binary for portability.
            # Download from: https://github.com/bootandy/dust/releases
            if ! command -v dust >/dev/null 2>&1; then
                echo "Installing dust v${DUST_VERSION}..."
                _dust_tmpdir=$(mktemp -d)
                _cleanup_dirs+=("$_dust_tmpdir")
                if curl -fsSL "https://github.com/bootandy/dust/releases/download/v${DUST_VERSION}/dust-v${DUST_VERSION}-${DUST_ARCH}.tar.gz" \
                    -o "$_dust_tmpdir/dust.tar.gz"; then
                    tar -xzf "$_dust_tmpdir/dust.tar.gz" -C "$_dust_tmpdir"
                    install -m 755 "$_dust_tmpdir/dust-v${DUST_VERSION}-${DUST_ARCH}/dust" "$HOME/.local/bin/"
                    echo "dust v${DUST_VERSION} installed to ~/.local/bin/"
                else
                    echo "Warning: dust download failed."
                fi
            fi

            # ── fd symlink (Debian/Ubuntu quirk) ──────────────────────────────
            # Debian/Ubuntu packages fd-find as "fdfind" to avoid a name conflict
            # with the fdclone package. Create a "fd" symlink in ~/.local/bin/ so
            # aliases and scripts can use the standard name.
            if command -v fdfind >/dev/null 2>&1 && [ ! -f "$HOME/.local/bin/fd" ]; then
                mkdir -p "$HOME/.local/bin"
                ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
                echo "Created fd symlink at ~/.local/bin/fd"
            fi

            # Wayland clipboard support (only needed on Wayland sessions)
            if [ -n "${WAYLAND_DISPLAY:-}" ]; then
                sudo apt install -y wl-clipboard
            fi
        else
            echo "Offline Mode: Attempting to install available packages from cache/CD..."
            sudo apt install -y tmux git fzf xclip bash-completion hstr bat cmatrix btop || echo "Some packages failed to install in offline mode."
        fi

    # --------------------------------------------------------------------------
    # RHEL / CentOS / Fedora
    # --------------------------------------------------------------------------
    # Uses dnf (modern) or yum (legacy) depending on what's available.
    # EPEL is enabled on RHEL/CentOS for access to additional packages.
    elif [ -f /etc/redhat-release ]; then
        echo "Installing tools via dnf/yum..."
        # Prefer dnf over yum (dnf is the modern replacement on Fedora/RHEL 8+)
        PKG_MANAGER="yum"
        command -v dnf > /dev/null 2>&1 && PKG_MANAGER="dnf"

        if [ "$IS_ONLINE" = true ]; then
            # EPEL (Extra Packages for Enterprise Linux) — needed on RHEL/CentOS
            # for packages not in the base repos (e.g., bat, hstr, neovim).
            if grep -qi "centos\|rhel" /etc/redhat-release; then
                sudo $PKG_MANAGER install -y epel-release
            fi

            # Core tools + build tools (gcc/g++/make needed by Treesitter for
            # parser compilation). RHEL/Fedora repos tend to have newer versions
            # of most tools, so we can install more directly via the package manager.
            sudo $PKG_MANAGER install -y git tmux fzf neovim hstr bat fastfetch cmatrix btop lazygit glow tldr ripgrep fd-find unzip gcc gcc-c++ make gawk

            # Shell-specific packages (same pattern as Debian: primary + secondary)
            if [ "$ACTIVE_SHELL" = "bash" ]; then
                echo "Active shell is Bash — zsh plugins installed as secondary..."
                sudo $PKG_MANAGER install -y zsh zsh-syntax-highlighting zsh-autosuggestions 2>/dev/null || true
            else
                echo "Active shell is Zsh — installing zsh plugins..."
                sudo $PKG_MANAGER install -y zsh zsh-syntax-highlighting zsh-autosuggestions
            fi

            # Modern tools not in RHEL/CentOS repos — direct binary downloads.
            # All install to ~/.local/bin/ (no sudo needed).

            # zoxide (smart cd replacement)
            if ! command -v zoxide >/dev/null 2>&1; then
                echo "Installing Zoxide v${ZOXIDE_VERSION}..."
                _zoxide_tmpdir=$(mktemp -d)
                _cleanup_dirs+=("$_zoxide_tmpdir")
                ZOXIDE_ARCH="$ARCH"
                [[ "$ZOXIDE_ARCH" == "aarch64" ]] && ZOXIDE_ARCH="aarch64"
                [[ "$ZOXIDE_ARCH" == "x86_64" ]] && ZOXIDE_ARCH="x86_64"
                curl -fsSL "https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-${ZOXIDE_ARCH}-unknown-linux-musl.tar.gz" \
                    -o "$_zoxide_tmpdir/zoxide.tar.gz" && \
                tar -xzf "$_zoxide_tmpdir/zoxide.tar.gz" -C "$_zoxide_tmpdir" && \
                install -m 755 "$_zoxide_tmpdir/zoxide" "$HOME/.local/bin/" && \
                echo "Zoxide installed to ~/.local/bin/" || \
                echo "Warning: Zoxide install failed."
            fi

            # eza (modern ls replacement — not in RHEL repos)
            if ! command -v eza >/dev/null 2>&1; then
                echo "Installing eza v${EZA_VERSION}..."
                _eza_tmpdir=$(mktemp -d)
                _cleanup_dirs+=("$_eza_tmpdir")
                if curl -fsSL "https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_${EZA_ARCH}.tar.gz" \
                    -o "$_eza_tmpdir/eza.tar.gz"; then
                    tar -xzf "$_eza_tmpdir/eza.tar.gz" -C "$_eza_tmpdir"
                    install -m 755 "$_eza_tmpdir/eza" "$HOME/.local/bin/"
                    echo "eza v${EZA_VERSION} installed to ~/.local/bin/"
                else
                    echo "Warning: eza download failed."
                fi
            fi

            # dust (modern du replacement — not in RHEL repos)
            if ! command -v dust >/dev/null 2>&1; then
                echo "Installing dust v${DUST_VERSION}..."
                _dust_tmpdir=$(mktemp -d)
                _cleanup_dirs+=("$_dust_tmpdir")
                if curl -fsSL "https://github.com/bootandy/dust/releases/download/v${DUST_VERSION}/dust-v${DUST_VERSION}-${DUST_ARCH}.tar.gz" \
                    -o "$_dust_tmpdir/dust.tar.gz"; then
                    tar -xzf "$_dust_tmpdir/dust.tar.gz" -C "$_dust_tmpdir"
                    install -m 755 "$_dust_tmpdir/dust-v${DUST_VERSION}-${DUST_ARCH}/dust" "$HOME/.local/bin/"
                    echo "dust v${DUST_VERSION} installed to ~/.local/bin/"
                else
                    echo "Warning: dust download failed."
                fi
            fi

            # duf (modern df replacement — not in RHEL repos)
            # Download from: https://github.com/muesli/duf/releases
            if ! command -v duf >/dev/null 2>&1; then
                echo "Installing duf v${DUF_VERSION}..."
                _duf_tmpdir=$(mktemp -d)
                _cleanup_dirs+=("$_duf_tmpdir")
                if curl -fsSL "https://github.com/muesli/duf/releases/download/v${DUF_VERSION}/duf_${DUF_VERSION}_linux_${DUF_ARCH}.tar.gz" \
                    -o "$_duf_tmpdir/duf.tar.gz"; then
                    tar -xzf "$_duf_tmpdir/duf.tar.gz" -C "$_duf_tmpdir"
                    install -m 755 "$_duf_tmpdir/duf" "$HOME/.local/bin/"
                    echo "duf v${DUF_VERSION} installed to ~/.local/bin/"
                else
                    echo "Warning: duf download failed."
                fi
            fi

            # Create fd symlink if needed
            if command -v fdfind >/dev/null 2>&1 && [ ! -f "$HOME/.local/bin/fd" ]; then
                mkdir -p "$HOME/.local/bin"
                ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
            fi
        else
            echo "Offline Mode: Installing what is available..."
            sudo $PKG_MANAGER install -y git tmux fzf neovim hstr bat || true
        fi

    # --------------------------------------------------------------------------
    # Arch Linux
    # --------------------------------------------------------------------------
    # Arch has most modern tools in official repos — minimal manual installs.
    # AUR helpers (yay/paru) are used for packages not in the official repos.
    elif [ -f /etc/arch-release ]; then
        echo "Installing tools via pacman..."
        if [ "$IS_ONLINE" = true ]; then
            # Core tools + modern replacements in one command.
            # Arch repos are bleeding-edge so most tools are available directly.
            # base-devel provides compilers (gcc, make, etc) needed for
            # Neovim Treesitter parser compilation.
            sudo pacman -Syu --noconfirm base-devel git tmux fzf neovim eza fastfetch btop ripgrep fd dust duf zoxide unzip gawk

            # Shell-specific packages (same pattern as Debian/RHEL)
            if [ "$ACTIVE_SHELL" = "bash" ]; then
                echo "Active shell is Bash — zsh plugins installed as secondary..."
                sudo pacman -S --noconfirm zsh zsh-syntax-highlighting zsh-autosuggestions 2>/dev/null || true
            else
                echo "Active shell is Zsh — installing zsh plugins..."
                sudo pacman -S --noconfirm zsh zsh-syntax-highlighting zsh-autosuggestions
            fi
            
            # Optional tools — these move between official repos and AUR frequently,
            # so we try them one-by-one. If an AUR helper (yay/paru) is detected,
            # it can install from the AUR; otherwise we fall back to pacman.
            echo "Attempting to install optional modern tools (hstr, lazygit, glow, tldr, etc)..."
            OPTIONAL_TOOLS=(hstr lazygit glow tldr)
            
            # Detect AUR helper
            AUR_HELPER=""
            if command -v yay >/dev/null 2>&1; then AUR_HELPER="yay"; elif command -v paru >/dev/null 2>&1; then AUR_HELPER="paru"; fi

            for tool in "${OPTIONAL_TOOLS[@]}"; do
                if ! command -v "$tool" >/dev/null 2>&1; then
                    echo "Installing $tool..."
                    if [ -n "$AUR_HELPER" ]; then
                        $AUR_HELPER -S --noconfirm "$tool"
                    else
                        sudo pacman -S --noconfirm "$tool" || echo "Warning: $tool not found in official repositories and no AUR helper (yay/paru) detected."
                    fi
                fi
            done
        else
            echo "Offline Mode: Updating skipped."
        fi
    fi

    # --------------------------------------------------------------------------
    # Fonts (Linux)
    # --------------------------------------------------------------------------
    # JetBrainsMono Nerd Font — required for icons in starship, eza, nvim, etc.
    # Downloaded from: https://github.com/ryanoasis/nerd-fonts/releases
    # Installed to ~/.local/share/fonts/ (user-local, no sudo needed).
    if [ "$IS_ONLINE" = true ]; then
        FONT_DIR="$HOME/.local/share/fonts"
        if [ ! -d "$FONT_DIR/JetBrainsMono" ]; then
            echo "Installing JetBrainsMono Nerd Font..."
            mkdir -p "$FONT_DIR"
            cd "$FONT_DIR"
            curl -fLo JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
            unzip -q -o JetBrainsMono.zip -d JetBrainsMono
            rm JetBrainsMono.zip
            cd - > /dev/null
            if command -v fc-cache >/dev/null 2>&1; then
                fc-cache -f -v
            fi
        fi
    fi

    # --------------------------------------------------------------------------
    # Starship Prompt Installation
    # --------------------------------------------------------------------------
    # Direct binary download (no curl|bash pipe) — uses Rust musl static binary.
    # Starship uses raw uname arch strings (x86_64, aarch64) in its release URLs.
    # Install target: ~/.local/bin/ (no sudo needed).
    if [ "$IS_ONLINE" = true ]; then
        if ! command -v starship >/dev/null 2>&1; then
            echo "Installing Starship v${STARSHIP_VERSION}..."
            _starship_tmpdir=$(mktemp -d)
            _cleanup_dirs+=("$_starship_tmpdir")
            STARSHIP_ARCH="$ARCH"
            [[ "$STARSHIP_ARCH" == "aarch64" ]] && STARSHIP_ARCH="aarch64"
            [[ "$STARSHIP_ARCH" == "x86_64" ]] && STARSHIP_ARCH="x86_64"
            curl -fsSL "https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-${STARSHIP_ARCH}-unknown-linux-musl.tar.gz" \
                -o "$_starship_tmpdir/starship.tar.gz" && \
            tar -xzf "$_starship_tmpdir/starship.tar.gz" -C "$_starship_tmpdir" && \
            install -m 755 "$_starship_tmpdir/starship" "$HOME/.local/bin/" && \
            echo "Starship installed to ~/.local/bin/" || \
            echo "Warning: Starship install failed."
        fi
    fi

    # --------------------------------------------------------------------------
    # Carapace - Multi-shell completion engine
    # --------------------------------------------------------------------------
    # Direct binary download (no curl|bash pipe) — Go binary.
    # Carapace uses Go GOARCH naming: amd64 (not x86_64), arm64 (not aarch64).
    # Install target: ~/.local/bin/ (no sudo needed).
    if [ "$IS_ONLINE" = true ]; then
        if ! command -v carapace >/dev/null 2>&1; then
            echo "Installing Carapace v${CARAPACE_VERSION}..."
            _carapace_tmpdir=$(mktemp -d)
            _cleanup_dirs+=("$_carapace_tmpdir")
            # Map uname arch → Go GOARCH convention
            CARAPACE_ARCH="$ARCH"
            [[ "$CARAPACE_ARCH" == "x86_64" ]] && CARAPACE_ARCH="amd64"
            [[ "$CARAPACE_ARCH" == "aarch64" ]] && CARAPACE_ARCH="arm64"
            # Download from: https://github.com/carapace-sh/carapace-bin/releases
            curl -fsSL "https://github.com/carapace-sh/carapace-bin/releases/download/v${CARAPACE_VERSION}/carapace-bin_${CARAPACE_VERSION}_linux_${CARAPACE_ARCH}.tar.gz" \
                -o "$_carapace_tmpdir/carapace.tar.gz" && \
            tar -xzf "$_carapace_tmpdir/carapace.tar.gz" -C "$_carapace_tmpdir" && \
            install -m 755 "$_carapace_tmpdir/carapace" "$HOME/.local/bin/" && \
            echo "Carapace installed to ~/.local/bin/" || \
            echo "Warning: Carapace install failed."
        fi
    fi

    # --------------------------------------------------------------------------
    # Atuin - Magical Shell History (SQLite-backed, cross-machine sync)
    # --------------------------------------------------------------------------
    # Direct binary download (no curl|bash pipe) — Rust musl static binary.
    # Atuin uses raw uname arch strings (x86_64, aarch64).
    # Install target: ~/.local/bin/ (no sudo needed).
    # Note: Atuin archives contain a nested directory, so we use `find` to
    # locate the binary rather than assuming a fixed path inside the tarball.
    if [ "$IS_ONLINE" = true ]; then
        if ! command -v atuin >/dev/null 2>&1; then
            echo "Installing Atuin v${ATUIN_VERSION}..."
            _atuin_tmpdir=$(mktemp -d)
            _cleanup_dirs+=("$_atuin_tmpdir")
            ATUIN_ARCH="$ARCH"
            [[ "$ATUIN_ARCH" == "aarch64" ]] && ATUIN_ARCH="aarch64"
            [[ "$ATUIN_ARCH" == "x86_64" ]] && ATUIN_ARCH="x86_64"
            if curl -fsSL "https://github.com/atuinsh/atuin/releases/download/v${ATUIN_VERSION}/atuin-v${ATUIN_VERSION}-${ATUIN_ARCH}-unknown-linux-musl.tar.gz" \
                -o "$_atuin_tmpdir/atuin.tar.gz"; then
                tar -xzf "$_atuin_tmpdir/atuin.tar.gz" -C "$_atuin_tmpdir"
                _atuin_bin=$(find "$_atuin_tmpdir" -name "atuin" -type f ! -name "*.tar*" -print -quit 2>/dev/null || true)
                if [[ -n "${_atuin_bin:-}" ]]; then
                    install -m 755 "$_atuin_bin" "$HOME/.local/bin/"
                    echo "Atuin v${ATUIN_VERSION} installed to ~/.local/bin/"
                else
                    echo "Warning: Could not find atuin binary in downloaded archive."
                fi
            else
                echo "Warning: Atuin download failed."
            fi
        fi
    fi
    
else
    echo "Unsupported OS: $OS"
    exit 1
fi

# ------------------------------------------------------------------------------
# Helper Tool Installation (ble.sh, TPM)
# ------------------------------------------------------------------------------

# ble.sh — Bash Line Editor: provides fish-like autosuggestions, syntax
# highlighting, and enhanced line editing for Bash. Requires bash and make
# (build tools installed above). Built from master source via a helper script
# because the nightly release tarball was stale/broken.
# Prerequisites: bash, make, gawk (installed in the package sections above).
# Config: ~/.blerc (symlinked by stow).
if [ "$IS_ONLINE" = true ] && command -v bash >/dev/null 2>&1 && command -v make >/dev/null 2>&1; then
    if [ ! -f "$HOME/.local/share/blesh/ble.sh" ]; then
        echo "Installing ble.sh from source..."
        bash "$(dirname "$0")/install-blesh.sh" || echo "Warning: ble.sh install failed, skipping."
    fi
fi

# Base16 Shell — terminal color scheme framework.
# Provides 256-color themes; .bashrc activates Catppuccin Mocha via base16_*.
if [ "$IS_ONLINE" = true ] && [ ! -d "$HOME/.config/base16-shell" ]; then
    echo "Cloning base16-shell for color themes..."
    rm -rf "$HOME/.config/base16-shell"
    git clone https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell
fi

# Tmux Plugin Manager (TPM) — manages tmux plugins declared in .tmux.conf.
# After install, press prefix + I inside tmux to fetch plugins.
if [ "$IS_ONLINE" = true ] && [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "Cloning Tmux Plugin Manager..."
    rm -rf "$HOME/.tmux/plugins/tpm"
    mkdir -p "$HOME/.tmux/plugins"
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# ------------------------------------------------------------------------------
# Dotfiles Symlinking & Setup
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Dotfiles Symlinking via GNU Stow
# ------------------------------------------------------------------------------
# GNU Stow creates symlinks from stow/<pkg>/<file> → ~/<file>.
# Each subdirectory under stow/ is a "package" (e.g., stow/bash/.bashrc → ~/.bashrc).
#
# Key flags (set in .stowrc at the repo root):
#   --dir=stow      Source directory for packages
#   --target=~      Symlinks are created in $HOME
#   --no-folding    CRITICAL: prevents stow from replacing an entire directory
#                   with a symlink. Without this, stow would symlink ~/.config/nvim/
#                   as a single link, which breaks when other tools write into it.
#
# --restow = unstow + stow in one step. This makes the operation idempotent:
# stale symlinks from removed files are cleaned up, and new ones are created.

# Install stow if not present
if ! command -v stow &>/dev/null; then
    echo "Installing GNU Stow..."
    if [ "$OS" = "Darwin" ]; then
        brew install stow
    elif command -v apt &>/dev/null; then
        sudo apt install -y stow
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y stow
    elif command -v yum &>/dev/null; then
        sudo yum install -y stow
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm stow
    else
        echo "ERROR: Cannot install stow automatically. Install it manually and re-run."
        exit 1
    fi
fi

echo "Stowing dotfiles..."
echo "Active shell: $ACTIVE_SHELL"

# ── Migration: remove old-style symlinks pointing to dots/ or .config/ ────────
# Before stow was adopted, install.sh created direct symlinks (e.g.,
# ~/.bashrc → dotfiles/dots/.bashrc). Stow refuses to replace symlinks it
# didn't create. This loop detects any symlink whose target points into the
# old dots/ or .config/ paths and removes it so stow can take ownership.
echo "Checking for legacy symlinks to migrate..."
_old_paths=("$DOTFILES_DIR/dots" "$DOTFILES_DIR/.config")
_stow_targets=(
    "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.bash_aliases"
    "$HOME/.bash_exports" "$HOME/.bash_functions" "$HOME/.bash_wrappers"
    "$HOME/.blerc" "$HOME/.zshrc" "$HOME/.tmux.conf" "$HOME/.inputrc"
    "$HOME/.gitconfig" "$HOME/.gitattributes" "$HOME/.editorconfig"
    "$HOME/.config/starship.toml"
    "$HOME/.config/nvim/init.lua" "$HOME/.config/nvim/lua"
    "$HOME/.config/tmux/scripts"
    "$HOME/.config/bat/themes"
    "$HOME/.config/atuin/config.toml"
    "$HOME/.config/fastfetch/config.jsonc"
    "$HOME/.config/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.yml"
)
for target in "${_stow_targets[@]}"; do
    if [ -L "$target" ]; then
        link_dest=$(readlink "$target")
        for old_path in "${_old_paths[@]}"; do
            if [[ "$link_dest" == "$old_path"* ]]; then
                echo "  Removing legacy symlink: $target -> $link_dest"
                rm "$target"
                break
            fi
        done
    fi
done
unset _old_paths _stow_targets target link_dest old_path

# ── Backup real (non-symlink) files that would conflict with stow ──────────────
# Stow will refuse to create a symlink if a real file exists at the target.
# Back up these files to $BACKUP_DIR and remove them so stow can proceed.
for dotfile in .bashrc .bash_profile .bash_aliases .bash_exports .bash_functions \
               .bash_wrappers .blerc .zshrc .tmux.conf .inputrc .gitconfig .editorconfig; do
    if [ -f "$HOME/$dotfile" ] && [ ! -L "$HOME/$dotfile" ]; then
        echo "Backing up existing file: $HOME/$dotfile"
        mkdir -p "$BACKUP_DIR"
        cp -P "$HOME/$dotfile" "$BACKUP_DIR/"
        rm "$HOME/$dotfile"
    fi
done

# Core packages — deployed to all machines (servers + workstations)
STOW_PKGS=(bash zsh git shell tmux nvim starship bat atuin fastfetch)

# Workstation-only packages — only add on macOS or Linux with a display server.
# Headless servers don't need GUI terminal emulator configs.
if [ "$OS" = "Darwin" ] || [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
    STOW_PKGS+=(alacritty)
fi

echo "Packages: ${STOW_PKGS[*]}"

# --restow = unstow then stow (removes stale symlinks, idempotent for re-runs).
# .stowrc at repo root provides: --dir=stow --target=$HOME --no-folding
cd "$DOTFILES_DIR"
stow --restow "${STOW_PKGS[@]}"

# Rebuild bat theme cache after Catppuccin theme dir is symlinked into place.
# On Debian/Ubuntu, bat is installed as "batcat" due to a name conflict.
if command -v bat &>/dev/null; then
    bat cache --build
elif command -v batcat &>/dev/null; then
    batcat cache --build
fi

# Ensure tmux scripts are executable (stow preserves permissions but be explicit)
chmod +x "$DOTFILES_DIR/stow/tmux/.config/tmux/scripts/"*.sh

echo "Symlinks created via GNU Stow."

# ── SSH Config (handled separately from stow) ─────────────────────────────────
# SSH is NOT managed by stow because:
#   1. OpenSSH requires strict permissions on ~/.ssh/ (700) and config files (600)
#   2. Stow symlinks would create files owned by the user but in a directory
#      that might not have the right permissions
#   3. Some SSH clients refuse to use config files that are symlinks or have
#      group/other read permissions
# Instead, we manually symlink just the config file and set permissions explicitly.
if [ ! -d "$HOME/.ssh" ]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
fi
# Sockets directory for SSH ControlMaster multiplexing
if [ ! -d "$HOME/.ssh/sockets" ]; then
    mkdir -p "$HOME/.ssh/sockets"
    chmod 700 "$HOME/.ssh/sockets"
fi
if [ -f "$DOTFILES_DIR/.ssh/config" ]; then
    # Back up existing config if it's a real file (not our symlink)
    if [ -f "$HOME/.ssh/config" ] && [ ! -L "$HOME/.ssh/config" ]; then
        mkdir -p "$BACKUP_DIR"
        cp "$HOME/.ssh/config" "$BACKUP_DIR/ssh_config"
    fi
    # Symlink and lock down permissions to 600 (required by OpenSSH)
    ln -sf "$DOTFILES_DIR/.ssh/config" "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"
fi

# ------------------------------------------------------------------------------
# SSH Key Installation
# ------------------------------------------------------------------------------
# Appends the MDC public key to authorized_keys for passwordless SSH access.
# Uses grep -F (fixed string) to avoid duplicate entries on re-runs.
SSH_KEY_SOURCE="$DOTFILES_DIR/.ssh/MDC_public.pub"
if [ -f "$SSH_KEY_SOURCE" ]; then
    echo "Installing SSH key to authorized_keys..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    # Append key only if it doesn't exist
    if ! grep -q -F "$(cat "$SSH_KEY_SOURCE")" "$HOME/.ssh/authorized_keys" 2>/dev/null; then
        cat "$SSH_KEY_SOURCE" >> "$HOME/.ssh/authorized_keys"
        chmod 600 "$HOME/.ssh/authorized_keys"
        echo "SSH key added."
    else
        echo "SSH key already present."
    fi
else
    echo "Warning: SSH key ($SSH_KEY_SOURCE) not found. Skipping."
fi

# ------------------------------------------------------------------------------
# Final Initialization
# ------------------------------------------------------------------------------

# Reload active shell profile
if [ "$ACTIVE_SHELL" = "bash" ]; then
    source "$HOME/.bash_profile" 2>/dev/null || true
fi

echo "=============================================================================="
echo "Installation Complete!"
echo "Notes:"
echo "1. Restart your terminal or run 'exec $ACTIVE_SHELL' to apply changes."
echo "2. If using Tmux, press 'prefix + I' to install plugins."
echo "3. For machine-specific settings, create ~/.bash_local (auto-sourced)"
if [ -d "$BACKUP_DIR" ]; then
    echo "4. Existing configs backed up to: $BACKUP_DIR"
fi
if [ "$IS_ONLINE" = false ]; then
    echo "Warning: Installation completed in OFFLINE mode. Some tools/fonts may be missing."
fi
echo "=============================================================================="

echo "INSTALLATION COMPLETE!"
echo ""
if [ "$(uname)" = "Darwin" ]; then
    echo "NOTICE FOR macOS USERS:"
    echo "Terminal.app does not allow automatic font changes via scripts."
    echo "To see icons, you MUST manually set the font:"
    echo "  1. Open Terminal Settings (Cmd + ,)"
    echo "  2. Go to Profiles -> Text -> Font"
    echo "  3. Click 'Change' and select 'JetBrainsMono Nerd Font'"
    echo ""
fi
echo "To apply shell changes immediately, please RESTART your terminal or run:"
if [ "$ACTIVE_SHELL" = "zsh" ]; then
    echo "  source ~/.zshrc   (active shell)"
    echo "  bash              (to switch to Bash temporarily)"
else
    echo "  source ~/.bashrc  (active shell)"
    echo "  zsh               (to switch to Zsh temporarily)"
fi
echo ""
echo "If icons are not showing, ensure your Terminal is set to use 'JetBrainsMono Nerd Font'."
echo "=============================================================================="
