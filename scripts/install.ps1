<#
Install tools with winget and link configs on Windows.

  irm https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.ps1 | iex
  .\scripts\install.ps1            # from a local clone

Run from an elevated PowerShell (or turn on Developer Mode) so symlinks can be
created. Safe to re-run. Existing files that would be replaced are moved to
~\.dotfiles-backup\<timestamp>\ first; uninstall.ps1 puts them back.
#>

$Repo = 'https://github.com/deey001/dotfiles.git'

$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
$devMode = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense -eq 1
if (-not ($admin -or $devMode)) { throw 'Run from an elevated PowerShell (or turn on Developer Mode) so symlinks can be created.' }
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw 'winget not found. Install "App Installer" from the Microsoft Store.' }

function Update-Path {
    $env:PATH = [Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('PATH', 'User')
}

# Install one winget package unless it's already there; never abort the run.
function Install-WingetPackage($Id) {
    winget list --id $Id --exact --accept-source-agreements | Out-Null
    if ($LASTEXITCODE -eq 0) { return }
    Write-Host "  installing $Id"
    winget install --id $Id --exact --silent --accept-package-agreements --accept-source-agreements | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Host "  skipped: $Id" -ForegroundColor Yellow }
}

if ($PSCommandPath) {
    $Dotfiles = Split-Path (Split-Path $PSCommandPath)
} else {
    # Piped from irm: clone (or update) ~\dotfiles, then continue from there.
    Install-WingetPackage Git.Git
    Update-Path
    $Dotfiles = "$HOME\dotfiles"
    if (Test-Path "$Dotfiles\.git") { git -C $Dotfiles pull --ff-only } else { git clone $Repo $Dotfiles }
}

Write-Host '--- Packages ---'
Get-Content "$Dotfiles\platform\packages\winget.txt" |
    Where-Object { $_ -match '^\s*[^#\s]' } |
    ForEach-Object { Install-WingetPackage ($_.Trim() -split '\s+')[0] }
Update-Path

# PSFzf gives PowerShell fzf's Ctrl+R / Ctrl+T, like fzf's bash keybindings.
foreach ($shell in 'pwsh', 'powershell') {
    if (Get-Command $shell -ErrorAction SilentlyContinue) {
        & $shell -NoProfile -Command {
            if (Get-Module -ListAvailable PSFzf) { return }
            if ($PSVersionTable.PSEdition -eq 'Desktop') {
                Install-PackageProvider NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force | Out-Null
            }
            Install-Module PSFzf -Scope CurrentUser -Force
        }
    }
}

# Windows PowerShell 5 refuses to load profiles under the default policy.
try { Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force } catch { Write-Host "  could not set execution policy: $_" -ForegroundColor Yellow }

Write-Host '--- Linking dotfiles ---'
. "$Dotfiles\platform\windows\links.ps1"

# Drop links into the repo that the current layout no longer uses (older
# versions linked ~\.bashrc, ~\.config\nvim, ~\starship.toml and others).
Get-ChildItem $HOME, "$HOME\.config" -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.LinkType -eq 'SymbolicLink' -and "$($_.Target)" -like "$Dotfiles\*" -and -not $Links.Contains($_.FullName) } |
    ForEach-Object { Remove-Link $_.FullName; Write-Host "  removed old link $($_.FullName)" }

$backup = "$HOME\.dotfiles-backup\$(Get-Date -Format 'yyyyMMdd-HHmmss')"
foreach ($target in $Links.Keys) {
    $source = Join-Path $Dotfiles $Links[$target]
    if (Test-Linked $target $source) { continue }
    if (Test-Path -LiteralPath $target) {
        $dest = Get-BackupPath $backup $target
        New-Item -ItemType Directory (Split-Path $dest) -Force | Out-Null
        Move-Item -LiteralPath $target $dest
        Write-Host "  backed up $target"
    } elseif (Get-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue) {
        Remove-Link $target  # dangling link
    }
    New-Item -ItemType Directory (Split-Path $target) -Force | Out-Null
    New-Item -ItemType SymbolicLink -Path $target -Target $source | Out-Null
}

Write-Host '--- PuTTY ---'
. "$Dotfiles\platform\windows\putty.ps1"
# Save PuTTY's sessions once, before the first change, so uninstall.ps1 can put them back.
$saved = Get-ChildItem "$HOME\.dotfiles-backup" -Recurse -Filter putty-sessions.reg -ErrorAction SilentlyContinue
if (-not $saved -and (Test-Path $PuttySessions)) {
    New-Item -ItemType Directory $backup -Force | Out-Null
    reg export 'HKCU\Software\SimonTatham\PuTTY\Sessions' "$backup\putty-sessions.reg" /y | Out-Null
    Write-Host '  backed up PuTTY sessions'
}
Write-Host '  font, colours, UTF-8, xterm-256color, logging (where off) for:'
Set-PuttyDefaults

Write-Host 'Done. Restart Windows Terminal to pick up the font, colors and profile.'
Write-Host 'For servers: curl -fsSL https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.sh | bash'
