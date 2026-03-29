-- ============================================================================
-- options.lua — Neovim Options
-- ============================================================================
-- Description: Sets Vim/Neovim options that override or extend LazyVim defaults.
--   This file is loaded BEFORE lazy.nvim and any plugins start, so options
--   set here are available to every plugin during initialization.
--
-- LazyVim defaults already set (among others):
--   • number = true, relativenumber = true  (line numbers)
--   • expandtab = true                      (spaces instead of tabs)
--   • shiftwidth = 2, tabstop = 2           (2-space indent — OVERRIDDEN below)
--   • smartindent = true                    (auto-indent new lines)
--   • undofile = true                       (persistent undo across sessions)
--   • ignorecase = true, smartcase = true   (smart search casing)
--   • termguicolors = true                  (24-bit color)
--   • signcolumn = "yes"                    (always show sign column)
--   • clipboard = "unnamedplus"             (system clipboard integration)
--   • cursorline = true                     (highlight current line)
--   • mouse = "a"                           (mouse support — OVERRIDDEN below)
--   • scrolloff = 4                         (OVERRIDDEN below)
--
-- Reference: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- ============================================================================

-- ============================================================================
-- Indentation (overrides LazyVim default of 2)
-- ============================================================================
-- Use 4-space indent to match this dotfiles repo's EditorConfig convention
-- for shell scripts and general editing. Language-specific overrides can be
-- added via autocmds (see autocmds.lua suggestions).
vim.opt.shiftwidth = 4   -- Number of spaces for each step of (auto)indent
vim.opt.tabstop = 4      -- Number of spaces a <Tab> character displays as

-- ============================================================================
-- UI / Editing Behavior
-- ============================================================================
-- Disable mouse entirely — forces keyboard-only editing, which is faster
-- once muscle memory is built and avoids accidental clicks over SSH/tmux.
-- (Overrides LazyVim default of mouse = "a")
vim.opt.mouse = ""

-- Keep 8 lines visible above/below the cursor when scrolling — provides more
-- context than the LazyVim default of 4, reducing the "tunnel vision" effect.
vim.opt.scrolloff = 8

-- Show a vertical guide at column 80 — a visual reminder for line length
-- limits without enforcing hard wraps. Useful for code review readability.
vim.opt.colorcolumn = "80"

-- ============================================================================
-- Backup & Undo (extends LazyVim defaults)
-- ============================================================================
-- LazyVim enables undofile by default, but doesn't configure backup files.
-- These settings add filesystem backups and consolidate undo/backup files
-- into a dedicated directory to keep project trees clean.
-- The trailing "//" in the path tells Vim to use the full file path in the
-- backup filename, preventing collisions between files with the same name.
vim.opt.backup = true                                       -- Enable file backups on each write
vim.opt.swapfile = false                                    -- Disable swap files — undo + backup is sufficient
vim.opt.backupdir = vim.fn.expand("~/.vim/tmp/backup//")    -- Consolidated backup location
vim.opt.undodir = vim.fn.expand("~/.vim/tmp/undo//")        -- Consolidated undo location

-- Create backup/undo directories if they don't exist (the "p" flag creates
-- intermediate parent directories, similar to `mkdir -p` in shell).
vim.fn.mkdir(vim.fn.expand("~/.vim/tmp/backup"), "p")
vim.fn.mkdir(vim.fn.expand("~/.vim/tmp/undo"), "p")

-- ============================================================================
-- Command-Line Shortcuts
-- ============================================================================
-- Sudo save workaround — type `:w!!` to write a file you opened without sudo.
-- Pipes the buffer through `sudo tee` to write with elevated privileges.
vim.cmd([[cmap w!! w !sudo tee > /dev/null %]])

-- ============================================================================
-- Suggested Options (uncomment to enable)
-- ============================================================================

-- -- ---- conceallevel ----
-- -- Controls how "concealable" text is displayed. Level 2 hides concealed
-- -- text entirely (useful for markdown where bold/italic markers clutter the
-- -- view). LazyVim sets this to 2 for markdown by default via autocmd, but
-- -- you can set it globally if you prefer.
-- vim.opt.conceallevel = 2

-- -- ---- wrap ----
-- -- LazyVim disables line wrapping by default. Enable it if you edit a lot
-- -- of prose (markdown, txt) and prefer soft wrapping over horizontal scroll.
-- vim.opt.wrap = true
-- vim.opt.linebreak = true   -- Wrap at word boundaries, not mid-character

-- -- ---- splitkeep ----
-- -- Keeps the text on screen stable when opening/closing splits. "screen"
-- -- means the topline of the current window stays the same.
-- vim.opt.splitkeep = "screen"

-- -- ---- list (show invisible characters) ----
-- -- Reveal tabs, trailing spaces, and non-breaking spaces for debugging
-- -- whitespace issues. Useful alongside the trim-whitespace autocmd.
-- vim.opt.list = true
-- vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
