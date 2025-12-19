<#
.SYNOPSIS
    Dotfiles Windows Local Setup Installer
    One-liner: irm "https://raw.githubusercontent.com/deey001/dotfiles/master/install.ps1" | iex

.DESCRIPTION
    This script prepares a Windows workstation so that Nerd Font icons from your dotfiles
    (Starship prompt, etc.) display correctly when connecting to Linux servers.

    Why this exists:
    - Colleagues reported icons not showing after running install.sh on the server
    - Root cause: Local Windows terminal (Windows Terminal or PuTTY/KeePass) lacked Nerd Fonts
    - KeePass loads PuTTY's Default Settings — not saved sessions — so we must modify those

    Features (per your explicit requests):
    - One-liner installation like Chris Titus WinUtil
    - Interactive menu with descriptions
    - Auto-upgrade PowerShell 5 → 7 without user choice
    - Auto-relaunch as Administrator in PowerShell 7 to continue seamlessly
    - Install UbuntuMono Nerd Font
    - Configure Windows Terminal defaults
    - Configure PuTTY Default%20Settings registry (KeePass compatible)
    - Automatic timestamped backups before any changes
    - Restore from backup option
    - Reset/remove option
    - Comprehensive logging + summary saved to Documents
    - Guidance for remote server installation
    - Extreme inline documentation for beginners/colleagues

    KISS principle followed throughout.
#>

# ========================================================================================
# Section 1: PowerShell Version Detection and Automatic Upgrade
# ========================================================================================
# Why this section exists:
# - PowerShell 5 does not support ANSI/VT sequences → colors show as raw escape codes
# - Your screenshot showed exactly this problem
# - You explicitly said: "I dont want to give them an option, auto upgrade to 7"
# - Also: "Is there anyway are the ps7 install to auto launch and continue the installation as terminal admin?"

if ($PSVersionTable.PSVersion.Major -lt 7) {
    # Inform user what's happening
    Write-Host "PowerShell version $($PSVersionTable.PSVersion.Major) detected." -ForegroundColor Yellow
    Write-Host "Upgrading to PowerShell 7 automatically (required for colors and reliability)..." -ForegroundColor Yellow

    # Install PowerShell 7 silently using winget (built-in on modern Windows)
    # --silent: no prompts
    # --accept-*: auto-accept EULA and source agreements
    $result = winget install --id Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements 2>&1

    # Common installation paths for pwsh.exe
    $possiblePaths = @(
        "$env:ProgramFiles\PowerShell\7\pwsh.exe"
        "C:\Program Files\PowerShell\7\pwsh.exe"
        "${env:ProgramFiles(x86)}\PowerShell\7\pwsh.exe"
    )
    $pwsh7Path = $possiblePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    # Check if installation succeeded
    if ($pwsh7Path -and ($LASTEXITCODE -eq 0 -or $result -match "successfully installed")) {
        Write-Host "PowerShell 7 installed successfully." -ForegroundColor Green
        Write-Host "Relaunching installer in new elevated PowerShell 7 window..." -ForegroundColor Green

        # The exact same one-liner command to continue installation
        $continueCommand = "irm 'https://raw.githubusercontent.com/deey001/dotfiles/master/install.ps1' | iex"

        # Launch PowerShell 7 as Administrator, bypassing profile, bypassing execution policy
        Start-Process -FilePath $pwsh7Path -Verb RunAs -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $continueCommand

        # Give the new window time to appear before closing this one
        Start-Sleep -Seconds 3
        exit 0
    } else {
        Write-Host "Failed to install PowerShell 7 automatically." -ForegroundColor Red
        Write-Host "Please install manually from https://github.com/PowerShell/PowerShell/releases and rerun." -ForegroundColor Red
        exit 1
    }
}

