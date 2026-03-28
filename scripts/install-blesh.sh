#!/bin/bash
# install-blesh.sh — Build and install ble.sh from latest master
# Usage: bash ~/dotfiles/scripts/install-blesh.sh
set -euo pipefail

MASTER_URL="https://github.com/akinomyoga/ble.sh/archive/refs/heads/master.tar.gz"
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo "Removing old ble.sh..."
rm -rf "$HOME/.local/share/blesh"

echo "Downloading ble.sh master branch..."
# Try wget first (common on Ubuntu/Debian), fall back to curl
if command -v wget >/dev/null 2>&1; then
    wget -q -O "$TMPDIR/blesh.tar.gz" "$MASTER_URL"
elif command -v curl >/dev/null 2>&1; then
    curl -fsSL "$MASTER_URL" -o "$TMPDIR/blesh.tar.gz"
else
    echo "Error: neither wget nor curl found"
    exit 1
fi

echo "Extracting..."
tar -xzf "$TMPDIR/blesh.tar.gz" -C "$TMPDIR"

BLE_DIR=$(find "$TMPDIR" -maxdepth 1 -type d -name 'ble.sh*' | head -1)
if [ -z "$BLE_DIR" ]; then
    echo "Error: could not find extracted directory. Contents:"
    ls "$TMPDIR"
    exit 1
fi
echo "Found: $BLE_DIR"

if ! command -v make >/dev/null 2>&1; then
    echo "Error: 'make' is required to build ble.sh from source"
    echo "Install with: sudo apt install make"
    exit 1
fi

echo "Building and installing to ~/.local..."
make -C "$BLE_DIR" install PREFIX="$HOME/.local"

BLE_VER=$(grep -o "BLE_VERSION=[^ ;]*" "$HOME/.local/share/blesh/ble.sh" 2>/dev/null | head -1 || echo "unknown")
echo ""
echo "Done! Version: ${BLE_VER}"
echo "Run: exec bash && echo \$BLE_VERSION"
