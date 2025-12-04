" Minimal init file for Packer installation
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'

" Packer plugins
lua << EOF
require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'  -- Packer manages itself
  use 'nvim-treesitter/nvim-treesitter'  -- Syntax highlighting
  use 'nvim-telescope/telescope.nvim'  -- Fuzzy finder
  use 'nvim-lua/plenary.nvim'  -- Dependency for telescope
  use 'neovim/nvim-lspconfig'  -- LSP support
  use 'hrsh7th/nvim-cmp'  -- Completion
  use 'hrsh7th/cmp-nvim-lsp'  -- LSP completion
  use 'L3MON4D3/LuaSnip'  -- Snippets
end)
EOF
