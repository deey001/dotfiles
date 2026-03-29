-- ============================================================================
-- colorscheme.lua — Theme Configuration
-- ============================================================================
-- Description: Configures the Catppuccin color scheme (Mocha variant) as the
--   active theme for the entire editor. This file does two things:
--   1. Tells LazyVim to use "catppuccin" as the global colorscheme.
--   2. Configures the catppuccin plugin itself (flavour, integrations).
--
-- Catppuccin provides four flavours: latte (light), frappe, macchiato, mocha
--   (darkest). Mocha is used here for the best contrast on dark terminals.
--
-- The `priority = 1000` ensures Catppuccin loads before any other plugin so
--   the correct colors are available when the UI renders.
--
-- Dependencies: catppuccin/nvim
-- ============================================================================

return {

  -- ---- Tell LazyVim which colorscheme to activate ----
  -- This overrides LazyVim's default colorscheme (tokyonight). The name must
  -- match a colorscheme command that will be available after plugins load.
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },

  -- ---- Catppuccin Plugin Configuration ----
  {
    "catppuccin/nvim",
    name = "catppuccin",    -- Alias so other plugins can refer to it by name
    priority = 1000,        -- Load before everything else — colorscheme must be first
    opts = {
      flavour = "mocha",               -- Darkest variant — best for dark terminals
      transparent_background = false,   -- Use Catppuccin's own background color

      -- ---- Plugin Integrations ----
      -- Enable Catppuccin-aware highlighting for each plugin. Without these,
      -- plugins fall back to generic highlight groups and may look inconsistent.
      integrations = {
        aerial = true,                              -- Code outline/symbol navigation
        cmp = true,                                 -- Autocompletion popup
        dashboard = true,                           -- Start screen (snacks dashboard)
        flash = true,                               -- Flash.nvim motion highlights
        gitsigns = true,                            -- Git change indicators in sign column
        indent_blankline = { enabled = true },      -- Indent guide lines
        mason = true,                               -- LSP/tool installer UI
        mini = true,                                -- mini.nvim modules (surround, ai, etc.)
        navic = { enabled = true, custom_bg = "lualine" },  -- Breadcrumb bar in lualine
        neotree = true,                             -- File tree sidebar
        noice = true,                               -- Enhanced command line / notifications
        notify = true,                              -- Notification popups
        snacks = true,                              -- Snacks.nvim components
        telescope = true,                           -- Fuzzy finder popups
        treesitter_context = true,                  -- Sticky function/class context header
        which_key = true,                           -- Keybinding hint popup
      },
    },
  },
}
