return {
  -- Set LazyVim colorscheme to Catppuccin
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },

  -- Configure Catppuccin Mocha
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = false,
      integrations = {
        aerial = true,
        cmp = true,
        dashboard = true,
        flash = true,
        gitsigns = true,
        indent_blankline = { enabled = true },
        mason = true,
        mini = true,
        navic = { enabled = true, custom_bg = "lualine" },
        neotree = true,
        noice = true,
        notify = true,
        snacks = true,
        telescope = true,
        treesitter_context = true,
        which_key = true,
      },
    },
  },
}
