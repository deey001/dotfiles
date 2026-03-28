#!/bin/bash
# install-blesh.sh — Build and install ble.sh from latest master
# Usage: bash ~/dotfiles/scripts/install-blesh.sh
set -euo pipefail

REPO="https://github.com/akinomyoga/ble.sh.git"
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo "Removing old ble.sh..."
rm -rf "$HOME/.local/share/blesh"

if ! command -v make >/dev/null 2>&1; then
    echo "Error: 'make' is required. Install with: sudo apt install make"
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
echo "Run: exec bash && echo \$BLE_VERSION"
