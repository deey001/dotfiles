# ==============================================================================
# themes/catppuccin-latte.sh — Catppuccin Latte Theme Variables (Light)
# ==============================================================================
#
# PURPOSE:
#   Catppuccin Latte variant — the light/day mode palette.
#   Same variable API as catppuccin-mocha.sh; all consumers work unchanged.
#
# ACTIVATE:
#   make theme-latte    (stows themes/catppuccin-latte.sh → ~/.config/dotfiles/theme.sh)
#
# PALETTE REFERENCE:
#   https://catppuccin.com/palette  (Latte column)
# ==============================================================================

# ── Identity ──────────────────────────────────────────────────────────────────
export DOTFILES_THEME="catppuccin-latte"
export DOTFILES_THEME_DISPLAY="Catppuccin Latte"

# ── Catppuccin Latte Palette ──────────────────────────────────────────────────
export DOTFILES_COLOR_ROSEWATER="#dc8a78"
export DOTFILES_COLOR_FLAMINGO="#dd7878"
export DOTFILES_COLOR_PINK="#ea76cb"
export DOTFILES_COLOR_MAUVE="#8839ef"
export DOTFILES_COLOR_RED="#d20f39"
export DOTFILES_COLOR_MAROON="#e64553"
export DOTFILES_COLOR_PEACH="#fe640b"
export DOTFILES_COLOR_YELLOW="#df8e1d"
export DOTFILES_COLOR_GREEN="#40a02b"
export DOTFILES_COLOR_TEAL="#179299"
export DOTFILES_COLOR_SKY="#04a5e5"
export DOTFILES_COLOR_SAPPHIRE="#209fb5"
export DOTFILES_COLOR_BLUE="#1e66f5"
export DOTFILES_COLOR_LAVENDER="#7287fd"
export DOTFILES_COLOR_TEXT="#4c4f69"
export DOTFILES_COLOR_SUBTEXT1="#5c5f77"
export DOTFILES_COLOR_SUBTEXT0="#6c6f85"
export DOTFILES_COLOR_OVERLAY2="#7c7f93"
export DOTFILES_COLOR_OVERLAY1="#8c8fa1"
export DOTFILES_COLOR_OVERLAY0="#9ca0b0"
export DOTFILES_COLOR_SURFACE2="#acb0be"
export DOTFILES_COLOR_SURFACE1="#bcc0cc"
export DOTFILES_COLOR_SURFACE0="#ccd0da"
export DOTFILES_COLOR_BASE="#eff1f5"
export DOTFILES_COLOR_MANTLE="#e6e9ef"
export DOTFILES_COLOR_CRUST="#dce0e8"

# ── Tool-specific theme names ─────────────────────────────────────────────────
export BAT_THEME="Catppuccin Latte"
export DOTFILES_WEZTERM_THEME="Catppuccin Latte"
export DOTFILES_STARSHIP_PALETTE="catppuccin_latte"

# ── Pre-built FZF color string ────────────────────────────────────────────────
export DOTFILES_FZF_COLORS="bg+:${DOTFILES_COLOR_SURFACE0},bg:${DOTFILES_COLOR_BASE},spinner:${DOTFILES_COLOR_ROSEWATER},hl:${DOTFILES_COLOR_RED},fg:${DOTFILES_COLOR_TEXT},header:${DOTFILES_COLOR_RED},info:${DOTFILES_COLOR_MAUVE},pointer:${DOTFILES_COLOR_ROSEWATER},marker:${DOTFILES_COLOR_GREEN},fg+:${DOTFILES_COLOR_TEXT},prompt:${DOTFILES_COLOR_MAUVE},hl+:${DOTFILES_COLOR_RED}"

# ── fzf-tab Zsh zstyle color string ──────────────────────────────────────────
export DOTFILES_FZFTAB_COLORS="bg+:${DOTFILES_COLOR_SURFACE0},fg+:${DOTFILES_COLOR_TEXT},hl:${DOTFILES_COLOR_RED},hl+:${DOTFILES_COLOR_RED},info:${DOTFILES_COLOR_MAUVE},prompt:${DOTFILES_COLOR_MAUVE},pointer:${DOTFILES_COLOR_ROSEWATER},marker:${DOTFILES_COLOR_GREEN},spinner:${DOTFILES_COLOR_ROSEWATER},header:${DOTFILES_COLOR_BLUE}"
