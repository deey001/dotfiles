# ==============================================================================
# Microsoft.PowerShell_profile.ps1 — PowerShell Profile
# ==============================================================================
# Deployed by scripts/install.ps1 → Configure-PowerShell
# Provides an experience comparable to the bash/zsh setup:
#   - Catppuccin Mocha colors via PSReadLine (modular — loaded from theme file)
#   - Common aliases mirroring .bash_aliases (eza, nvim, git shortcuts)
#   - Starship prompt (must be last)
#
# THEME SYSTEM:
#   Colors are loaded from ~/.config\dotfiles\theme.ps1 — a file deployed by
#   install.ps1 → Configure-PowerShell from themes/windows/<name>.ps1.
#   Inline PSReadLine colors below are the FALLBACK for fresh installs where
#   no theme file has been deployed yet.
#
# COMPATIBLE: PowerShell 5.1 and PowerShell 7+
# ==============================================================================

# ── 1. Active Theme ────────────────────────────────────────────────────────────
# Load theme variables and PSReadLine colors from the deployed theme file.
# The theme file sets $env:DOTFILES_COLOR_*, $env:BAT_THEME, and calls
# Set-PSReadLineOption -Colors with the palette values.
#
# themes/windows/ contains one file per theme:
#   catppuccin-mocha.ps1   (dark, default)
#   catppuccin-latte.ps1   (light)
#
# To switch themes: re-run install.ps1 option 5 after editing
# $env:USERPROFILE\.config\dotfiles\theme.ps1 to point to the desired file,
# OR copy the desired themes/windows/*.ps1 to that path manually.
$_themeFile = "$env:USERPROFILE\.config\dotfiles\theme.ps1"
if (Test-Path $_themeFile) {
    . $_themeFile    # dot-source: loads $env:DOTFILES_COLOR_* + PSReadLine colors
} else {
    # ── Fallback: inline Catppuccin Mocha colors ──────────────────────────────
    # Used when no theme file is deployed (fresh install, or theme step skipped).
    # Keeps the profile functional and themed even without the theme system.
    if (Get-Module -ListAvailable -Name PSReadLine) {
        Import-Module PSReadLine
        Set-PSReadLineOption -Colors @{
            Command            = '#89b4fa'   # blue   — valid commands
            Parameter          = '#cba6f7'   # mauve  — flags/parameters
            Operator           = '#89dceb'   # sky    — operators (=, +, |, etc.)
            Variable           = '#cdd6f4'   # text   — $variables
            String             = '#a6e3a1'   # green  — string literals
            Number             = '#fab387'   # peach  — number literals
            Type               = '#94e2d5'   # teal   — [type] casts
            Comment            = '#585b70'   # surface2 — # comments
            Keyword            = '#f38ba8'   # red    — keywords (if, for, function)
            Error              = '#f38ba8'   # red    — error state
            Default            = '#cdd6f4'   # text   — default foreground
            Emphasis           = '#f5c2e7'   # pink   — emphasis
            Selection          = '#313244'   # surface0 — selected text background
            InlinePrediction   = '#585b70'   # surface2 — ghost-text suggestions
        }
    }
    $env:BAT_THEME = 'Catppuccin Mocha'
}
Remove-Variable _themeFile -ErrorAction SilentlyContinue

# ── 2. PSReadLine Behaviour (non-color settings) ──────────────────────────────
# Color settings are handled by the theme file above.
# These behaviour settings are theme-independent.
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineOption -EditMode Emacs
    # History-based autosuggestion (like ble.sh / zsh-autosuggestions)
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
    # Key bindings
    # Tab cycles forward through completions; Shift+Tab cycles backward.
    Set-PSReadLineKeyHandler -Key Tab             -Function MenuComplete
    Set-PSReadLineKeyHandler -Key Shift+Tab       -Function TabCompletePrevious
    Set-PSReadLineKeyHandler -Key UpArrow         -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow       -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Ctrl+d          -Function DeleteCharOrExit
    Set-PSReadLineKeyHandler -Key Ctrl+LeftArrow  -Function BackwardWord
    Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function ForwardWord
}

# ── 3. Environment Variables ──────────────────────────────────────────────────
$env:EDITOR = 'nvim'
$env:VISUAL = 'nvim'
# BAT_THEME is set by the theme file; fallback here in case theme wasn't loaded.
if (-not $env:BAT_THEME) { $env:BAT_THEME = 'Catppuccin Mocha' }

# ── 4. Aliases — mirroring .bash_aliases ──────────────────────────────────────

# Navigation
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }

# Editor shortcuts
function v { nvim $args }
Set-Alias -Name vi  -Value nvim -Force -Option AllScope
Set-Alias -Name vim -Value nvim -Force -Option AllScope

# Git shortcuts (mirror of .bash_aliases)
function g { git $args }
function ga { git add $args }
function gst { git status $args }
function gd { git diff $args }
function gc { git commit -m $args }
function gp { git push $args }
function gl { git pull $args }
function gco { git checkout $args }
function glog { git log --oneline --graph --color --all --decorate $args }

# Docker shortcuts
function d { docker $args }
function dc { docker compose $args }

# Quick shell actions
function c { Clear-Host }
function q { exit }
function da { Get-Date -Format "yyyy-MM-dd dddd HH:mm:ss" }

# ── 4. ls/eza aliases ─────────────────────────────────────────────────────────
if (Get-Command eza -ErrorAction SilentlyContinue) {
    function ls   { eza --color=auto --icons $args }
    function ll   { eza -alF --icons --git $args }
    function la   { eza -A --icons $args }
    function l    { eza -CF --icons $args }
    function tree { eza --tree --icons $args }
} else {
    # Fallback to Get-ChildItem with color
    function ll { Get-ChildItem -Force $args }
    function la { Get-ChildItem -Force $args }
}

# ── 5. cat/bat alias ─────────────────────────────────────────────────────────
if (Get-Command bat -ErrorAction SilentlyContinue) {
    function cat { bat --paging=never $args }
}

# ── 6. mkcd — create and enter a directory ───────────────────────────────────
function mkcd {
    param([string]$Path)
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    Set-Location $Path
}

# ── 7. which — find command location (like Unix which) ───────────────────────
function which {
    param([string]$Command)
    (Get-Command $Command -ErrorAction SilentlyContinue).Source
}

# ── 8. PATH additions ─────────────────────────────────────────────────────────
# Ensure common tool locations are on PATH
$extraPaths = @(
    "$env:USERPROFILE\.local\bin",
    "$env:USERPROFILE\bin",
    "$env:APPDATA\npm"
)
foreach ($p in $extraPaths) {
    if ((Test-Path $p) -and ($env:PATH -notlike "*$p*")) {
        $env:PATH = "$p;$env:PATH"
    }
}

# ── 9. Zoxide — smarter cd (if installed) ────────────────────────────────────
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# ── 10. Starship prompt (MUST be last) ───────────────────────────────────────
# STARSHIP_CONFIG is set as a User environment variable by install.ps1.
# Fallback: also set it here in case the env var wasn't persisted yet.
if (-not $env:STARSHIP_CONFIG) {
    $env:STARSHIP_CONFIG = "$env:USERPROFILE\.config\starship.toml"
}
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}
