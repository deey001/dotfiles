return {
  -- Markdown rendering in-buffer
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    ft = { "markdown" },
    opts = {
      heading = {
        enabled = true,
        icons = { "󰫄 ", "󰫆 ", "󰫈 ", "󰫊 ", "󰫌 ", "󰫎 " },
      },
      code = { enabled = true, style = "full" },
      bullet = { enabled = true, icons = { "●", "○", "◆", "◇" } },
    },
  },

  -- Extra treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash", "python", "javascript", "typescript", "json", "yaml",
        "toml", "markdown", "markdown_inline", "go", "rust", "html",
        "css", "lua", "vim", "vimdoc", "dockerfile", "terraform",
      },
    },
  },
}
