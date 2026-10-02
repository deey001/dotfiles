-- Overrides on top of LazyVim defaults (https://www.lazyvim.org/configuration/general)
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.mouse = ""
vim.opt.scrolloff = 8
vim.opt.colorcolumn = "80"

-- Save as root when nvim was opened without sudo
vim.cmd([[cmap w!! w !sudo tee > /dev/null %]])

-- Over SSH, LazyVim turns off clipboard sync because there's no X/Wayland
-- clipboard on the server. Instead, yank to the local machine's clipboard with
-- OSC 52 (passes through tmux). Paste with the terminal's paste key; "+p pastes
-- the last yank, since most terminals don't allow reading the clipboard remotely.
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
  local osc52 = require("vim.ui.clipboard.osc52")
  local function paste()
    return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
  end
  vim.g.clipboard = {
    name = "OSC 52",
    copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
    paste = { ["+"] = paste, ["*"] = paste },
  }
  vim.opt.clipboard = "unnamedplus"
end
