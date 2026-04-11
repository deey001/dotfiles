# Customization & Suggested Additions

Collected suggestions from across the dotfiles. Copy into the relevant config file to enable.

## Shell

### .inputrc — Vi mode
```
set editing-mode vi
set keymap vi-command
set show-mode-in-prompt on
set vi-ins-mode-string "(ins)"
set vi-cmd-mode-string "(cmd)"
```

### .bashrc / .zshrc — Additional functions
```bash
# Recursive case-insensitive grep with paging
ftext() { grep -iIHrn --color=always "$1" . | less -r; }
```

## Git

### Useful aliases
```ini
[alias]
    stash-all = stash save --include-untracked
    wip = !git add -A && git commit -m "WIP"
    conflicts = diff --name-only --diff-filter=U
    authors = shortlog -sne
    cleanup = !git branch --merged | grep -v '\\*\\|main\\|master' | xargs -n 1 git branch -d
```

### Reuse recorded conflict resolution
```ini
[rerere]
    enabled = true
```

### Rebase improvements
```ini
[rebase]
    autoStash = true
    autoSquash = true
```

### Commit signing (SSH)
```ini
[commit]
    gpgsign = true
[gpg]
    format = ssh
[user]
    signingkey = ~/.ssh/id_ed25519.pub
```

### Difftastic (structural diffs)
```ini
[diff]
    external = difft    # cargo install difftastic
```

## Tmux

### Additional plugins
```
set -g @plugin 'tmux-plugins/tmux-open'         # Open highlighted file/URL
set -g @plugin 'tmux-plugins/tmux-copycat'       # Regex search in scrollback
set -g @plugin 'tmux-plugins/tmux-logging'       # Log pane output to file
set -g @plugin 'tmux-plugins/tmux-pain-control'  # Standardized pane navigation
set -g @plugin 'jaclu/tmux-menus'                # Context menus
```

## Neovim

### Keymaps
```lua
-- Better escape
vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- Keep cursor centered on scroll/search
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down (centered)" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up (centered)" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Next search (centered)" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Prev search (centered)" })

-- Paste without losing register
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without losing register" })

-- Quick save
vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
```

### Autocmds
```lua
-- Trim trailing whitespace on save
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("TrimWhitespace", { clear = true }),
  pattern = "*",
  callback = function()
    local save = vim.fn.winsaveview()
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.winrestview(save)
  end,
})

-- Filetype-specific 2-space indent
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("IndentOverrides", { clear = true }),
  pattern = { "lua", "yaml", "json", "html", "css", "javascript", "typescript" },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
  end,
})
```

### Options
```lua
vim.opt.wrap = true           -- Soft wrap for prose
vim.opt.linebreak = true      -- Wrap at word boundaries
vim.opt.conceallevel = 2      -- Hide markdown markers
vim.opt.list = true           -- Show invisible characters
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
```

### Plugins
```lua
-- Linting
{ "mfussenegger/nvim-lint", opts = { linters_by_ft = { python = { "ruff" }, bash = { "shellcheck" } } } }

-- Formatting
{ "stevearc/conform.nvim", opts = { formatters_by_ft = { lua = { "stylua" }, python = { "ruff_format" }, bash = { "shfmt" } } } }

-- Copilot
{ "zbirenbaum/copilot.lua", cmd = "Copilot", event = "InsertEnter", opts = { suggestion = { enabled = true, auto_trigger = true } } }

-- Tmux-Neovim seamless navigation
{ "christoomey/vim-tmux-navigator", lazy = false }

-- LazyVim Extras (add to spec in lazy.lua):
{ import = "lazyvim.plugins.extras.lang.python" }
{ import = "lazyvim.plugins.extras.lang.typescript" }
{ import = "lazyvim.plugins.extras.lang.go" }
{ import = "lazyvim.plugins.extras.lang.docker" }
```

## Starship

### Cloud contexts
```toml
[aws]
format = '[$symbol($profile)]($style) '
symbol = "  "
style = "fg:peach"

[kubernetes]
disabled = false
symbol = "☸ "
style = "fg:blue"
format = '[$symbol$context]($style) '
```

### Battery (laptops)
```toml
[[battery.display]]
threshold = 20
style = "fg:red bold"
```

### Desktop notifications for long commands
```toml
[cmd_duration]
show_notifications = true
min_time_to_notify = 30_000
```

## Atuin

### Daemon mode (faster search)
```toml
[daemon]
enabled = true
```

### Self-hosted sync
```toml
sync_address = "https://atuin.myserver.com"
sync_frequency = "5m"
```
