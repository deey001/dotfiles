#!/bin/bash
# install-blesh.sh — Standalone ble.sh installer
# Usage: bash ~/dotfiles/scripts/install-blesh.sh
set -euo pipefail

URL="https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz"
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo "Removing old ble.sh..."
rm -rf "$HOME/.local/share/blesh"

echo "Downloading ble.sh nightly..."
curl -fsSL "$URL" -o "$TMPDIR/ble-nightly.tar.xz"

echo "Extracting..."
tar -xJf "$TMPDIR/ble-nightly.tar.xz" -C "$TMPDIR"

# Find the extracted directory
BLE_DIR=$(find "$TMPDIR" -maxdepth 1 -type d -name 'ble*' | head -1)
if [ -z "$BLE_DIR" ]; then
    echo "Error: could not find extracted ble.sh directory. Contents:"
    ls "$TMPDIR"
    exit 1
fi
echo "Found: $BLE_DIR"
echo "Contents: $(ls $BLE_DIR)"

echo "Installing to ~/.local..."
mkdir -p "$HOME/.local/share"
if [ -f "$BLE_DIR/install.sh" ]; then
    # Pre-built release: has install.sh
    bash "$BLE_DIR/install.sh" --prefix="$HOME/.local" --no-confirm
elif [ -f "$BLE_DIR/Makefile" ]; then
    # Source tarball: needs make
    make -C "$BLE_DIR" install PREFIX="$HOME/.local"
else
    # Fallback: copy directly (flat tarball structure)
    mkdir -p "$HOME/.local/share/blesh"
    cp -r "$BLE_DIR"/. "$HOME/.local/share/blesh/"
fi

BLE_VER=$(grep -o "BLE_VERSION=[^ ;]*" ~/.local/share/blesh/ble.sh 2>/dev/null | head -1 || echo "unknown")
echo "Done! Installed: ~/.local/share/blesh/ble.sh (${BLE_VER:-nightly})"
echo "Run: exec bash && echo \$BLE_VERSION"