# ========================================================================================
# Section 2: Enable UTF-8 and ANSI Color Support
# ========================================================================================
# Why: Ensures icons and colors render properly in PowerShell 7+
# PowerShell 7 supports Virtual Terminal sequences natively
try {
    [System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $script:UseColors = $true
} catch {
    $script:UseColors = $false  # Fallback if something goes wrong (unlikely in PS7)
}

# ========================================================================================
# Section 3: Global Configuration Variables
# ========================================================================================
# Why centralized: Easy to modify, single source of truth
$FONT_DOWNLOAD_URL = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/UbuntuMono.zip"
$TEMP_DIR = "$env:TEMP\nerd-fonts-install"                         # Temporary working directory
$BACKUP_DIR = "$env:USERPROFILE\.dotfiles-backup"                 # Hidden folder for backups
$BACKUP_TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"            # Unique per run
$LOG_FILE = "$env:USERPROFILE\Documents\dotfiles-install-log-$BACKUP_TIMESTAMP.txt"

# Script-scoped arrays to track what happened during this run
$script:InstallationLog = @()      # Full timestamped log for audit
$script:ActionsPerformed = @()     # High-level actions for summary

# ========================================================================================
# Section 4: ANSI Escape Code Definitions
# ========================================================================================
# Why hashtable: Fast lookup, clean code
# These are standard bright colors that work reliably in PowerShell 7 and Windows Terminal
$colors = @{
    Reset   = "`e[0m"
    Red     = "`e[91m"
    Green   = "`e[92m"
    Yellow  = "`e[93m"
    Cyan    = "`e[96m"
    Magenta = "`e[95m"
    Gray    = "`e[90m"
    White   = "`e[97m"
}

# ========================================================================================
# Section 5: Core Helper Functions (Logging, Output, Tests)
# ========================================================================================

function Write-Log {
    <#
    .DESCRIPTION
    Adds a timestamped entry to the installation log.
    All output should go through logging for complete audit trail.
    #>
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] [$Level] $Message"
    $script:InstallationLog += $entry
}

function Add-Action {
    <#
    .DESCRIPTION
    Records a high-level user-visible action for the final summary.
    #>
    param([string]$Action)
    $script:ActionsPerformed += $Action
    Write-Log $Action "ACTION"
}

function Write-ColorText {
    <#
    .DESCRIPTION
    Outputs text with ANSI colors if supported, otherwise falls back to basic Write-Host colors.
    Used everywhere for consistent appearance.
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [Parameter(Mandatory=$true)][string]$Color
    )

    Write-Log $Message "OUTPUT"

    if ($script:UseColors) {
        $code = $colors[$Color]
        if (-not $code) { $code = "" }
        Write-Host "$code$Message$($colors.Reset)" -NoNewline
    } else {
        # Fallback mapping for PowerShell 5 (in case something unexpected happens)
        $map = @{ Red="Red"; Green="Green"; Yellow="Yellow"; Cyan="Cyan"; Gray="Gray"; White="White" }
        $fg = $map[$Color] ? $map[$Color] : "White"
        Write-Host $Message -ForegroundColor $fg -NoNewline
    }
}

function Write-Status {
    <#
    .DESCRIPTION
    Displays status with Unicode icons and appropriate color.
    Makes output more readable and professional.
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [ValidateSet("Success","Error","Warning","Info","Progress")][string]$StatusType = "Info"
    )

    $map = @{
        Success  = @{ Icon = "✓"; Color = "Green" }
        Error    = @{ Icon = "✗"; Color = "Red" }
        Warning  = @{ Icon = "!"; Color = "Yellow" }
        Info     = @{ Icon = "i"; Color = "Gray" }
        Progress = @{ Icon = "→"; Color = "Cyan" }
    }
    $status = $map[$StatusType]

    $formatted = "[$($status.Icon)] $Message"
    Write-ColorText $formatted $status.Color
    Write-Host ""
}

function Test-AdminPrivileges {
    <#
    .DESCRIPTION
    Checks if script is running elevated.
    Required for font installation and some registry operations.
    #>
    try {
        $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        Write-Log "Admin privilege check failed: $_" "ERROR"
        return $false
    }
}

function Test-FontInstalled {
    <#
    .DESCRIPTION
    Checks if UbuntuMono Nerd Font is already installed system-wide.
    Prevents unnecessary re-download/install.
    #>
    param([string]$FontName = "UbuntuMono Nerd Font")

    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
    if (-not (Test-Path $regPath)) { return $false }

    $props = Get-ItemProperty -Path $regPath
    return ($props.PSObject.Properties.Value -like "*$FontName*").Count -gt 0
}

