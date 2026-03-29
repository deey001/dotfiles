-- ============================================================================
-- keymaps.lua — Custom Key Mappings
-- ============================================================================
-- Description: Defines custom keybindings beyond what LazyVim provides.
--   This file is automatically loaded by LazyVim on the VeryLazy event.
--
-- LazyVim default keymaps already active (do NOT redefine these):
--   • <C-h/j/k/l>       — Navigate between windows/splits
--   • <leader>e          — Toggle file explorer (neo-tree / snacks explorer)
--   • <leader><leader>   — Find files (telescope / snacks picker)
--   • <leader>/          — Live grep
--   • <leader>bb         — Switch buffers
--   • <leader>bd         — Delete buffer
--   • <leader>gg         — Lazygit (overridden in snacks.lua here)
--   • <leader>xx         — Diagnostics (Trouble)
--   • ]d / [d            — Next/prev diagnostic
--   • ]b / [b            — Next/prev buffer
--   • <leader>cf         — Format document
--   • <leader>cr         — Rename symbol
--   • <leader>ca         — Code action
--   • gd / gr / gI       — Go to definition / references / implementation
--   • K                  — Hover documentation
--
-- Reference: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- ============================================================================

-- ============================================================================
-- Suggested Keymaps (uncomment to enable)
-- ============================================================================

-- -- ---- Buffer Navigation ----
-- -- Quickly cycle through open buffers without reaching for [ and ]
-- vim.keymap.set("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
-- vim.keymap.set("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next Buffer" })

-- -- ---- Better Escape ----
-- -- Use "jk" in insert mode as a faster alternative to reaching for <Esc>
-- vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- -- ---- Move Lines Up/Down ----
-- -- LazyVim provides <A-j>/<A-k> for this, but Alt can be unreliable over SSH.
-- -- These use leader-based alternatives for headless/SSH sessions.
-- vim.keymap.set("n", "<leader>j", "<cmd>m .+1<cr>==", { desc = "Move line down" })
-- vim.keymap.set("n", "<leader>k", "<cmd>m .-2<cr>==", { desc = "Move line up" })
-- vim.keymap.set("v", "<leader>j", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
-- vim.keymap.set("v", "<leader>k", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })

-- -- ---- Keep Cursor Centered ----
-- -- When scrolling half-pages or searching, re-center the screen so you
-- -- never lose your place — especially useful on small terminal windows.
-- vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down (centered)" })
-- vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up (centered)" })
-- vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result (centered)" })
-- vim.keymap.set("n", "N", "Nzzzv", { desc = "Prev search result (centered)" })

-- -- ---- Window Management ----
-- -- Quick splits without typing the full :split/:vsplit command
-- vim.keymap.set("n", "<leader>wv", "<C-W>v", { desc = "Split window vertically" })
-- vim.keymap.set("n", "<leader>ws", "<C-W>s", { desc = "Split window horizontally" })
-- vim.keymap.set("n", "<leader>we", "<C-W>=", { desc = "Equalize window sizes" })
-- vim.keymap.set("n", "<leader>wx", "<cmd>close<cr>", { desc = "Close current split" })

-- -- ---- Clipboard helpers ----
-- -- Paste over a selection without losing the current yank register.
-- -- By default, visual paste replaces the register with the deleted text.
-- vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without losing register" })

-- -- ---- Quick save ----
-- vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
