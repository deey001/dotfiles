# VERSION: 1.0.6 (RELIABLE-LINKING)
# ========================================================================================

# Force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Helper: Check if the current user has Administrator privileges.
function Test-AdminPrivileges {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Auto-Elevate: If not running as Admin, download the script to a temp file and relaunch
if (-not (Test-AdminPrivileges)) {
    Write-Host "█▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█" -ForegroundColor Red
    Write-Host "█  ADMINISTRATOR PRIVILEGES REQUIRED - AUTO-ELEVATING    █" -ForegroundColor Yellow
    Write-Host "█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█" -ForegroundColor Red
    Write-Host "`nPlease accept the UAC prompt to continue..." -ForegroundColor Gray
    
    $TempScript = "$env:TEMP\DotfilesSetup.ps1"
    try {
        $v = Get-Random
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.ps1?v=$v" -OutFile $TempScript -UseBasicParsing
        Start-Process powershell -Verb RunAs -ArgumentList "-NoExit", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$TempScript`""
    } catch {
        Write-Host "`n[ERROR] Failed to prepare auto-elevation: $_" -ForegroundColor Red
    }
    exit
}

# PowerShell Version Check
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "Detected PowerShell $($PSVersionTable.PSVersion.Major). Installing PowerShell 7..." -ForegroundColor Yellow
    winget install --id Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements | Out-Null
    
    $pwsh7Path = "C:\Program Files\PowerShell\7\pwsh.exe"
    if (Test-Path $pwsh7Path) {
        $TempScript = "$env:TEMP\DotfilesSetup.ps1"
        $v = Get-Random
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.ps1?v=$v" -OutFile $TempScript -UseBasicParsing
        Start-Process -FilePath $pwsh7Path -Verb RunAs -ArgumentList "-NoExit", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$TempScript`""
        exit 0
    }
}

try {
    [System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $script:UseColors = $true
} catch {
    $script:UseColors = $false
}

$FONT_DOWNLOAD_URL = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
$TEMP_DIR = "$env:TEMP\nerd-fonts-install"
$BACKUP_DIR = "$env:USERPROFILE\.dotfiles-backup"
$BACKUP_TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"
$LOG_FILE = "$env:USERPROFILE\Documents\dotfiles-install-log-$BACKUP_TIMESTAMP.txt"

$script:InstallationLog = @()
$script:ActionsPerformed = @()

$colors = @{
    Reset   = "`e[0m"; Red = "`e[91m"; Green = "`e[92m"; Yellow = "`e[93m"
    Cyan    = "`e[96m"; Magenta = "`e[95m"; Gray = "`e[90m"; White = "`e[97m"
}

function Write-Log {
    param([string]$Message, $Level = "INFO")
    $script:InstallationLog += "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message"
}

function Add-Action { param($Action) $script:ActionsPerformed += $Action; Write-Log $Action "ACTION" }

function Write-ColorText {
    param($Message, $Color)
    Write-Log $Message "OUTPUT"
    if ($script:UseColors) { Write-Host "$($colors[$Color])$Message$($colors.Reset)" } else { Write-Host $Message -ForegroundColor $Color }
}

function Write-Status {
    param($Message, $StatusType)
    $map = @{ Success = @{I='[OK]';C='Green'}; Error = @{I='[!!]';C='Red'}; Progress = @{I='[>>]';C='Cyan'}; Warning = @{I='[! ]';C='Yellow'}; Info = @{I='[i ]';C='Gray'} }
    $s = $map[$StatusType]; if (-not $s) { $s = $map['Info'] }
    Write-ColorText "$($s.I) $Message" $s.C
}

function Backup-Settings {
    try {
        $timestampDir = Join-Path $BACKUP_DIR $BACKUP_TIMESTAMP
        New-Item -Path $timestampDir -ItemType Directory -Force | Out-Null
        $wtPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        if (Test-Path $wtPath) { Copy-Item $wtPath (Join-Path $timestampDir "settings.json") }
        Add-Action "Backup created at $timestampDir"
    } catch { Write-Log "Backup failed: $_" "ERROR" }
}

function Install-NerdFont {
    try {
        Write-Host "Installing Nerd Font..." -ForegroundColor Cyan
        New-Item $TEMP_DIR -ItemType Directory -Force | Out-Null
        $zip = Join-Path $TEMP_DIR "font.zip"
        Invoke-WebRequest -Uri $FONT_DOWNLOAD_URL -OutFile $zip
        Expand-Archive $zip $TEMP_DIR -Force
        $shell = New-Object -ComObject Shell.Application
        $fontsFolder = $shell.Namespace(0x14)
        Get-ChildItem $TEMP_DIR -Filter "*.ttf" -Recurse | ForEach-Object {
            if (-not (Test-Path "$env:SystemRoot\Fonts\$($_.Name)")) {
                $fontsFolder.CopyHere($_.FullName, 0x10)
            }
        }
        Remove-Item $TEMP_DIR -Recurse -Force
        Add-Action "Installed JetBrainsMono Nerd Font"
        Write-Status "Nerd Font installed" "Success"
    } catch { Write-Status "Font failed: $_" "Error" }
}

function Configure-WindowsTerminal {
    try {
        Write-Host "Configuring Windows Terminal..." -ForegroundColor Cyan
        $wtPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        if (Test-Path $wtPath) {
            $settings = Get-Content $wtPath -Raw | ConvertFrom-Json
            if (-not $settings.profiles.defaults) { $settings.profiles | Add-Member NoteProperty defaults ([PSCustomObject]@{}) }
            if (-not $settings.profiles.defaults.font) { $settings.profiles.defaults | Add-Member NoteProperty font ([PSCustomObject]@{ face = "JetBrainsMono Nerd Font" }) }
            else { $settings.profiles.defaults.font.face = "JetBrainsMono Nerd Font" }
            $settings | ConvertTo-Json -Depth 100 | Set-Content $wtPath -Encoding UTF8
            Write-Status "Updated Windows Terminal" "Success"
        }
    } catch { Write-Status "WT config failed: $_" "Error" }
}

function Configure-PuTTY {
    try {
        $reg = "HKCU:\Software\SimonTatham\PuTTY\Sessions\Default%20Settings"
        if (-not (Test-Path $reg)) { New-Item $reg -Force | Out-Null }
        Set-ItemProperty $reg -Name "Font" -Value "JetBrainsMono Nerd Font"
        Set-ItemProperty $reg -Name "FontHeight" -Value 12
        Write-Status "PuTTY configured" "Success"
    } catch { Write-Status "PuTTY failed: $_" "Error" }
}

function Install-CoreTools {
    try {
        $tools = @("Neovim.Neovim", "Git.Git", "BurntSushi.Ripgrep", "sharkdp.fd", "starship.starship", "eza-community.eza", "fastfetch-cli.fastfetch")
        foreach ($t in $tools) {
            Write-Status "Installing $t..." "Progress"
            winget install --id $t --silent --accept-package-agreements --accept-source-agreements | Out-Null
        }
        Write-Status "Core Tools installed" "Success"
    } catch { Write-Status "Winget failed: $_" "Error" }
}

function Configure-PowerShell {
    try {
        Write-Host "Configuring PowerShell Profiles..." -ForegroundColor Cyan
        $profilePaths = @("$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1", "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1", $PROFILE) | Select-Object -Unique
        $starshipLine = 'starship init powershell | Invoke-Expression'
        foreach ($path in $profilePaths) {
            $newContent = @()
            if (Test-Path $path) {
                $newContent = Get-Content $path | Where-Object { $_ -notmatch "starship" -and $_ -notmatch "oh-my-posh" -and $_ -notmatch "Invoke-Expression" }
            }
            $dir = Split-Path -Parent $path
            if (-not (Test-Path $dir)) { New-Item $dir -ItemType Directory -Force | Out-Null }
            $final = @("# Added by Dotfiles Setup", $starshipLine)
            if ($newContent) { $final = $newContent + $final }
            $final | Out-File $path -Encoding UTF8 -Force
        }
        Write-Status "PowerShell Profiles configured" "Success"
    } catch { Write-Status "PowerShell failed: $_" "Error" }
}

function Symlink-Dotfiles {
    try {
        Write-Host "Symlinking dotfiles..." -ForegroundColor Cyan
        $userHome = $env:USERPROFILE
        $scriptPath = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
        $dotfilesDir = $scriptPath | Split-Path -Parent
        if (-not (Test-Path (Join-Path $dotfilesDir "stow"))) {
            $dotfilesDir = Join-Path $userHome "dotfiles"
            if (-not (Test-Path $dotfilesDir)) {
                Write-Status "Cloning repository..." "Warning"
                git clone "https://github.com/deey001/dotfiles.git" $dotfilesDir
            }
        }
        $fileMap = @{ ".bashrc"="stow\bash\.bashrc"; ".bash_aliases"="stow\bash\.bash_aliases"; ".blerc"="stow\bash\.blerc"; ".tmux.conf"="stow\tmux\.tmux.conf"; ".gitconfig"="stow\git\.gitconfig"; ".inputrc"="stow\shell\.inputrc"; ".common_shell"="stow\shell\.common_shell" }
        foreach ($f in $fileMap.Keys) {
            $src = Join-Path $dotfilesDir $fileMap[$f]; $tgt = Join-Path $userHome $f
            if (Test-Path $src) { if (Test-Path $tgt) { Remove-Item $tgt -Force }; New-Item -ItemType SymbolLink -Path $tgt -Value $src -Force | Out-Null }
        }
        $configSrc = Join-Path $dotfilesDir "stow\config\.config"; $configTgt = Join-Path $userHome ".config"
        if (Test-Path $configSrc) {
            if (-not (Test-Path $configTgt)) { New-Item $configTgt -ItemType Directory -Force | Out-Null }
            Get-ChildItem $configSrc | ForEach-Object {
                $iSrc = $_.FullName; $iTgt = Join-Path $configTgt $_.Name
                if (Test-Path $iTgt) { if ($_.PSIsContainer) { Remove-Item $iTgt -Recurse -Force } else { Remove-Item $iTgt -Force } }
                New-Item -ItemType SymbolLink -Path $iTgt -Value $iSrc -Force | Out-Null
                if ($_.Name -eq "starship.toml") { $rTgt = Join-Path $userHome "starship.toml"; if (Test-Path $rTgt) { Remove-Item $rTgt -Force }; New-Item -ItemType SymbolLink -Path $rTgt -Value $iSrc -Force | Out-Null }
            }
        }
        Write-Status "Dotfiles symlinked" "Success"
    } catch { Write-Status "Symlinking failed: $_" "Error" }
}

function Install-RemoteDotfiles {
    Write-ColorText "`nREMOTE SERVER SETUP" "Cyan"
    Write-Host "Run this on your server:"
    Write-ColorText "curl -fsSL https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.sh | bash" "Yellow"
}

function Show-Menu {
    Clear-Host
    Write-ColorText "╔══════════════════════════════════════════════════╗" "Cyan"
    Write-ColorText "║          DOTFILES WINDOWS SETUP TOOL             ║" "Cyan"
    Write-ColorText "╚══════════════════════════════════════════════════╝" "Cyan"
    Write-Host ""
    Write-ColorText " [1] Install Nerd Font" "Yellow"
    Write-ColorText " [2] Configure Windows Terminal Font" "Yellow"
    Write-ColorText " [3] Configure PuTTY Font" "Yellow"
    Write-ColorText " [4] Install Core Tools (Winget)" "Yellow"
    Write-ColorText " [5] Configure PowerShell Profile" "Yellow"
    Write-ColorText " [6] Full Local Setup (1-5)" "Green"
    Write-ColorText " [7] Symlink Dotfiles" "Green"
    Write-ColorText " [8] Remote Setup Guide" "Yellow"
    Write-ColorText " [9] Complete Workflow (1-8)" "Yellow"
    Write-ColorText " [0] Exit" "Red"
    Write-Host "`nEnter choice: " -NoNewline
}

function Main {
    try {
        Backup-Settings
        do {
            Show-Menu
            $c = Read-Host
            switch ($c) {
                "1" { Install-NerdFont }
                "2" { Configure-WindowsTerminal }
                "3" { Configure-PuTTY }
                "4" { Install-CoreTools }
                "5" { Configure-PowerShell }
                "6" { Install-NerdFont; Configure-WindowsTerminal; Configure-PuTTY; Install-CoreTools; Configure-PowerShell }
                "7" { Symlink-Dotfiles }
                "8" { Install-RemoteDotfiles }
                "9" { Install-NerdFont; Configure-WindowsTerminal; Configure-PuTTY; Install-CoreTools; Configure-PowerShell; Symlink-Dotfiles; Install-RemoteDotfiles }
                "0" { break }
            }
            if ($c -ne "0") { Read-Host "`nPress Enter to continue" }
        } while ($c -ne "0")
    } catch { Write-Error "Error: $_" }
}
Main
