-- Options are automatically loaded before lazy.nvim startup
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.mouse = ""
vim.opt.scrolloff = 8
vim.opt.colorcolumn = "80"
vim.opt.backup = true
vim.opt.swapfile = false
vim.opt.backupdir = vim.fn.expand("~/.vim/tmp/backup//")
vim.opt.undodir = vim.fn.expand("~/.vim/tmp/undo//")

-- Create backup/undo directories if they don't exist
vim.fn.mkdir(vim.fn.expand("~/.vim/tmp/backup"), "p")
vim.fn.mkdir(vim.fn.expand("~/.vim/tmp/undo"), "p")

-- Sudo save workaround
vim.cmd([[cmap w!! w !sudo tee > /dev/null %]])
