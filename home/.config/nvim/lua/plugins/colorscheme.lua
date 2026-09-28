-- On Omarchy, ~/.config/nvim/lua/plugins/theme.lua (managed by Omarchy) sets the
-- colorscheme and hot-reloads it on theme change. Elsewhere, use Catppuccin.
if vim.uv.fs_stat(vim.fn.stdpath("config") .. "/lua/plugins/theme.lua") then
  return {}
end

return {
  { "catppuccin/nvim", name = "catppuccin", priority = 1000, opts = { flavour = "mocha" } },
  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin" } },
}
