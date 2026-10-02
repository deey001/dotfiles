-- ============================================================================
-- custom.lua — Custom Plugin Specifications
-- ============================================================================
-- Description: Adds plugins and configuration beyond what LazyVim provides
--   out of the box. Each top-level table entry is a lazy.nvim plugin spec.
--
-- Current plugins:
--   • render-markdown.nvim  — Rich markdown preview inside the buffer
--   • nvim-treesitter       — Extra language parsers for syntax highlighting
--
-- Note: Plugins defined here are merged with LazyVim's built-in specs. If a
--   plugin is already included by LazyVim (like treesitter), specifying it
--   again with `opts` will deep-merge your options into the defaults.
-- ============================================================================

return {

  -- ============================================================================
  -- Markdown Rendering
  -- ============================================================================
  -- Renders markdown inline — headings get icons, code blocks get background
  -- highlighting, and bullets use Unicode symbols. Much nicer than reading
  -- raw markdown syntax, especially for README files and notes.
  --
  -- `ft = { "markdown" }` means this plugin only loads when a markdown file
  -- is opened, keeping startup fast for non-markdown workflows.
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },  -- Needs treesitter for parsing
    ft = { "markdown" },
    opts = {
      heading = {
        enabled = true,
        -- Nerd Font icons for heading levels 1–6 (requires a patched font)
        icons = { "󰫄 ", "󰫆 ", "󰫈 ", "󰫊 ", "󰫌 ", "󰫎 " },
      },
      code = { enabled = true, style = "full" },  -- Full-width background for code blocks
      bullet = { enabled = true, icons = { "●", "○", "◆", "◇" } },  -- Alternating bullet styles by depth
    },
  },

  -- ============================================================================
  -- Treesitter Parser Configuration
  -- ============================================================================
  -- Extends LazyVim's default treesitter setup with additional language parsers.
  -- LazyVim already installs a core set (lua, vim, vimdoc, etc.), but this
  -- ensures parsers for all languages used in this dotfiles environment are
  -- available for syntax highlighting, indentation, and text objects.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        -- Shell & scripting (matches this dotfiles repo's primary languages)
        "bash", "python", "lua", "vim", "vimdoc",
        -- Web / JS ecosystem
        "javascript", "typescript", "html", "css", "json", "yaml", "toml",
        -- Systems / DevOps
        "go", "rust", "dockerfile", "terraform",
        -- Documentation
        "markdown", "markdown_inline",
      },
    },
  },
}

-- ============================================================================
-- Suggested Plugins (copy into the return table above to enable)
-- ============================================================================

-- ---- nvim-dap (Debug Adapter Protocol) ----
-- Full debugger integration for stepping through code. LazyVim has a
-- `lazyvim.plugins.extras.dap.core` extra you can import instead.
-- {
--   "mfussenegger/nvim-dap",
--   dependencies = {
--     "rcarriga/nvim-dap-ui",    -- Debugger UI with watches, breakpoints, etc.
--     "nvim-neotest/nvim-nio",   -- Required by nvim-dap-ui
--   },
-- },

-- ---- nvim-lint (Asynchronous Linting) ----
-- Runs linters on save and shows diagnostics. LazyVim extra available:
-- { import = "lazyvim.plugins.extras.linting" }
-- {
--   "mfussenegger/nvim-lint",
--   opts = {
--     linters_by_ft = {
--       python = { "ruff" },
--       bash = { "shellcheck" },
--       javascript = { "eslint_d" },
--     },
--   },
-- },

-- ---- conform.nvim (Formatting) ----
-- Auto-format on save using formatters like stylua, prettier, shfmt.
-- LazyVim extra available:
-- { import = "lazyvim.plugins.extras.formatting.prettier" }
-- {
--   "stevearc/conform.nvim",
--   opts = {
--     formatters_by_ft = {
--       lua = { "stylua" },
--       python = { "ruff_format" },
--       bash = { "shfmt" },
--       javascript = { "prettier" },
--     },
--   },
-- },

