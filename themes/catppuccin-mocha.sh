# ==============================================================================
# themes/catppuccin-mocha.sh — Catppuccin Mocha Theme Variables
# ==============================================================================
#
# PURPOSE:
#   Single source of truth for the Catppuccin Mocha color palette and all
#   tool-specific theme names derived from it.  Sourced by
#   ~/.config/dotfiles/theme.sh (stowed from stow/theme-catppuccin-mocha/).
#
# CONSUMERS:
#   .common_shell        → sources this via ~/.config/dotfiles/theme.sh
#   .bashrc              → uses DOTFILES_FZF_COLORS for FZF_DEFAULT_OPTS
#   .zshrc               → uses DOTFILES_FZF_COLORS for FZF_DEFAULT_OPTS + fzf-tab
#   wezterm.lua          → reads DOTFILES_WEZTERM_THEME via os.getenv()
#   PS profile           → sources themes/windows/catppuccin-mocha.ps1 (via DOTFILES_THEME)
#   install.ps1          → references windows/ path for WT color scheme
#
# SWITCHING THEMES:
#   1. stow a different theme package:
#        make theme-latte     # switch to Catppuccin Latte (light)
#        make theme-mocha     # switch back to Catppuccin Mocha (dark)
#   2. Restart your shell (or: source ~/.config/dotfiles/theme.sh)
#
# ADDING A NEW THEME:
#   1. Copy this file to themes/<name>.sh
#   2. Create stow/theme-<name>/.config/dotfiles/theme.sh that sources it
#   3. Create themes/windows/<name>.ps1 with PSReadLine colors
#   4. Add a Makefile target: theme-<name>
#
# PALETTE REFERENCE:
#   https://catppuccin.com/palette  (Mocha column)
# ==============================================================================

# ── Identity ──────────────────────────────────────────────────────────────────
# DOTFILES_THEME: machine-readable slug used to select theme assets.
# DOTFILES_THEME_DISPLAY: human-readable name for status messages.
export DOTFILES_THEME="catppuccin-mocha"
export DOTFILES_THEME_DISPLAY="Catppuccin Mocha"

# ── Catppuccin Mocha Palette ──────────────────────────────────────────────────
# Full 26-color palette. Use DOTFILES_COLOR_* in any tool that accepts hex.
# These match the values in starship.toml [palettes.catppuccin_mocha] exactly.
export DOTFILES_COLOR_ROSEWATER="#f5e0dc"
export DOTFILES_COLOR_FLAMINGO="#f2cdcd"
export DOTFILES_COLOR_PINK="#f5c2e7"
export DOTFILES_COLOR_MAUVE="#cba6f7"     # Accent — prompt symbol, info text
export DOTFILES_COLOR_RED="#f38ba8"       # Error / root warning
export DOTFILES_COLOR_MAROON="#eba0ac"
export DOTFILES_COLOR_PEACH="#fab387"     # Number literals / Ubuntu icon
export DOTFILES_COLOR_YELLOW="#f9e2af"    # Git status / command duration
export DOTFILES_COLOR_GREEN="#a6e3a1"     # Success / language modules
export DOTFILES_COLOR_TEAL="#94e2d5"      # Type casts
export DOTFILES_COLOR_SKY="#89dceb"       # Operators / Arch icon
export DOTFILES_COLOR_SAPPHIRE="#74c7ec"  # NixOS icon
export DOTFILES_COLOR_BLUE="#89b4fa"      # Directory / Docker context
export DOTFILES_COLOR_LAVENDER="#b4befe"
export DOTFILES_COLOR_TEXT="#cdd6f4"      # Default foreground
export DOTFILES_COLOR_SUBTEXT1="#bac2de"
export DOTFILES_COLOR_SUBTEXT0="#a6adc8"  # Hostname / git branch (subdued)
export DOTFILES_COLOR_OVERLAY2="#9399b2"
export DOTFILES_COLOR_OVERLAY1="#7f849c"
export DOTFILES_COLOR_OVERLAY0="#6c7086"
export DOTFILES_COLOR_SURFACE2="#585b70"  # Comments
export DOTFILES_COLOR_SURFACE1="#45475a"
export DOTFILES_COLOR_SURFACE0="#313244"  # Selection background
export DOTFILES_COLOR_BASE="#1e1e2e"      # Main background
export DOTFILES_COLOR_MANTLE="#181825"
export DOTFILES_COLOR_CRUST="#11111b"

# ── Tool-specific theme names ─────────────────────────────────────────────────
# These are the exact strings each tool expects — not hex codes.

# bat (https://github.com/sharkdp/bat) — used in BAT_THEME env var
export BAT_THEME="Catppuccin Mocha"

# WezTerm — built-in color scheme name (no external file needed)
export DOTFILES_WEZTERM_THEME="Catppuccin Mocha"

# Starship — palette name referenced in starship.toml `palette = "..."` field.
# starship.toml already has the full palette hardcoded; this var documents which
# one is "active" for reference — Starship doesn't read env vars for palette.
export DOTFILES_STARSHIP_PALETTE="catppuccin_mocha"

# ── Pre-built FZF color string ────────────────────────────────────────────────
# Used directly in FZF_DEFAULT_OPTS in .bashrc and .zshrc.
# Avoids duplicating this string in every shell config file.
# Format: --color=key:value,key:value,...  (passed as a flag, not a full --color= flag)
export DOTFILES_FZF_COLORS="bg+:${DOTFILES_COLOR_SURFACE0},bg:${DOTFILES_COLOR_BASE},spinner:${DOTFILES_COLOR_ROSEWATER},hl:${DOTFILES_COLOR_RED},fg:${DOTFILES_COLOR_TEXT},header:${DOTFILES_COLOR_RED},info:${DOTFILES_COLOR_MAUVE},pointer:${DOTFILES_COLOR_ROSEWATER},marker:${DOTFILES_COLOR_GREEN},fg+:${DOTFILES_COLOR_TEXT},prompt:${DOTFILES_COLOR_MAUVE},hl+:${DOTFILES_COLOR_RED}"

# ── fzf-tab Zsh zstyle color string ──────────────────────────────────────────
# Separate from DOTFILES_FZF_COLORS because fzf-tab's --color flag format
# does not include bg: (uses terminal default background) to avoid the
# fzf-tab popup looking different from the terminal background.
export DOTFILES_FZFTAB_COLORS="bg+:${DOTFILES_COLOR_SURFACE0},fg+:${DOTFILES_COLOR_TEXT},hl:${DOTFILES_COLOR_RED},hl+:${DOTFILES_COLOR_RED},info:${DOTFILES_COLOR_MAUVE},prompt:${DOTFILES_COLOR_MAUVE},pointer:${DOTFILES_COLOR_ROSEWATER},marker:${DOTFILES_COLOR_GREEN},spinner:${DOTFILES_COLOR_ROSEWATER},header:${DOTFILES_COLOR_BLUE}"