# ========================================================================================
# Section 6: Backup and Restore Functions
# ========================================================================================

function Backup-Settings {
    <#
    .DESCRIPTION
    Creates a timestamped backup of terminal configurations before any changes.
    You requested: "Please add an option to restore all settings back to default. Make sure to have a backup."
    This runs automatically at start.
    #>
    try {
        $backupPath = Join-Path $BACKUP_DIR $BACKUP_TIMESTAMP
        New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
        Write-Log "Created backup directory: $backupPath"

        # PuTTY Default Settings registry export
        $puttyReg = "HKCU\Software\SimonTatham\PuTTY\Sessions\Default%20Settings"
        $puttyFile = Join-Path $backupPath "putty-default.reg"
        if (Test-Path $puttyReg) {
            reg export "$puttyReg" $puttyFile /y | Out-Null
            Write-Log "Backed up PuTTY Default Settings"
        }

        # Windows Terminal settings.json
        $wtPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        if (Test-Path $wtPath) {
            Copy-Item $wtPath (Join-Path $backupPath "wt-settings.json")
            Write-Log "Backed up Windows Terminal settings"
        }

        # Metadata for easier restore later
        $meta = @{ Timestamp = $BACKUP_TIMESTAMP; Actions = $script:ActionsPerformed }
        $meta | ConvertTo-Json | Set-Content (Join-Path $backupPath "metadata.json")

        Add-Action "Created backup: $BACKUP_TIMESTAMP"
        Write-Status "Settings backed up successfully" "Success"
    } catch {
        Write-Log "Backup failed: $_" "ERROR"
        Write-Status "Failed to create backup" "Error"
    }
}

function Restore-Settings {
    <#
    .DESCRIPTION
    Interactive restore from previous timestamped backups.
    Menu option [8].
    #>
    try {
        $backups = Get-ChildItem -Path $BACKUP_DIR -Directory | Sort-Object Name -Descending
        if ($backups.Count -eq 0) {
            Write-Status "No backups found in $BACKUP_DIR" "Warning"
            return
        }

        Write-ColorText "`nAvailable backups:" "Cyan"
        $backups | ForEach-Object { Write-Host "  $($backups.IndexOf($_) + 1). $($_.Name)" }

        $choice = Read-Host "`nEnter number to restore (0 to cancel)"
        if ($choice -eq "0" -or -not ($choice -match '^\d+$') -or $choice -gt $backups.Count) {
            Write-Status "Restore cancelled" "Info"
            return
        }

        $selected = $backups[$choice - 1].FullName

        # Restore PuTTY
        $puttyFile = Join-Path $selected "putty-default.reg"
        if (Test-Path $puttyFile) {
            reg import $puttyFile | Out-Null
            Write-Log "Restored PuTTY Default Settings"
        }

        # Restore Windows Terminal
        $wtFile = Join-Path $selected "wt-settings.json"
        $wtTarget = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        if (Test-Path $wtFile -and (Test-Path (Split-Path $wtTarget))) {
            Copy-Item $wtFile $wtTarget -Force
            Write-Log "Restored Windows Terminal settings"
        }

        Add-Action "Restored settings from backup $BACKUP_TIMESTAMP"
        Write-Status "Restore completed — restart terminals" "Success"
    } catch {
        Write-Log "Restore error: $_" "ERROR"
        Write-Status "Restore failed" "Error"
    }
}

# ========================================================================================
# Section 7: Core Installation Functions
# ========================================================================================

