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

echo "Installing to ~/.local..."
bash "$TMPDIR/ble-nightly/install.sh" --prefix="$HOME/.local"

BLE_VER=$(grep -o "BLE_VERSION='[^']*'" ~/.local/share/blesh/ble.sh 2>/dev/null | head -1 || echo "unknown")
echo "Done! Version: $BLE_VER"
echo "Run: exec bash"
