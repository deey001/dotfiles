#!/bin/bash
# ==============================================================================
# install-nvim.sh — install latest stable Neovim if system nvim is too old
# ==============================================================================
# LazyVim requires Neovim >= 0.11.2. Most LTS distros (Ubuntu 24.04, Debian
# stable, RHEL) ship a much older nvim, so this script installs an upstream
# tarball into ~/.local without sudo and without polluting the system path.
#
# USAGE: bash ~/dotfiles/scripts/install-nvim.sh
#
# Idempotent: skips download if installed nvim already meets MIN_VERSION.
# ==============================================================================
set -euo pipefail

MIN_VERSION="0.11.2"
INSTALL_DIR="$HOME/.local/share/nvim-linux"
BIN_LINK="$HOME/.local/bin/nvim"

# Returns 0 if $1 >= $2 (semver compare via sort -V).
ver_ge() {
    [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -1)" = "$2" ]
}

current_version() {
    command -v nvim >/dev/null 2>&1 || { echo "0.0.0"; return; }
    nvim --version | head -1 | sed -nE 's/^NVIM v([0-9.]+).*/\1/p'
}

cur="$(current_version)"
if [ -n "$cur" ] && ver_ge "$cur" "$MIN_VERSION"; then
    echo "nvim $cur already meets minimum $MIN_VERSION — skipping"
    exit 0
fi
echo "nvim ${cur:-absent} < $MIN_VERSION — installing latest stable from GitHub"

case "$(uname -m)" in
    x86_64)  ASSET="nvim-linux-x86_64.tar.gz" ;;
    aarch64) ASSET="nvim-linux-arm64.tar.gz" ;;
    *) echo "Unsupported arch $(uname -m) — install nvim manually" >&2; exit 1 ;;
esac

URL="https://github.com/neovim/neovim/releases/latest/download/$ASSET"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "Downloading $URL..."
curl -fsSL "$URL" -o "$TMP/nvim.tar.gz"

# Wipe any prior tarball install and re-extract.
mkdir -p "$INSTALL_DIR"
rm -rf "${INSTALL_DIR:?}"/*
tar -xzf "$TMP/nvim.tar.gz" -C "$INSTALL_DIR" --strip-components=1

mkdir -p "$(dirname "$BIN_LINK")"
ln -sf "$INSTALL_DIR/bin/nvim" "$BIN_LINK"

echo "Installed: $("$BIN_LINK" --version | head -1)"
echo "Ensure \$HOME/.local/bin is on PATH (already added by .bashrc/.zshrc)."
