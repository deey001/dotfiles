" Neovim config based on .vimrc with modern plugins

" Enable Pathogen plugin manager (commented out as it requires manual setup)
" execute pathogen#infect()

# Mouse and terminal settings
# Disable mouse support and terminal mouse tracking for better compatibility with some terminals.
set mouse=
set ttymouse=

# Sudo save workaround
# Allow saving files as sudo when forgetting to start Vim with sudo privileges.
cmap w!! w !sudo tee > /dev/null %

" Highlight characters over 80 columns (commented out)
" This group highlights text beyond 80 characters; disabled to avoid distraction (uncomment to enable).
"augroup vimrc_autocmds
"  autocmd BufEnter * highlight OverLength ctermbg=darkgrey guibg=#111111
"  autocmd BufEnter * match OverLength /\%81v.*/
"augroup END

# Crontab and backup settings
# Allow editing crontab files by skipping certain backup paths. Enable backups, disable swap files, and set directories.
set backupskip=/tmp/*,/private/tmp/*
set backup                        " Enable backup files
set noswapfile                    " Disable swap files (modern practice)
set undodir=~/.vim/tmp/undo//     " Directory for undo files
set backupdir=~/.vim/tmp/backup// " Directory for backup files
set directory=~/.vim/tmp/swap//   " Directory for swap files (though disabled)
# Create directories if they don't exist
if !isdirectory(expand(&undodir))
    call mkdir(expand(&undodir), "p")
endif
if !isdirectory(expand(&backupdir))
    call mkdir(expand(&backupdir), "p")
endif
if !isdirectory(expand(&directory))
    call mkdir(expand(&directory), "p")
endif

# Window resizing and layout
# Automatically resize splits when the Vim window is resized.
au VimResized * :wincmd =

" General settings
set modelines=1                   " Process first line for modelines
set showmode                      " Display current mode (e.g., INSERT)
set history=700                   " Store 700 lines of command history
set undofile                      " Enable persistent undo
set undoreload=10000              " Load up to 10,000 lines for undo
set matchtime=3                   " Time to show matching bracket (in tenths of sec)
set splitbelow                    " New window goes below
set splitright                    " New window goes right
set autowrite                     " Automatically save before commands like :next
set autoread                      " Reload files changed outside Vim
set shiftround                    " Round indent to multiple of shiftwidth
set title                         " Set the terminal title
set linebreak                     " Wrap lines at convenient points
set colorcolumn=+1                " Highlight column after textwidth (if set)

# Filetype and indentation
# Enable filetype-specific plugins and indentation.
filetype plugin on
filetype indent on

" Display and navigation
set ruler                         " Show cursor position
set clipboard=unnamedplus         " Use system clipboard
set cmdheight=2                   " Height of the command bar
set hid                           " Hide buffers when abandoned
set backspace=eol,start,indent    " Allow backspace over everything
set whichwrap+=<,>,h,l            " Wrap cursor movement at line ends
set ignorecase                    " Ignore case in searches
set smartcase                     " Smart case sensitivity in searches
set hlsearch                      " Highlight search results
set incsearch                     " Incremental search
set lazyredraw                    " Don't redraw during macros
set magic                         " Enable magic for regex
set showmatch                     " Highlight matching brackets
set noerrorbells                  " No beeps on errors
set novisualbell                  " No visual bell
set t_vb=                         " Disable visual bell
set t_ut=                         " Clear terminal background (for 256-color)
set tm=500                        " Terminal mode timeout (ms)

# Colors and Fonts
# Set 256-color mode if supported, enable syntax highlighting, and customize line numbers.
set t_Co=256
syntax enable
set cursorline                    " Highlight current line
set cursorcolumn                  " Highlight current column
highlight LineNr term=bold cterm=NONE ctermfg=DarkGrey ctermbg=NONE gui=NONE guifg=DarkGrey guibg=NONE
set nu                            " Enable line numbers
set relativenumber                " Show relative line numbers
set background=dark               " Dark background theme
#let g:solarized_termcolors=256   " Use 256 colors with Solarized (commented out)
#colorscheme slate                " Slate theme (commented out)
set encoding=utf8                 " Use UTF-8 encoding
set ffs=unix,dos,mac              " Prefer Unix file formats

# Text, tab, and indent related
# Use spaces instead of tabs, with smart indentation.
set expandtab
set smarttab
set shiftwidth=4                  " Indent with 4 spaces
set tabstop=4                     " Tab width is 4 spaces
set lbr                           " Linebreak at word boundaries
set tw=500                        " Text width for wrapping
set ai                            " Auto-indent
set si                            " Smart-indent
set wrap                          " Wrap long lines

# Visual mode related
# Search for visually selected text with * or #.
vnoremap <silent> * :call VisualSelection('f')<CR>
vnoremap <silent> # :call VisualSelection('b')<CR>

# Status line
# Always show the status line (commented out to use default or plugin).
#set laststatus=1
# Format status line with paste mode, file info, and CWD (commented out).
#set statusline=\ %{HasPaste()}%F%m%r%h\ %w\ \ CWD:\ %r%{getcwd()}%h\ \ \ Line:\ %l

# Moving around, tabs, windows, and buffers
# Resize splits with + - > < keys.
map + <c-w>-
map - <c-w>+
map > <c-w><
map < <c-w>>
" Close current buffer with leader+bd.
map <leader>bd :Bclose<cr>
" Close all buffers with leader+ba.
map <leader>ba :1,1000 bd!<cr>
" Useful mappings for managing tabs.
map <leader>tn :tabnew<cr>
map <leader>to :tabonly<cr>
map <leader>tc :tabclose<cr>
map <leader>tm :tabmove
" Open new tab with current buffer's path.
map <leader>te :tabedit <c-r>=expand("%:p:h")<cr>/
" Switch CWD to open buffer's directory.
map <leader>cd :cd %:p:h<cr>:pwd<cr>
" Behavior when switching buffers.
try
  set switchbuf=useopen,usetab,newtab
  set stal=2
catch
endtry
" Return to last edit position on file open.
autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif
" Remember open buffers on close.
set viminfo^=%

# Vim split navigation
# Remap Ctrl + HJKL to navigate splits.
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

# Helper functions
# Execute a command from the command line.
function! CmdLine(str)
    exe "menu Foo.Bar :" . a:str
    emenu Foo.Bar
    unmenu Foo
endfunction
" Handle visual selection for search/replace.
function! VisualSelection(direction) range
    let l:saved_reg = @"
    execute "normal! vgvy"
    let l:pattern = escape(@", '\\/.*$^~[]')
    let l:pattern = substitute(l:pattern, "\n$", "", "")
    if a:direction == 'b'
        execute "normal ?" . l:pattern . "^M"
    elseif a:direction == 'gv'
        call CmdLine("vimgrep " . '/'. l:pattern . '/' . ' **/*.')
    elseif a:direction == 'replace'
        call CmdLine("%s" . '/'. l:pattern . '/')
    elseif a:direction == 'f'
        execute "normal /" . l:pattern . "^M"
    endif
    let @/ = l:pattern
    let @" = l:saved_reg
