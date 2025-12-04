#!/bin/bash
# Neovim Plugin Installation Script for Linux
# This script installs Packer and all required Neovim plugins

set -e

echo "Installing Packer plugin manager..."

# Determine the correct data directory
if command -v nvim &> /dev/null; then
    DATA_DIR=$(nvim --headless -c "echo stdpath('data')" -c "quit" 2>&1 | tail -n 1)
else
    echo "Error: nvim not found. Please install Neovim first."
    exit 1
fi

PACKER_DIR="${DATA_DIR}/site/pack/packer/start/packer.nvim"

# Install Packer if not present
if [ ! -d "$PACKER_DIR" ]; then
    echo "Cloning Packer to $PACKER_DIR..."
    git clone --depth 1 https://github.com/wbthomason/packer.nvim "$PACKER_DIR"
else
    echo "Packer already installed at $PACKER_DIR"
fi

# Create a minimal init file for plugin installation
TEMP_INIT=$(mktemp)
cat > "$TEMP_INIT" << 'EOF'
lua << LUA
require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'
  use 'nvim-treesitter/nvim-treesitter'
  use 'nvim-telescope/telescope.nvim'
  use 'nvim-lua/plenary.nvim'
  use 'neovim/nvim-lspconfig'
  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'L3MON4D3/LuaSnip'
end)
LUA
EOF

echo "Installing plugins..."
nvim --headless -u "$TEMP_INIT" -c 'autocmd User PackerComplete quitall' -c 'PackerSync'

# Clean up
rm "$TEMP_INIT"

echo "✓ Plugin installation complete!"
echo "You can now use nvim without errors."
