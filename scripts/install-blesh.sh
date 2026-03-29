#!/bin/bash
# ==============================================================================
# install-blesh.sh — Install ble.sh (Bash Line Editor) from source
# ==============================================================================
# ble.sh adds syntax highlighting, autosuggestions, and improved line editing
# to Bash — similar to what zsh-syntax-highlighting/zsh-autosuggestions do for
# Zsh. It is sourced from .bashrc via the .blerc configuration file.
#
# USAGE:
#   bash ~/dotfiles/scripts/install-blesh.sh
#
# WHAT IT DOES:
#   1. Checks for an existing ble.sh installation and attempts in-place update
#   2. Falls back to a fresh clone-and-build if the update fails
#   3. Installs to ~/.local/share/blesh/ (PREFIX=~/.local)
#
# DEPENDENCIES:
#   • make   — drives the build process
#   • gawk   — required by ble.sh's build system for code generation
#   • git    — clones the repository and its submodules
#
# PREREQUISITES (bash 5.2 compatibility):
#   • bash-completion >= 2.12 — older versions trigger a "read: '': not a
#     valid identifier" error because they pass an empty variable name to
#     `read`. This was an upstream bug in bash-completion, not ble.sh.
#   • fzf >= 0.61 — older versions hit a failglob + __fzf_list_hosts bug
#     that causes errors when ble.sh is active.
#
# CONFIGURATION:
#   ble.sh reads ~/.blerc for customization (keybindings, theme, features).
#   See stow/bash/.blerc in this repo.
#
# IMPROVEMENT SUGGESTIONS:
#   TODO: Pin to a specific ble.sh release tag instead of cloning master.
#         This would make builds reproducible across machines and avoid
#         surprise breakage from upstream nightly changes.
#         Example: git clone --branch v0.4.0-devel3 --depth 1 ...
#   TODO: Add checksum/signature verification after cloning to ensure the
#         source hasn't been tampered with (git verify-tag or sha256sum).
#   TODO: Consider caching the built artifacts to speed up reinstalls.
# ==============================================================================
set -euo pipefail

# ==============================================================================
# Update Path — try to update an existing installation in-place first.
# ble.sh ships with a built-in --update flag that pulls the latest changes
# without a full rebuild. This is faster and preserves any local patches.
# ==============================================================================
if [[ -f "$HOME/.local/share/blesh/ble.sh" ]]; then
    echo "Updating existing ble.sh installation..."
    # If --update succeeds, we're done — no need for a full rebuild
    bash "$HOME/.local/share/blesh/ble.sh" --update && exit 0
    # --update can fail if the install was corrupted or the git history is missing
    echo "ble --update failed, falling back to fresh install..."
fi

# ==============================================================================
# Fresh Install Path — clone from source, build, and install
# ==============================================================================

REPO="https://github.com/akinomyoga/ble.sh.git"
TMPDIR=$(mktemp -d)
# Clean up the temp directory on exit regardless of success or failure
trap "rm -rf $TMPDIR" EXIT

# Remove the old installation so the build installs cleanly
echo "Removing old ble.sh..."
rm -rf "$HOME/.local/share/blesh"

# ---- Prerequisite checks ----------------------------------------------------
# Both make and gawk must be present before we attempt the build.
# We check explicitly so the user gets a clear error message instead of a
# cryptic build failure halfway through.

if ! command -v make >/dev/null 2>&1; then
    echo "Error: 'make' is required. Install with: sudo apt install make"
    exit 1
fi

if ! command -v gawk >/dev/null 2>&1; then
    echo "Error: 'gawk' is required. Install with: sudo apt install gawk"
    exit 1
fi

# ---- Clone -------------------------------------------------------------------
# --recursive pulls submodules (ble.sh uses them for contrib scripts)
# --depth 1 and --shallow-submodules keep the clone small (~15 MB vs ~80 MB)
echo "Cloning ble.sh master (with submodules)..."
git clone --recursive --depth 1 --shallow-submodules \
    "$REPO" "$TMPDIR/ble.sh"

# ---- Build & Install ---------------------------------------------------------
# PREFIX=~/.local installs the runtime to ~/.local/share/blesh/ which is the
# standard XDG-compliant location. No sudo required.
echo "Building and installing to ~/.local..."
make -C "$TMPDIR/ble.sh" install PREFIX="$HOME/.local"

# ---- Verification ------------------------------------------------------------
# Extract the installed version string for confirmation output
BLE_VER=$(grep -o "BLE_VERSION=[^ ;]*" "$HOME/.local/share/blesh/ble.sh" 2>/dev/null | head -1 || echo "unknown")
echo ""
echo "Done! Version: ${BLE_VER}"
echo "Run: source ~/.bashrc && echo \$BLE_VERSION"