function Install-NerdFont {
    <#
    .DESCRIPTION
    Downloads and installs UbuntuMono Nerd Font if not already present.
    Uses shell.application COM object for silent font installation.
    #>
    try {
        if (Test-FontInstalled) {
            Write-Status "UbuntuMono Nerd Font already installed" "Info"
            return
        }

        Write-Status "Downloading UbuntuMono Nerd Font..." "Progress"

        New-Item -Path $TEMP_DIR -ItemType Directory -Force | Out-Null
        $zipPath = Join-Path $TEMP_DIR "UbuntuMono.zip"

        Invoke-WebRequest -Uri $FONT_DOWNLOAD_URL -OutFile $zipPath -UseBasicParsing
        Expand-Archive -Path $zipPath -DestinationPath $TEMP_DIR -Force

        $ttfFiles = Get-ChildItem -Path $TEMP_DIR -Filter "*.ttf" -Recurse
        $shell = New-Object -ComObject Shell.Application
        $fontsFolder = $shell.Namespace(0x14)  # Special folder constant for Fonts

        foreach ($file in $ttfFiles) {
            $fontsFolder.CopyHere($file.FullName, 0x10)  # 0x10 = no UI
        }

        Remove-Item -Path $TEMP_DIR -Recurse -Force
        Add-Action "Installed UbuntuMono Nerd Font"
        Write-Status "Nerd Font installed successfully" "Success"
    } catch {
        Write-Log "Font install failed: $_" "ERROR"
        Write-Status "Failed to install Nerd Font" "Error"
        if (Test-Path $TEMP_DIR) { Remove-Item $TEMP_DIR -Recurse -Force }
    }
}

function Configure-WindowsTerminal {
    <#
    .DESCRIPTION
    Sets default font face in Windows Terminal to UbuntuMono Nerd Font.
    Modifies profiles.defaults for global effect.
    #>
    try {
        $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        if (-not (Test-Path $settingsPath)) {
            Write-Status "Windows Terminal not found — skipping" "Info"
            return
        }

        $json = Get-Content $settingsPath -Raw | ConvertFrom-Json

        if (-not $json.profiles.defaults) {
            $json.profiles | Add-Member -MemberType NoteProperty -Name defaults -Value ([PSCustomObject]@{})
        }

        $json.profiles.defaults | Add-Member -MemberType NoteProperty -Name font -Value @{ face = "UbuntuMono Nerd Font" } -Force

        $json | ConvertTo-Json -Depth 100 | Set-Content $settingsPath -Encoding UTF8

        Add-Action "Configured Windows Terminal default font"
        Write-Status "Windows Terminal configured" "Success"
    } catch {
        Write-Log "WT config error: $_" "ERROR"
        Write-Status "Failed to configure Windows Terminal" "Error"
    }
}

function Configure-PuTTY {
    <#
    .DESCRIPTION
    Modifies PuTTY Default Settings registry — critical for KeePass compatibility.
    You said: "since they use keepass the default profile is always loaded in putty"
    #>
    try {
        $regPath = "HKCU:\Software\SimonTatham\PuTTY\Sessions\Default%20Settings"
        New-Item -Path $regPath -Force | Out-Null

        Set-ItemProperty -Path $regPath -Name "Font" -Value "UbuntuMono Nerd Font" -Type String
        Set-ItemProperty -Path $regPath -Name "FontHeight" -Value 12 -Type DWord
        Set-ItemProperty -Path $regPath -Name "FontIsBold" -Value 0 -Type DWord
        Set-ItemProperty -Path $regPath -Name "UTF8" -Value 1 -Type DWord  # Ensure proper encoding

        Add-Action "Configured PuTTY Default Settings (KeePass compatible)"
        Write-Status "PuTTY Default Settings updated" "Success"
    } catch {
        Write-Log "PuTTY config error: $_" "ERROR"
        Write-Status "Failed to configure PuTTY" "Error"
    }
}

# ========================================================================================
# Section 8: Summary and Remote Guidance
# ========================================================================================

function Save-InstallationSummary {
    <#
    .DESCRIPTION
    Shows final summary and saves log + readable summary to Documents.
    You requested detailed output at the end.
    #>
    try {
        $summaryText = @"
DOTFILES WINDOWS SETUP — COMPLETE
============================================
Date:     $(Get-Date)
Backup:   $BACKUP_DIR\$BACKUP_TIMESTAMP

Actions performed:
$($script:ActionsPerformed | ForEach-Object { "  • $_" })

Next steps:
- Restart Windows Terminal and PuTTY/KeePass
- Connect to server — icons should now appear!
- Run the server installer when connected:
  bash -c "`$(curl -fsSL https://raw.githubusercontent.com/deey001/dotfiles/master/install.sh)"

Thank you!
"@

        Clear-Host
        Write-ColorText "════════════════════════════════════════" "Cyan"
        Write-ColorText "     INSTALLATION COMPLETE" "Green"
        Write-ColorText "════════════════════════════════════════" "Cyan"
        Write-Host $summaryText

        # Save full log
        $script:InstallationLog | Set-Content -Path $LOG_FILE

        # Save readable summary
        $summaryFile = "$env:USERPROFILE\Documents\dotfiles-windows-summary-$BACKUP_TIMESTAMP.txt"
        $summaryText | Set-Content -Path $summaryFile

        Write-ColorText "`nLog saved: $LOG_FILE" "Gray"
        Write-ColorText "Summary saved: $summaryFile" "Gray"
    } catch {
        Write-Status "Failed to save summary" "Warning"
    }
}

