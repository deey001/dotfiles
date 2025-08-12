" Enable Pathogen plugin manager (commented out as it requires manual setup)
" execute pathogen#infect()

" Mouse and terminal settings
" Disable mouse support and terminal mouse tracking for better compatibility with some terminals.
set mouse=
set ttymouse=

" Sudo save workaround
" Allow saving files as sudo when forgetting to start Vim with sudo privileges.
cmap w!! w !sudo tee > /dev/null %

" Highlight characters over 80 columns (commented out)
" This group highlights text beyond 80 characters; disabled to avoid distraction (uncomment to enable).
"augroup vimrc_autocmds
"  autocmd BufEnter * highlight OverLength ctermbg=darkgrey guibg=#111111
"  autocmd BufEnter * match OverLength /\%81v.*/
"augroup END

" Crontab and backup settings
" Allow editing crontab files by skipping certain backup paths. Enable backups, disable swap files, and set directories.
set backupskip=/tmp/*,/private/tmp/*
set backup                        " Enable backup files
set noswapfile                    " Disable swap files (modern practice)
set undodir=~/.vim/tmp/undo//     " Directory for undo files
set backupdir=~/.vim/tmp/backup// " Directory for backup files
set directory=~/.vim/tmp/swap//   " Directory for swap files (though disabled)
" Create directories if they don't exist
if !isdirectory(expand(&undodir))
    call mkdir(expand(&undodir), "p")
endif
if !isdirectory(expand(&backupdir))
    call mkdir(expand(&backupdir), "p")
endif
if !isdirectory(expand(&directory))
    call mkdir(expand(&directory), "p")
endif

" Window resizing and layout
" Automatically resize splits when the Vim window is resized.
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

" Filetype and indentation
" Enable filetype-specific plugins and indentation.
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

" Colors and Fonts
" Set 256-color mode if supported, enable syntax highlighting, and customize line numbers.
set t_Co=256
syntax enable
set cursorline                    " Highlight current line
set cursorcolumn                  " Highlight current column
highlight LineNr term=bold cterm=NONE ctermfg=DarkGrey ctermbg=NONE gui=NONE guifg=DarkGrey guibg=NONE
set nu                            " Enable line numbers
set relativenumber                " Show relative line numbers
set background=dark               " Dark background theme
"let g:solarized_termcolors=256   " Use 256 colors with Solarized (commented out)
"colorscheme slate                " Slate theme (commented out)
set encoding=utf8                 " Use UTF-8 encoding
set ffs=unix,dos,mac              " Prefer Unix file formats

" Text, tab, and indent related
" Use spaces instead of tabs, with smart indentation.
set expandtab
set smarttab
set shiftwidth=4                  " Indent with 4 spaces
set tabstop=4                     " Tab width is 4 spaces
set lbr                           " Linebreak at word boundaries
set tw=500                        " Text width for wrapping
set ai                            " Auto-indent
set si                            " Smart-indent
set wrap                          " Wrap long lines

" Visual mode related
" Search for visually selected text with * or #.
vnoremap <silent> * :call VisualSelection('f')<CR>
vnoremap <silent> # :call VisualSelection('b')<CR>

" Status line
" Always show status line (commented out to use default or plugin).
"set laststatus=1
" Format status line with paste mode, file info, and CWD (commented out).
"set statusline=\ %{HasPaste()}%F%m%r%h\ %w\ \ CWD:\ %r%{getcwd()}%h\ \ \ Line:\ %l

" Moving around, tabs, windows, and buffers
" Resize splits with + - > < keys.
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

" Vim split navigation
" Remap Ctrl + HJKL to navigate splits.
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" Helper functions
" Execute a command from the command line.
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

" Trailing whitespace and line return
" Toggle trailing whitespace visibility in non-insert mode.
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

" Pathogen Plugins
" Start NERDTree if no files specified.
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif
" Close NERDTree if it's the only window left.
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif
" Exclude NERDTree from indent guides.
let g:indent_guides_exclude_filetypes = ['nerdtree']

" Airline Plugin
let g:airline#extensions#tabline#enabled = 1
set laststatus=2
let g:airline_theme='murmur'
let g:airline#extensions#hunks#enabled=0
let g:airline#extensions#branch#enabled=1

" Windowswap Plugin
let g:windowswap_map_keys = 0
nnoremap <silent> <leader>yw :call WindowSwap#MarkWindowSwap()<CR>
nnoremap <silent> <leader>pw :call WindowSwap#DoWindowSwap()<CR>
nnoremap <silent> <leader>ww :call WindowSwap#EasyWindowSwap()<CR>

" CtrlP Plugin
set runtimepath^=~/.vim/bundle/ctrlp.vim

" Ansible-vim Plugin
let g:ansible_extra_keywords_highlight = 1
let g:ansible_name_highlight = 'b'
let g:ansible_extra_syntaxes = "sh.vim"
func! DeleteTrailingWS()
    exe "normal mz"
    %s/\s\+$//ge
    exe "normal `z"
endfunc
autocmd BufWrite * :call DeleteTrailingWS()

" vim-hclfmt Plugin
let g:hcl_fmt_autosave = 1
let g:tf_fmt_autosave = 0
let g:nomad_fmt_autosave = 1

" Custom toggle for indent guides
nmap <silent> <leader><bslash> :call ToggleIndentGuidesSpaces()<cr>
function! ToggleIndentGuidesSpaces()
    if exists('b:iguides_spaces')
        call matchdelete(b:iguides_spaces)
        unlet b:iguides_spaces
    else
        let pos = range(1, &l:textwidth, &l:shiftwidth)
        call map(pos, '"\\%" . v:val . "v"')
        let pat = '\%(\_^\s*\)\@<=\%(' . join(pos, '\|') . '\)\s'
        let b:iguides_spaces = matchadd('CursorLine', pat)
    endif
endfunction

" vim-hashicorp-terraform Plugin
let g:terraform_align = 1

" Autocomplete Enhancement
" Enable Vim's built-in omni-completion for various filetypes (e.g., Python, HTML).
set omnifunc=syntaxcomplete#Complete
" Map Ctrl+Space to trigger autocomplete (works in Insert mode).
inoremap <C-Space> <C-x><C-o>
" Enable auto-completion popup menu with Tab.
set completeopt=menu,menuone,preview
" Add dictionary completion (e.g., for custom words).
set complete+=k
" Optional: Set a dictionary file (create ~/.vim/dict/words with custom words).
" set dictionary+=~/.vim/dict/words