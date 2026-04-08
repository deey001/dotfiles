-- ==============================================================================
-- wezterm.lua — WezTerm Terminal Emulator Configuration
-- ==============================================================================
-- LOCATION:  ~/.config/wezterm/wezterm.lua  (symlinked by install.sh)
-- DOCS:      https://wezfurlong.org/wezterm/config/files.html
-- REQUIRES:  WezTerm nightly or stable ≥ 20230712
--
-- OVERVIEW:
--   WezTerm is a GPU-accelerated cross-platform terminal emulator written in
--   Rust, configured entirely in Lua. This config sets up:
--     • Catppuccin Mocha color scheme (built-in to WezTerm — no external file)
--     • JetBrainsMono Nerd Font at 14pt (required for Starship/eza icons)
--     • Slight background transparency (0.95 opacity) for depth on desktop
--     • Minimal UI — no title bar chrome, tab bar hidden on single tab
--     • 10,000-line scrollback buffer (generous for server log tailing)
--     • Ctrl+Shift+L: dump current pane scrollback to ~/logs/ as a text file
--
-- FONT:
--   JetBrainsMono Nerd Font must be installed. On Linux/macOS it is installed
--   by Nerd Fonts' install script. On Windows, scripts/install.ps1 option 1
--   downloads and installs it from github.com/ryanoasis/nerd-fonts.
--
-- THEME:
--   'Catppuccin Mocha' is one of WezTerm's built-in color schemes — no extra
--   file needed. Matches the theme used in Starship, Neovim, Tmux, bat, fzf,
--   and the Windows Terminal.
--
-- RELATED FILES:
--   ~/.config/starship.toml   — prompt theme (also Catppuccin Mocha)
--   ~/.config/nvim/           — editor theme (also Catppuccin Mocha)
--   windows/settings.json     — Windows Terminal uses the same color values
-- ==============================================================================

local wezterm = require 'wezterm'

-- config_builder() provides better error messages than a plain {} table.
-- It validates key names and value types at parse time rather than silently
-- ignoring unknown options.
local config = wezterm.config_builder()

-- ==============================================================================
-- Appearance
-- ==============================================================================

-- Catppuccin Mocha is bundled into WezTerm — no external scheme file needed.
-- The active theme is exported as DOTFILES_WEZTERM_THEME by the stowed theme
-- package (stow/theme-catppuccin-mocha/ or stow/theme-catppuccin-latte/).
-- Switch themes: `make theme-latte` / `make theme-mocha`, then restart WezTerm.
-- If the env var is unset (fresh install, no theme stowed yet), fall back to
-- Catppuccin Mocha so the terminal is never unstyled.
-- To see all available built-in schemes: wezterm ls-fonts --list-color-schemes
local active_theme = os.getenv("DOTFILES_WEZTERM_THEME") or "Catppuccin Mocha"
config.color_scheme = active_theme

-- Slight transparency (5%) so desktop wallpaper bleeds through on macOS/Linux.
-- Set to 1.0 for fully opaque (useful on low-powered machines or Windows).
-- Note: On Windows, transparency requires DWM compositing (usually automatic).
config.window_background_opacity = 0.95

-- Inner padding in pixels on all four sides.
-- Prevents text from touching the window edge; matches the old Alacritty config.
config.window_padding = {
  left   = 10,
  right  = 10,
  top    = 10,
  bottom = 10,
}

-- "RESIZE" removes the OS title bar while keeping the resize border.
-- This maximizes vertical space — Starship's prompt provides context instead.
-- Alternatives: "TITLE" (standard title bar), "NONE" (borderless), "INTEGRATED_BUTTONS"
config.window_decorations = "RESIZE"

-- Hide the tab bar when only one tab is open; it reappears automatically
-- as soon as a second tab is opened (Ctrl+Shift+T).
config.hide_tab_bar_if_only_one_tab = true

-- ==============================================================================
-- Font
-- ==============================================================================

-- JetBrainsMono Nerd Font — a ligature-enabled monospace font patched with
-- Nerd Font icons (used by Starship OS icons, eza file-type icons, etc.).
-- If this font is missing, WezTerm will fall back to a system monospace but
-- Starship/eza icons will render as boxes or question marks.
config.font = wezterm.font('JetBrainsMono Nerd Font')

-- 14pt is a comfortable reading size at 1080p. Increase for HiDPI / 4K displays.
-- Adjust with Ctrl+= (increase) or Ctrl+- (decrease) at runtime.
config.font_size = 14.0

-- ==============================================================================
-- Scrollback
-- ==============================================================================

-- 10,000 lines of scrollback — enough to capture most server log tails without
-- excessive memory use. For log-heavy workloads, use Ctrl+Shift+L to dump to
-- a file instead of relying entirely on scrollback.
config.scrollback_lines = 10000

-- ==============================================================================
-- Key Bindings
-- ==============================================================================

config.keys = {
  -- Ctrl+Shift+L: Dump the entire scrollback buffer to a timestamped file in
  -- ~/logs/. Useful for capturing long build outputs, server logs, or any
  -- session you want to review later without digging through scrollback.
  --
  -- The file is plain text (no ANSI escapes) — open it in any editor.
  -- ~/logs/ is created automatically on first use.
  {
    key   = 'L',
    mods  = 'CTRL|SHIFT',
    action = wezterm.action_callback(function(window, pane)
      -- get_logical_lines_as_text() returns the pane content with ANSI codes
      -- stripped, as plain readable text.
      local text     = pane:get_logical_lines_as_text()
      local time     = wezterm.strftime("%Y-%m-%d_%H-%M-%S")
      local log_dir  = wezterm.home_dir .. "/logs"

      -- Ensure ~/logs/ exists — cross-platform conditional.
      -- package.config:sub(1,1) returns '\' on Windows, '/' on Unix.
      local sep = package.config:sub(1,1)
      if sep == '\\' then
        os.execute('if not exist "' .. log_dir .. '" mkdir "' .. log_dir .. '"')
      else
        os.execute("mkdir -p '" .. log_dir .. "'")
      end

      local filename = log_dir .. "/session_" .. time .. ".txt"
      local file     = io.open(filename, "w")
      if file then
        file:write(text)
        file:close()
        -- Log to WezTerm's debug overlay (Ctrl+Shift+L in debug mode) for
        -- confirmation without interrupting the terminal session.
        wezterm.log_info("Saved session to " .. filename)
      end
    end),
  },
}

return config