function Install-RemoteDotfiles {
    <#
    .DESCRIPTION
    Guides user to run the server installer.
    #>
    Clear-Host
    Write-ColorText "REMOTE SERVER SETUP" "Cyan"
    Write-Host "`nAfter closing this window, connect to your server and run:"
    Write-ColorText "`nbash -c \"\$(curl -fsSL https://raw.githubusercontent.com/deey001/dotfiles/master/install.sh)\"" "Yellow"
    Write-Host "`nThis will install your dotfiles with full Nerd Font icon support."

    $open = Read-Host "`nOpen Windows Terminal now? (y/n)"
    if ($open -match "^[Yy]") {
        Start-Process wt.exe
    }
}

# ========================================================================================
# Section 9: Menu and Main Logic
# ========================================================================================

function Show-Menu {
    Clear-Host
    Write-ColorText "╔══════════════════════════════════════════════════╗" "Cyan"
    Write-ColorText "║        DOTFILES WINDOWS SETUP TOOL               ║" "Cyan"
    Write-ColorText "║   Prepare your terminal for Nerd Font icons      ║" "Cyan"
    Write-ColorText "╚══════════════════════════════════════════════════╝" "Cyan"

    Write-Host ""
    Write-ColorText " [1] Install Nerd Fonts only" "Yellow"
    Write-ColorText " [2] Configure Windows Terminal only" "Yellow"
    Write-ColorText " [3] Configure PuTTY Default Settings (KeePass compatible)" "Yellow"
    Write-ColorText " [4] Full Local Setup (Fonts + Both Terminals)" "Yellow"
    Write-ColorText " [5] Guide: Install dotfiles on remote server" "Yellow"
    Write-ColorText " [6] Complete Workflow (Local → Remote)" "Yellow"
    Write-ColorText " [7] Reset / Remove Configuration (uses backup)" "Yellow"
    Write-ColorText " [8] Restore from Previous Backup" "Yellow"
    Write-ColorText " [0] Exit" "Red"
    Write-Host ""
    Write-Host "Enter your choice: " -NoNewline
}

function Main {
    # Require admin for font install
    if (-not (Test-AdminPrivileges)) {
        Write-Status "This installer requires Administrator privileges" "Error"
        Write-Status "Right-click PowerShell → Run as Administrator, then rerun the one-liner" "Warning"
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Always backup first
    Backup-Settings

    do {
        Show-Menu
        $choice = Read-Host

        switch ($choice) {
            "1" { Install-NerdFont }
            "2" { Configure-WindowsTerminal }
            "3" { Configure-PuTTY }
            "4" {
                Install-NerdFont
                Configure-WindowsTerminal
                Configure-PuTTY
                Write-Status "Full local setup complete!" "Success"
            }
            "5" { Install-RemoteDotfiles }
            "6" {
                Install-NerdFont
                Configure-WindowsTerminal
                Configure-PuTTY
                Install-RemoteDotfiles
            }
            "7" {
                $confirm = Read-Host "Reset all changes using latest backup? (y/n)"
                if ($confirm -match "^[Yy]") { Restore-Settings }
            }
            "8" { Restore-Settings }
            "0" { $exit = $true }
            default { Write-Status "Invalid selection" "Warning" }
        }

        if ($choice -ne "0" -and -not $exit) {
            Read-Host "`nPress Enter to continue..."
        }
    } while (-not $exit)

    Save-InstallationSummary
}

# ========================================================================================
# Script Entry Point
# ========================================================================================
Main