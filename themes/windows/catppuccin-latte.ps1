# ==============================================================================
# themes/windows/catppuccin-latte.ps1 — PSReadLine Catppuccin Latte (Light)
# ==============================================================================
# Light/day-mode variant. Same variable API as catppuccin-mocha.ps1.
# PALETTE REFERENCE: https://catppuccin.com/palette  (Latte column)
# ==============================================================================

$env:DOTFILES_THEME         = "catppuccin-latte"
$env:DOTFILES_THEME_DISPLAY = "Catppuccin Latte"

$env:DOTFILES_COLOR_ROSEWATER = "#dc8a78"
$env:DOTFILES_COLOR_FLAMINGO  = "#dd7878"
$env:DOTFILES_COLOR_PINK      = "#ea76cb"
$env:DOTFILES_COLOR_MAUVE     = "#8839ef"
$env:DOTFILES_COLOR_RED       = "#d20f39"
$env:DOTFILES_COLOR_MAROON    = "#e64553"
$env:DOTFILES_COLOR_PEACH     = "#fe640b"
$env:DOTFILES_COLOR_YELLOW    = "#df8e1d"
$env:DOTFILES_COLOR_GREEN     = "#40a02b"
$env:DOTFILES_COLOR_TEAL      = "#179299"
$env:DOTFILES_COLOR_SKY       = "#04a5e5"
$env:DOTFILES_COLOR_SAPPHIRE  = "#209fb5"
$env:DOTFILES_COLOR_BLUE      = "#1e66f5"
$env:DOTFILES_COLOR_LAVENDER  = "#7287fd"
$env:DOTFILES_COLOR_TEXT      = "#4c4f69"
$env:DOTFILES_COLOR_SUBTEXT1  = "#5c5f77"
$env:DOTFILES_COLOR_SUBTEXT0  = "#6c6f85"
$env:DOTFILES_COLOR_OVERLAY2  = "#7c7f93"
$env:DOTFILES_COLOR_OVERLAY1  = "#8c8fa1"
$env:DOTFILES_COLOR_OVERLAY0  = "#9ca0b0"
$env:DOTFILES_COLOR_SURFACE2  = "#acb0be"
$env:DOTFILES_COLOR_SURFACE1  = "#bcc0cc"
$env:DOTFILES_COLOR_SURFACE0  = "#ccd0da"
$env:DOTFILES_COLOR_BASE      = "#eff1f5"
$env:DOTFILES_COLOR_MANTLE    = "#e6e9ef"
$env:DOTFILES_COLOR_CRUST     = "#dce0e8"

$env:BAT_THEME              = "Catppuccin Latte"
$env:DOTFILES_WEZTERM_THEME = "Catppuccin Latte"

$_psrl = Get-Module -ListAvailable -Name PSReadLine | Select-Object -First 1
if ($_psrl) {
    $_colors = @{
        Command   = $env:DOTFILES_COLOR_BLUE
        Parameter = $env:DOTFILES_COLOR_MAUVE
        Operator  = $env:DOTFILES_COLOR_SKY
        Variable  = $env:DOTFILES_COLOR_TEXT
        String    = $env:DOTFILES_COLOR_GREEN
        Number    = $env:DOTFILES_COLOR_PEACH
        Type      = $env:DOTFILES_COLOR_TEAL
        Comment   = $env:DOTFILES_COLOR_SURFACE2
        Keyword   = $env:DOTFILES_COLOR_RED
        Error     = $env:DOTFILES_COLOR_RED
        Default   = $env:DOTFILES_COLOR_TEXT
        Emphasis  = $env:DOTFILES_COLOR_PINK
        Selection = $env:DOTFILES_COLOR_SURFACE0
    }
    # InlinePrediction needs PSReadLine 2.1+; Win PS 5.1 ships 2.0.x.
    if ($_psrl.Version -ge [Version]'2.1.0') {
        $_colors.InlinePrediction = $env:DOTFILES_COLOR_SURFACE2
    }
    Set-PSReadLineOption -Colors $_colors
    Remove-Variable _colors -ErrorAction SilentlyContinue
}
Remove-Variable _psrl -ErrorAction SilentlyContinue
