-- ==============================================================================
-- wezterm.lua — WezTerm Configuration
-- ==============================================================================
-- Ported from Alacritty configuration.
-- Theme: Catppuccin Mocha
-- Font: JetBrainsMono Nerd Font
-- ==============================================================================

local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- --- Appearance --------------------------------------------------------------
-- WezTerm has Catppuccin Mocha built-in, so we can just use the scheme name!
config.color_scheme = 'Catppuccin Mocha'

-- Slightly transparent window (if supported by your OS/compositor)
config.window_background_opacity = 0.95

-- Inner padding (matches Alacritty's x=10, y=10)
config.window_padding = {
  left = 10,
  right = 10,
  top = 10,
  bottom = 10,
}

-- Native title bar
config.window_decorations = "RESIZE"

-- Hide the tab bar if there's only one tab
config.hide_tab_bar_if_only_one_tab = true

-- --- Font Configuration ------------------------------------------------------
-- Use the same font as Alacritty. WezTerm can automatically pick up Nerd Fonts.
config.font = wezterm.font('JetBrainsMono Nerd Font')
config.font_size = 14.0

-- --- Scrollback --------------------------------------------------------------
config.scrollback_lines = 10000

-- --- Key Bindings ------------------------------------------------------------
-- WezTerm defaults are quite good, but you can add custom bindings here.
-- Example: Pressing Ctrl+Shift+L to quickly dump the scrollback buffer to a file
config.keys = {
  {
    key = 'L',
    mods = 'CTRL|SHIFT',
    action = wezterm.action_callback(function(window, pane)
      local text = pane:get_logical_lines_as_text()
      local time = wezterm.strftime("%Y-%m-%d_%H-%M-%S")
      local log_dir = wezterm.home_dir .. "/logs"
      
      -- Ensure the directory exists (best effort via local bash)
      os.execute("mkdir -p " .. log_dir)
      
      local filename = log_dir .. "/session_" .. time .. ".txt"
      local file = io.open(filename, "w")
      if file then
        file:write(text)
        file:close()
        wezterm.log_info("Saved session to " .. filename)
      end
    end),
  },
}

return config
