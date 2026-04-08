# ==============================================================================
# themes/windows/catppuccin-mocha.ps1 — PSReadLine Catppuccin Mocha Colors
# ==============================================================================
#
# PURPOSE:
#   PowerShell equivalent of themes/catppuccin-mocha.sh.
#   Defines $env:DOTFILES_* color variables AND applies PSReadLine syntax
#   highlighting for the Catppuccin Mocha palette.
#
# SOURCED BY:
#   windows/Microsoft.PowerShell_profile.ps1 — dot-sources this file when
#   $env:USERPROFILE\.config\dotfiles\theme.ps1 resolves to this file.
#
# ACTIVATION (handled by install.ps1 Configure-PowerShell):
#   install.ps1 copies/links the active theme.ps1 to
#   $env:USERPROFILE\.config\dotfiles\theme.ps1
#   On theme switch: re-run Configure-PowerShell or copy manually.
#
# PALETTE REFERENCE:
#   https://catppuccin.com/palette  (Mocha column)
# ==============================================================================

# ── Identity ──────────────────────────────────────────────────────────────────
$env:DOTFILES_THEME         = "catppuccin-mocha"
$env:DOTFILES_THEME_DISPLAY = "Catppuccin Mocha"

# ── Catppuccin Mocha Palette ──────────────────────────────────────────────────
$env:DOTFILES_COLOR_ROSEWATER = "#f5e0dc"
$env:DOTFILES_COLOR_FLAMINGO  = "#f2cdcd"
$env:DOTFILES_COLOR_PINK      = "#f5c2e7"
$env:DOTFILES_COLOR_MAUVE     = "#cba6f7"
$env:DOTFILES_COLOR_RED       = "#f38ba8"
$env:DOTFILES_COLOR_MAROON    = "#eba0ac"
$env:DOTFILES_COLOR_PEACH     = "#fab387"
$env:DOTFILES_COLOR_YELLOW    = "#f9e2af"
$env:DOTFILES_COLOR_GREEN     = "#a6e3a1"
$env:DOTFILES_COLOR_TEAL      = "#94e2d5"
$env:DOTFILES_COLOR_SKY       = "#89dceb"
$env:DOTFILES_COLOR_SAPPHIRE  = "#74c7ec"
$env:DOTFILES_COLOR_BLUE      = "#89b4fa"
$env:DOTFILES_COLOR_LAVENDER  = "#b4befe"
$env:DOTFILES_COLOR_TEXT      = "#cdd6f4"
$env:DOTFILES_COLOR_SUBTEXT1  = "#bac2de"
$env:DOTFILES_COLOR_SUBTEXT0  = "#a6adc8"
$env:DOTFILES_COLOR_OVERLAY2  = "#9399b2"
$env:DOTFILES_COLOR_OVERLAY1  = "#7f849c"
$env:DOTFILES_COLOR_OVERLAY0  = "#6c7086"
$env:DOTFILES_COLOR_SURFACE2  = "#585b70"
$env:DOTFILES_COLOR_SURFACE1  = "#45475a"
$env:DOTFILES_COLOR_SURFACE0  = "#313244"
$env:DOTFILES_COLOR_BASE      = "#1e1e2e"
$env:DOTFILES_COLOR_MANTLE    = "#181825"
$env:DOTFILES_COLOR_CRUST     = "#11111b"

# ── Tool-specific names ───────────────────────────────────────────────────────
$env:BAT_THEME              = "Catppuccin Mocha"
$env:DOTFILES_WEZTERM_THEME = "Catppuccin Mocha"

# ── PSReadLine Syntax Highlighting ───────────────────────────────────────────
# Applies Catppuccin Mocha colors to the interactive PowerShell prompt.
# Colors use the palette variables defined above for consistency.
if (Get-Module -ListAvailable -Name PSReadLine) {
    Set-PSReadLineOption -Colors @{
        Command            = $env:DOTFILES_COLOR_BLUE      # valid commands
        Parameter          = $env:DOTFILES_COLOR_MAUVE     # flags/parameters
        Operator           = $env:DOTFILES_COLOR_SKY       # operators (=, +, |)
        Variable           = $env:DOTFILES_COLOR_TEXT      # $variables
        String             = $env:DOTFILES_COLOR_GREEN     # string literals
        Number             = $env:DOTFILES_COLOR_PEACH     # number literals
        Type               = $env:DOTFILES_COLOR_TEAL      # [type] casts
        Comment            = $env:DOTFILES_COLOR_SURFACE2  # # comments
        Keyword            = $env:DOTFILES_COLOR_RED       # if, for, function
        Error              = $env:DOTFILES_COLOR_RED       # error state
        Default            = $env:DOTFILES_COLOR_TEXT      # default foreground
        Emphasis           = $env:DOTFILES_COLOR_PINK      # emphasis
        Selection          = $env:DOTFILES_COLOR_SURFACE0  # selected text bg
        InlinePrediction   = $env:DOTFILES_COLOR_SURFACE2  # ghost-text suggestions
    }
}