endfunction
" Check if paste mode is enabled.
function! HasPaste()
    if &paste
        return 'PASTE MODE  '
    endif
    return ''
endfunction

# Trailing whitespace and line return
# Toggle trailing whitespace visibility in non-insert mode.
augroup trailing
    au!
    au InsertEnter * :set listchars-=trail:⌴
    au InsertLeave * :set listchars+=trail:⌴
augroup END
" Return to last edit position on file open (alternative method).
augroup line_return
    au!
    au BufReadPost *
        \ if line("'\"") > 0 && line("'\"") <= line("$") |
        \     execute 'normal! g`"zvzz' |
        \ endif
augroup END
" Reselect last-pasted text.
nnoremap gp `[v`]

" Neovim-specific enhancements
" Install packer if not present
if empty(glob('~/.local/share/nvim/site/pack/packer/start/packer.nvim'))
  silent !git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim
  autocmd VimEnter * PackerSync
endif

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

" Treesitter config
lua << EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = "all",
  highlight = { enable = true },
}
EOF

" Telescope config
lua << EOF
require('telescope').setup{}
EOF

" LSP config (basic)
lua << EOF
local lspconfig = require'lspconfig'
lspconfig.pyright.setup{}  -- Example for Python
EOF

" Completion config
lua << EOF
local cmp = require'cmp'
cmp.setup({
  snippet = {
    expand = function(args)
      require'luasnip'.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  }),
})
EOF

" Keymaps for Neovim
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>