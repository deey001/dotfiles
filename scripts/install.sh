#!/bin/bash
# ==============================================================================
# install.sh — Dotfiles Bootstrapper for macOS / Linux / RHEL
# ==============================================================================
#
# DESCRIPTION
#   Single-script bootstrapper that detects your OS, installs required system
#   packages via the native package manager, ensures GNU Stow is available,
#   then uses Stow to symlink every tracked dotfile package into $HOME.
#
# USAGE
#   One-liner (curl-pipe, remote bootstrap):
#     curl -fsSL https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.sh | bash
#
#   Local clone (after `git clone`):
#     make install          # runs this script via the repo Makefile
#     bash scripts/install.sh
#
# EXECUTION ORDER
#   1. Detect execution context  – curl-pipe vs. local clone
#   2. Clone the repo if needed  – only when piped from curl
#   3. Detect OS & architecture  – Darwin / Linux (Debian, Arch, RHEL)
#   4. Install system packages   – via Homebrew / apt / pacman / dnf|yum
#   5. Ensure GNU Stow exists    – install if missing
#   6. Stow dotfile packages     – symlink bash, zsh, git, shell, tmux, config
#
# DEPENDENCIES
#   bash  – version 4+ recommended (macOS ships bash 3; Homebrew provides bash 5)
#   git   – required to clone the repo when piped from curl
#   curl  – required only for the one-liner remote bootstrap
#   sudo  – required on Linux to install packages as root
#
# EXIT BEHAVIOUR  (set -euo pipefail)
#   -e           Exit immediately on any non-zero command return code.
#   -u           Treat unset variables as errors (prevents silent empty-string expansions).
#   -o pipefail  A pipeline fails if *any* command in it fails, not just the last.
#   Together these three flags make the script "fail fast" so partial installs
#   are caught early rather than producing a silently broken environment.
#
# SUPPORTED PLATFORMS
#   macOS                  – packages installed via Homebrew (Brewfile)
#   Debian / Ubuntu        – packages installed via apt  (meta/packages/ubuntu.txt)
#   Arch Linux             – packages installed via pacman (meta/packages/arch.txt)
#   RHEL / Fedora / CentOS – packages installed via dnf (preferred) or yum
#                            (meta/packages/rhel.txt)
#
# ==============================================================================

# ── 1. Execution Context Detection ─────────────────────────────────────────────
#
# We need to know WHERE the script is — either it was cloned to disk and executed
# directly, or it was piped straight from `curl` and has no path on disk yet.
#
# Why check BASH_SOURCE here?
#   • When run via `bash scripts/install.sh`, BASH_SOURCE[0] == the file path and
#     $0 == the file path, so they are equal → we are running from a local clone.
#   • When piped via `curl ... | bash`, bash reads from stdin; the script is never
#     written to disk.  BASH_SOURCE[0] is either empty ("") or unset because there
#     is no backing file.  The `:-` default-expansion guards handle both sub-cases.
#   • The `else` branch is reached only when BASH_SOURCE has a real path that
#     differs from $0 — meaning the script was sourced from inside the repo —
#     so we can safely derive the repo root via dirname traversal.

if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]] || [[ "${BASH_SOURCE[0]:-}" == "" ]]; then
    # Running from curl-pipe or a direct `bash install.sh` invocation outside the repo.
    # Point DOTFILES_DIR at the canonical location under $HOME.
    DOTFILES_DIR="$HOME/dotfiles"
    if [ ! -d "$DOTFILES_DIR" ]; then
        # Repo hasn't been cloned yet — fetch it now so the rest of the script can
        # reference package lists, the Brewfile, and stow packages that live inside it.
        echo "--- Cloning dotfiles repository... ---"
        git clone https://github.com/deey001/dotfiles.git "$DOTFILES_DIR"
    fi
else
    # Running via `make install` or sourced from inside the repo.
    # Walk up one level from the scripts/ directory to reach the repo root.
    DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# ── 2. Strict Mode ─────────────────────────────────────────────────────────────