-- ---- trouble.nvim (Diagnostics List) ----
-- NOTE: LazyVim already includes trouble.nvim in its default plugin set.
-- Access it via <leader>xx (workspace diagnostics) or <leader>xX (buffer).
-- No need to add it here unless you want to customize its options.

-- ---- copilot.lua (AI Code Completion) ----
-- GitHub Copilot integration for inline suggestions. LazyVim extra:
-- { import = "lazyvim.plugins.extras.ai.copilot" }
-- {
--   "zbirenbaum/copilot.lua",
--   cmd = "Copilot",
--   event = "InsertEnter",
--   opts = {
--     suggestion = { enabled = true, auto_trigger = true },
--   },
-- },

-- ---- vim-tmux-navigator ----
-- Seamless navigation between tmux panes and Neovim splits using the same
-- C-h/j/k/l keys. Since this dotfiles setup uses tmux, this plugin makes
-- the boundary between tmux and Neovim windows invisible.
-- {
--   "christoomey/vim-tmux-navigator",
--   lazy = false,
--   keys = {
--     { "<C-h>", "<cmd>TmuxNavigateLeft<cr>",  desc = "Navigate left (tmux-aware)" },
--     { "<C-j>", "<cmd>TmuxNavigateDown<cr>",  desc = "Navigate down (tmux-aware)" },
--     { "<C-k>", "<cmd>TmuxNavigateUp<cr>",    desc = "Navigate up (tmux-aware)" },
--     { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate right (tmux-aware)" },
--   },
-- },

-- ---- neogit (Git UI) / diffview.nvim ----
-- Full Git interface inside Neovim. Complements lazygit (which is already
-- configured in snacks.lua) with a more Neovim-native experience.
-- {
--   "NeogitOrg/neogit",
--   dependencies = { "nvim-lua/plenary.nvim", "sindrets/diffview.nvim" },
--   cmd = "Neogit",
--   opts = {},
-- },

-- ---- flash.nvim (Motion / Jump) ----
-- NOTE: LazyVim already includes flash.nvim in its default set. Use `s` in
-- normal mode to trigger a label-based jump. No need to add it here.

-- ---- todo-comments.nvim ----
-- NOTE: LazyVim already includes todo-comments.nvim. Use <leader>st to
-- search TODOs or <leader>xt to view them in Trouble. No extra config needed.

-- ---- persistence.nvim (Session Management) ----
-- NOTE: LazyVim already includes persistence.nvim. Use <leader>qs to restore
-- the last session, <leader>ql to restore for the current directory.

-- ---- mini.surround / mini.ai (Text Objects) ----
-- NOTE: LazyVim already includes mini.surround (sa/sd/sr for add/delete/
-- replace surroundings) and mini.ai (enhanced a/i text objects). These are
-- active out of the box.

-- ---- LazyVim Extras Not Currently Enabled ----
-- Import these in the `spec` table of lua/config/lazy.lua to activate:
--   { import = "lazyvim.plugins.extras.lang.python" }
--   { import = "lazyvim.plugins.extras.lang.typescript" }
--   { import = "lazyvim.plugins.extras.lang.go" }
--   { import = "lazyvim.plugins.extras.lang.rust" }
--   { import = "lazyvim.plugins.extras.lang.docker" }
--   { import = "lazyvim.plugins.extras.lang.terraform" }
--   { import = "lazyvim.plugins.extras.lang.json" }
--   { import = "lazyvim.plugins.extras.lang.yaml" }
--   { import = "lazyvim.plugins.extras.lang.markdown" }
--   { import = "lazyvim.plugins.extras.editor.illuminate" }   -- Highlight word under cursor
--   { import = "lazyvim.plugins.extras.ui.mini-animate" }     -- Smooth scrolling & cursor animation
--   { import = "lazyvim.plugins.extras.test.core" }           -- Test runner integration
