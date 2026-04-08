-- ============================================================================
-- snacks.lua — Snacks.nvim Configuration
-- ============================================================================
-- Description: Configures folke/snacks.nvim, a collection of small QoL
--   utilities bundled into a single plugin. Snacks replaces several
--   standalone plugins (indent guides, notification system, file picker,
--   dashboard, etc.) with a unified, well-integrated package.
--
-- Snacks is a core part of the modern LazyVim stack — LazyVim uses it for
--   the file explorer, picker (replacing telescope), dashboard, and more.
--   This file enables specific Snacks modules and adds custom keymaps.
--
-- `priority = 1000` ensures Snacks loads very early (same as colorscheme),
--   because the dashboard and notifier need to be ready at startup.
-- `lazy = false` disables lazy-loading — this plugin must be available
--   immediately, not deferred to an event.
--
-- Dependencies: folke/snacks.nvim (managed by lazy.nvim)
-- ============================================================================

return {
  {
    "folke/snacks.nvim",
    priority = 1000,   -- Load at startup alongside the colorscheme
    lazy = false,      -- Must be available immediately for dashboard/notifier
    ---@type snacks.Config
    opts = {

      -- ---- Enabled Modules ----
      -- Each module is a self-contained feature. Set `enabled = true` to
      -- activate it, or pass a config table for customization.

      bigfile = { enabled = true },       -- Disable heavy features (treesitter, LSP) for
                                          -- large files to prevent editor slowdown
      dashboard = { enabled = true },     -- Start screen with recent files, projects, etc.
      explorer = { enabled = true },      -- File explorer sidebar (replaces neo-tree in
                                          -- newer LazyVim setups)
      indent = { enabled = true },        -- Indent guide lines (replaces indent-blankline)
      input = { enabled = true },         -- Enhanced vim.ui.input() with floating window
      notifier = { enabled = true },      -- Notification system (replaces nvim-notify)
      picker = { enabled = true },        -- Fuzzy finder (replaces telescope.nvim in
                                          -- newer LazyVim setups)
      quickfile = { enabled = true },     -- Fast file opener — when opening a single file
                                          -- from the CLI, renders it before plugins finish
      scope = { enabled = true },         -- Highlight and text object for the current scope
                                          -- (the indent-level block the cursor is in)
      scroll = { enabled = true },        -- Smooth scrolling animations
      statuscolumn = { enabled = true },  -- Custom status column (line numbers, signs,
                                          -- fold indicators in a clean layout)
      words = { enabled = true },         -- Highlight other occurrences of the word under
                                          -- cursor and jump between them with ]w / [w
    },

    -- ---- Custom Keymaps ----
    -- These extend LazyVim's default Snacks keymaps.
    keys = {
      -- Toggle distraction-free writing mode — hides statusline, line numbers,
      -- and other chrome. Great for focused editing of prose or code.
      { "<leader>z", function() Snacks.zen() end, desc = "Toggle Zen Mode" },

      -- Show the notification history in a popup. Useful for reviewing
      -- messages that auto-dismissed before you could read them.
      { "<leader>n", function() Snacks.notifier.show_history() end, desc = "Notification History" },

      -- Open lazygit in a full-screen terminal overlay. This overrides
      -- LazyVim's default <leader>gg to use the Snacks terminal wrapper,
      -- which provides better integration (auto-refresh buffers on close).
      { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
    },
  },
}