#
# Placed AFTER the repo-clone block above intentionally: `set -u` would turn the
# BASH_SOURCE empty-variable check into a hard error before we've had a chance to
# handle it gracefully with the `:-` default-expansion guards above.
set -euo pipefail

# ── 3. Environment Detection ────────────────────────────────────────────────────
#
# Capture both CPU architecture and kernel name so platform-specific package
# install commands can be routed to the correct package manager below.
# $ARCH is available for future use (e.g. arm64-specific Homebrew paths on Apple Silicon).

ARCH=$(uname -m)    # e.g. x86_64, arm64, aarch64
OS_RAW="$(uname)"   # raw kernel name before normalisation

# Normalise the kernel name into a simple, stable token used throughout the script.
# MINGW / MSYS / CYGWIN covers Git-for-Windows and Cygwin environments on Windows.
case "$OS_RAW" in
    Darwin)               OS="Darwin" ;;
    Linux)                OS="Linux" ;;
    MINGW*|MSYS*|CYGWIN*) OS="Windows" ;;
    *)                    OS="Unknown" ;;
esac

# ── 4. Helper Functions ─────────────────────────────────────────────────────────

# install_package_list <list_file> <install_cmd>
#
# Reads a plain-text package manifest (one package per line; lines beginning with
# # or empty lines are ignored), then passes all packages to <install_cmd> in a
# single invocation.
#
# Why batch all packages into one command?
#   A single `apt install -y pkg1 pkg2 …` is substantially faster than N separate
#   install calls because it acquires the apt lock only once, resolves dependencies
#   in one pass, and downloads packages in parallel.  It also prevents "partial
#   upgrade" states that can occur when the lock is released between calls on
#   systems where background processes also use the package manager.
install_package_list() {
    local list_file="$1"
    local install_cmd="$2"

    # Bail silently if the package list doesn't exist.  This lets the repo omit
    # platform-specific files without breaking installs on other platforms.
    if [ ! -f "$list_file" ]; then return 1; fi

    echo "--- Installing system dependencies from $(basename "$list_file") ---"

    # Strip comment lines (^#) and blank lines (^$), then collapse newlines into
    # spaces so the whole list can be passed as positional args to the install cmd.
    local pkgs
    pkgs=$(grep -v '^#' "$list_file" | grep -v '^$' | tr '\n' ' ')

    # Guard against an empty package list — most package managers error out when
    # invoked with no arguments, which would abort the script under `set -e`.
    if [ -n "$pkgs" ]; then $install_cmd $pkgs; fi
}

# ── 5. System Package Installation ─────────────────────────────────────────────
#
# The OS token detected above drives the top-level Darwin / Linux split.
# On Linux, the presence of well-known distro marker files under /etc drives the
# inner split — these files are stable across distro versions and don't require
# parsing /etc/os-release (which has inconsistent quoting across distros).

if [ "$OS" = "Darwin" ]; then
    echo "--- Detected macOS ---"

    # Homebrew is the de-facto standard package manager on macOS.
    # If it isn't installed, pull down and run the official installer.
    # `command -v` is preferred over `which` because it's a shell built-in and
    # respects the current PATH without spawning a subprocess.
    command -v brew &>/dev/null || \
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # `brew bundle` reads the Brewfile and idempotently installs every formula,
    # cask, and Mac App Store (mas) entry declared there — one declarative manifest
    # for the entire macOS toolchain.
    [ -f "$DOTFILES_DIR/Brewfile" ] && brew bundle --file="$DOTFILES_DIR/Brewfile"

