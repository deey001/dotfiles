-- ============================================================================
-- lazy.lua — Plugin Manager Bootstrap & Configuration
-- ============================================================================
-- Description: Bootstraps the lazy.nvim plugin manager (auto-installs it on
--   first run), then configures it to load the LazyVim distribution and all
--   user plugin specs from lua/plugins/*.lua.
--
-- This file is required from init.lua and runs very early — before any
-- plugins, options, keymaps, or autocmds are loaded.
--
-- Dependencies: git (for initial clone of lazy.nvim on a fresh machine)
-- ============================================================================

-- ============================================================================
-- Bootstrap lazy.nvim
-- ============================================================================
-- Construct the path where lazy.nvim will be installed inside Neovim's data
-- directory (typically ~/.local/share/nvim/lazy/lazy.nvim).
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- Only clone if lazy.nvim is not already present on disk.
-- `vim.uv` is the preferred libuv binding (Neovim ≥0.10); `vim.loop` is the
-- legacy name kept for backwards compatibility with older Neovim versions.
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  -- `--filter=blob:none` performs a blobless clone — fetches commit/tree
  -- objects immediately but defers file contents, making the clone faster.
  -- `--branch=stable` pins to the latest stable release tag.
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

-- Prepend lazy.nvim to the runtime path so `require("lazy")` works below.
vim.opt.rtp:prepend(lazypath)

-- ============================================================================
-- Plugin Spec & lazy.nvim Options
-- ============================================================================
require("lazy").setup({

  -- ---- Plugin Specifications ----
  spec = {
    -- Load the LazyVim distribution first — this pulls in its curated set of
    -- plugins (treesitter, lsp, telescope/snacks, which-key, etc.) and their
    -- default configs. Think of this as the "base layer."
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },

    -- Import all files from lua/plugins/ — each file returns a table of
    -- plugin specs that extend or override the LazyVim defaults.
    { import = "plugins" },
  },

  -- ---- Default Plugin Behavior ----
  defaults = {
    lazy = false,    -- Load plugins at startup (not lazily) unless overridden
    version = false, -- Use latest git commits instead of semver release tags,
                     -- because many Neovim plugins don't publish stable releases
  },

  -- ---- Install Options ----
  -- When lazy.nvim installs plugins for the first time, apply the catppuccin
  -- colorscheme so the UI looks right even before all plugins finish loading.
  install = { colorscheme = { "catppuccin" } },

  -- ---- Update Checker ----
  checker = {
    enabled = true,  -- Periodically check for plugin updates in the background
    notify = false,  -- Don't pop up a notification — check manually with :Lazy
  },

  -- ---- Performance Tuning ----
  performance = {
    rtp = {
      -- Disable built-in Vim plugins that are unused, to shave a few ms off
      -- startup. These are legacy Vim features replaced by modern alternatives.
      disabled_plugins = {
        "gzip",       -- Editing gzipped files (rarely needed in a terminal editor)
        "tarPlugin",  -- Editing files inside tarballs
        "tohtml",     -- :TOhtml command (convert buffer to HTML)
        "tutor",      -- Built-in Vim tutorial
        "zipPlugin",  -- Editing files inside zip archives
      },
    },
  },
})
