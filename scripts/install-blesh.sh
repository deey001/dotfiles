#!/bin/bash
# install-blesh.sh — Install ble.sh nightly from source
# Usage: bash ~/dotfiles/scripts/install-blesh.sh
#
# Prerequisites for bash 5.2 compatibility:
#   • bash-completion >= 2.12 (fixes empty read var name bug)
#   • fzf >= 0.61             (fixes failglob + __fzf_list_hosts bug)
#   Both were upstream bugs in those tools, not ble.sh. Once they are updated,
#   the "read: '': not a valid identifier" error on bash 5.2 is gone.
set -euo pipefail

# Update existing installation if available
if [[ -f "$HOME/.local/share/blesh/ble.sh" ]]; then
    echo "Updating existing ble.sh installation..."
    bash "$HOME/.local/share/blesh/ble.sh" --update && exit 0
    echo "ble --update failed, falling back to fresh install..."
fi

REPO="https://github.com/akinomyoga/ble.sh.git"
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo "Removing old ble.sh..."
rm -rf "$HOME/.local/share/blesh"

if ! command -v make >/dev/null 2>&1; then
    echo "Error: 'make' is required. Install with: sudo apt install make"
    exit 1
fi

if ! command -v gawk >/dev/null 2>&1; then
    echo "Error: 'gawk' is required. Install with: sudo apt install gawk"
    exit 1
fi

echo "Cloning ble.sh master (with submodules)..."
git clone --recursive --depth 1 --shallow-submodules \
    "$REPO" "$TMPDIR/ble.sh"

echo "Building and installing to ~/.local..."
make -C "$TMPDIR/ble.sh" install PREFIX="$HOME/.local"

BLE_VER=$(grep -o "BLE_VERSION=[^ ;]*" "$HOME/.local/share/blesh/ble.sh" 2>/dev/null | head -1 || echo "unknown")
echo ""
echo "Done! Version: ${BLE_VER}"
echo "Run: source ~/.bashrc && echo \$BLE_VERSION"