elif [ "$OS" = "Linux" ]; then

    if [ -f /etc/debian_version ]; then
        # ── Debian / Ubuntu ────────────────────────────────────────────────────
        echo "--- Detected Debian/Ubuntu ---"

        # Refresh the package index before installing so we get current version
        # metadata and don't fail on packages that have been renamed or moved
        # since the last index refresh.
        sudo apt update

        # Install the full declarative package list from the repo.
        install_package_list "$DOTFILES_DIR/meta/packages/ubuntu.txt" "sudo apt install -y"

        # Neovim is listed separately because the apt universe version is often
        # several major releases behind upstream.  Naming it explicitly here makes
        # it easy to later swap for a PPA or snap without editing the package list.
        sudo apt install -y neovim

    elif [ -f /etc/arch-release ]; then
        # ── Arch Linux ─────────────────────────────────────────────────────────
        echo "--- Detected Arch Linux ---"

        # -Syu syncs the package database AND upgrades all installed packages before
        # installing the new ones.  On Arch (rolling release) installing without
        # upgrading first risks a "partial upgrade" state that can break packages.
        install_package_list "$DOTFILES_DIR/meta/packages/arch.txt" "sudo pacman -Syu --noconfirm"

    elif [ -f /etc/redhat-release ]; then
        # ── RHEL / Fedora / CentOS ─────────────────────────────────────────────
        echo "--- Detected RHEL/Fedora/CentOS ---"

        # dnf is the modern successor to yum (Fedora 22+, RHEL 8+, CentOS Stream).
        # Fall back to yum for older systems (CentOS 7 / RHEL 7) where dnf is absent.
        if command -v dnf &>/dev/null; then
            install_package_list "$DOTFILES_DIR/meta/packages/rhel.txt" "sudo dnf install -y"
        else
            install_package_list "$DOTFILES_DIR/meta/packages/rhel.txt" "sudo yum install -y"
        fi
    fi
fi

# ── 6. GNU Stow — The Symlink Engine ───────────────────────────────────────────
#
# GNU Stow manages dotfile symlinks by mirroring the directory tree inside each
# stow "package" into a target directory ($HOME).  This keeps the dotfiles repo
# clean and lets multiple machines share identical tracked files without copying.
#
# Why install Stow here rather than relying solely on the package lists?
#   Stow may already be present (installed above via a package list).  This block
#   is a safety-net install for cases where the platform list doesn't include it
#   or for a new machine that has no list yet.  `command -v stow` short-circuits
#   the entire block when Stow is already on PATH.

command -v stow &>/dev/null || {
    echo "Installing GNU Stow..."
    # Each line tests for its own distro marker independently so multiple guards
    # could fire safely — in practice only one will match.
    [ -f /etc/debian_version ]  && sudo apt install -y stow
    [ -f /etc/arch-release ]    && sudo pacman -S --noconfirm stow
    [ -f /etc/redhat-release ]  && {
        command -v dnf &>/dev/null && sudo dnf install -y stow || sudo yum install -y stow
    }
}

# ── 7. Stow Dotfile Packages ────────────────────────────────────────────────────
#
# Each entry in STOW_PKGS corresponds to a subdirectory under stow/ in the repo.
# The directory tree inside each package mirrors $HOME exactly, so Stow can
# create the correct symlinks without additional path configuration.
#
# Package breakdown:
#   bash    – .bashrc, .bash_profile, .bash_aliases, .blerc
#   zsh     – .zshrc, .zprofile (if present)
#   git     – .gitconfig, .gitignore_global
#   shell   – .inputrc, .common_shell (shared aliases/functions sourced by both shells)
#   tmux    – .tmux.conf
#   config  – .config/ subtree (starship.toml, nvim/, and other XDG config dirs)

echo "--- Symlinking Configurations via GNU Stow ---"
STOW_PKGS=(bash zsh git shell tmux config)

# Change to the repo root so Stow resolves the --dir relative path correctly.
cd "$DOTFILES_DIR"

for pkg in "${STOW_PKGS[@]}"; do
    echo "  Stowing: $pkg"
    # -R (restow) removes and recreates all symlinks for the package.
    # This cleanly handles files that were moved within a package — a plain `stow`
    # would leave dangling symlinks that the new run would refuse to overwrite.
    # --dir=stow   tells Stow where to find packages (the stow/ subdirectory).
    # --target=$HOME tells Stow where symlinks should be created.
    stow -R --dir=stow --target="$HOME" "$pkg"
done

echo "======================================================================"
echo "INSTALLATION PROCESS FINISHED!"
echo "======================================================================"
