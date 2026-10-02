# PowerShell profile (PowerShell 7 and Windows PowerShell 5).
# Mirrors Omarchy's bash defaults: default/bash/{envs,inputrc,init,aliases,fns}.
# Machine-specific additions go in ~\.pwsh_local.ps1 (untracked).

# Environment
$env:EDITOR = 'nvim'
$env:BAT_THEME = 'ansi'
if ($env:PATH -notlike "*$HOME\.local\bin*") { $env:PATH = "$HOME\.local\bin;$env:PATH" }

# Line editing (like Omarchy's inputrc)
if (Get-Module -ListAvailable PSReadLine) {
    Set-PSReadLineOption -EditMode Emacs -HistoryNoDuplicates -BellStyle None
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key Shift+Tab -Function TabCompletePrevious
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}

# Tools
if (Get-Command starship -ErrorAction SilentlyContinue) { Invoke-Expression (&starship init powershell) }
if (Get-Command zoxide -ErrorAction SilentlyContinue) { Invoke-Expression (& { (zoxide init powershell | Out-String) }) }
if (Get-Module -ListAvailable PSFzf) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}

# Built-in aliases win over functions, so clear the ones Omarchy's names reuse.
foreach ($a in 'ls', 'cd', 'gcm') { Remove-Item "Alias:$a" -Force -ErrorAction SilentlyContinue }

# File system
if (Get-Command eza -ErrorAction SilentlyContinue) {
    function ls { eza -lh --group-directories-first --icons=auto @args }
    function lsa { ls -a @args }
    function lt { eza --tree --level=2 --long --icons --git @args }
    function lta { lt -a @args }
} else {
    Set-Alias ls Get-ChildItem
}

function ff { fzf --preview 'bat --style=numbers --color=always {}' @args }
function eff { & $env:EDITOR (ff) }

function zd {
    if ($args.Count -eq 0) { Set-Location ~ }
    elseif (Test-Path -LiteralPath $args[0] -PathType Container) { Set-Location -LiteralPath $args[0] }
    elseif (Get-Command z -ErrorAction SilentlyContinue) { $before = $PWD.Path; z @args; if ($PWD.Path -ne $before) { $PWD.Path } }
    else { Write-Host 'Error: Directory not found' }
}
Set-Alias cd zd

function open { Invoke-Item @args }

# Directories
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }

# Tools
function d { docker @args }
function n { if ($args.Count -eq 0) { nvim . } else { nvim @args } }

# Git
function g { git @args }
function gcm { git commit -m @args }
function gcam { git commit -a -m @args }
function gcad { git commit -a --amend @args }

# Compression
function compress($Path) { $p = $Path.TrimEnd('\', '/'); tar -czf "$p.tar.gz" $p }
function decompress { tar -xzf @args }

if (Test-Path "$HOME\.pwsh_local.ps1") { . "$HOME\.pwsh_local.ps1" }
