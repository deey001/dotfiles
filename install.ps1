<#
.SYNOPSIS
    Dotfiles Windows Local Setup — Installs Nerd Fonts and configures terminals for proper icon display
    One-liner: irm "https://raw.githubusercontent.com/deey001/dotfiles/master/install.ps1" | iex

.DESCRIPTION
    This script prepares Windows machines so that Nerd Font icons display correctly
    when colleagues connect (via Windows Terminal, PuTTY, or KeePass) to Linux servers running your dotfiles.

    Key Features:
    - [FIX] Enforces TLS 1.2 for GitHub connectivity
    - [FIX] Auto-Elevates to Administrator if run as standard user
    - Automatically upgrades PowerShell 5 → PowerShell 7 with no prompts
    - Installs UbuntuMono Nerd Font (System-wide)
    - Configures Windows Terminal and PuTTY **Default Settings** (critical for KeePass compatibility)
    - Creates timestamped backups before any changes
    - Chris Titus-style interactive menu with descriptions
    - Comprehensive logging and summary saved to Documents folder
    - Restore and reset options
    - Full idiot-proof status messages

    Philosophy: KISS — everything via one simple one-liner.
#>

# ========================================================================================
# Section 0: Critical Pre-flight Checks (TLS & Admin)
# ========================================================================================

# 1. Force TLS 1.2 (Fixes "Could not create SSL/TLS secure channel" on older Windows)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 2. Define the exact command used to run this script (for auto-elevation reliability)
$RepoParams = "irm 'https://raw.githubusercontent.com/deey001/dotfiles/master/install.ps1' | iex"

# 3. Helper Function: Check for Admin Privileges
function Test-AdminPrivileges {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 4. Auto-Elevate if not Admin
if (-not (Test-AdminPrivileges)) {
    Write-Host "█▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█" -ForegroundColor Red
    Write-Host "█  ADMINISTRATOR PRIVILEGES REQUIRED - AUTO-ELEVATING    █" -ForegroundColor Yellow
    Write-Host "█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█" -ForegroundColor Red
    Write-Host "`nPlease accept the UAC prompt to continue..." -ForegroundColor Gray
    
    # Download script to temp file to avoid quoting/parsing hell in Start-Process
    $TempScript = "$env:TEMP\DotfilesSetup.ps1"
    try {
        Write-Host "Preparing setup file..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/deey001/dotfiles/master/install.ps1" -OutFile $TempScript -UseBasicParsing
        
        # Launch the temp file as Admin
        Start-Process powershell -Verb RunAs -ArgumentList "-NoExit", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$TempScript`""
    } catch {
        Write-Host "`n[ERROR] Failed to prepare auto-elevation: $_" -ForegroundColor Red
        Write-Host "Please try running PowerShell as Administrator manually." -ForegroundColor Yellow
    }
    
    # Pause so user sees what happened
    Read-Host "`n[INFO] Auto-elevation attempted. Check the new window.`nPress Enter to close this window..."
    exit
}

# ========================================================================================
# Section 1: PowerShell Version Check and Auto-Upgrade
# ========================================================================================
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "Detected PowerShell $($PSVersionTable.PSVersion.Major). Installing PowerShell 7 automatically..." -ForegroundColor Yellow

    # Attempt 1: Winget
    Write-Host "Attempting install via Winget..." -ForegroundColor Cyan
    $result = winget install --id Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements 2>&1
    
    # Check if Winget worked
    $pwsh7Paths = @(
        "$env:ProgramFiles\PowerShell\7\pwsh.exe",
        "C:\Program Files\PowerShell\7\pwsh.exe"
    )
    $pwsh7Path = $pwsh7Paths | Where-Object { Test-Path $_ } | Select-Object -First 1

    # Attempt 2: Official Install Script (Fallback)
    if (-not $pwsh7Path) {
        Write-Host "Winget failed or not found. Output:`n$result" -ForegroundColor Yellow
        Write-Host "Attempting fallback via official MSI script..." -ForegroundColor Cyan
        
        try {
            # Use the official Microsoft install script
            $InstallScript = "https://aka.ms/install-powershell.ps1"
            Invoke-Expression "& { $(Invoke-RestMethod $InstallScript) } -UseMSI -Quiet"
            
            # Wait for MSI to finish (simple sleep as the script usually returns after launch)
            Write-Host "Waiting for installer..." -ForegroundColor Cyan
            Start-Sleep -Seconds 30
            
            # Recheck path
            $pwsh7Path = $pwsh7Paths | Where-Object { Test-Path $_ } | Select-Object -First 1
        } catch {
            Write-Host "Fallback failed: $_" -ForegroundColor Red
        }
    }

    if ($pwsh7Path) {
        Write-Host "PowerShell 7 installed. Relaunching in new elevated window..." -ForegroundColor Green

        # Use same temp file strategy for reliability
        $TempScript = "$env:TEMP\DotfilesSetup.ps1"
        if (-not (Test-Path $TempScript)) {
            Invoke-WebRequest -Uri "https://raw.githubusercontent.com/deey001/dotfiles/master/install.ps1" -OutFile $TempScript -UseBasicParsing
        }

        Start-Process -FilePath $pwsh7Path -Verb RunAs -ArgumentList "-NoExit", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$TempScript`""

        Start-Sleep -Seconds 3
        exit 0
    } else {
        Write-Host "Failed to install PowerShell 7." -ForegroundColor Red
        Write-Host "Error details (Winget): $result" -ForegroundColor Gray
        Write-Host "Please install manually from: https://github.com/PowerShell/PowerShell/releases" -ForegroundColor Yellow
        Read-Host "Press Enter to exit..."
        exit 1
    }
}

# ========================================================================================
# Section 2: Enable ANSI Color Support
# ========================================================================================
try {
    [System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $script:UseColors = $true
} catch {
    $script:UseColors = $false
}

# ========================================================================================
# Section 3: Configuration Variables
# ========================================================================================
$FONT_DOWNLOAD_URL = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/UbuntuMono.zip"
$TEMP_DIR = "$env:TEMP\nerd-fonts-install"
$BACKUP_DIR = "$env:USERPROFILE\.dotfiles-backup"
$BACKUP_TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"
$LOG_FILE = "$env:USERPROFILE\Documents\dotfiles-install-log-$BACKUP_TIMESTAMP.txt"

$script:InstallationLog = @()
$script:ActionsPerformed = @()

# ========================================================================================
# Section 4: ANSI Color Definitions
# ========================================================================================
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
# Section 5: Helper Functions
# ========================================================================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    $script:InstallationLog += $logEntry
}

function Add-Action {
    param([string]$Action)
    $script:ActionsPerformed += $Action
    Write-Log $Action "ACTION"
}

function Write-ColorText {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [Parameter(Mandatory=$true)][string]$Color
    )
    Write-Log $Message "OUTPUT"

    if ($script:UseColors) {
        $colorCode = $colors[$Color]
        if (-not $colorCode) { $colorCode = "" }
        Write-Host "$colorCode$Message$($colors.Reset)"
    } else {
        $fallback = @{ Red="Red"; Green="Green"; Yellow="Yellow"; Cyan="Cyan"; Magenta="Magenta"; Gray="Gray"; White="White" }
        if ($fallback.ContainsKey($Color)) {
            $fg = $fallback[$Color]
        } else {
            $fg = "White"
        }
        Write-Host $Message -ForegroundColor $fg
    }
}

function Write-Status {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [ValidateSet("Success","Error","Progress","Warning","Info")][string]$StatusType
    )
    $statusMap = @{
        Success  = @{ Icon = "✓"; Color = "Green" }
        Error    = @{ Icon = "✗"; Color = "Red" }
        Progress = @{ Icon = "→"; Color = "Cyan" }
        Warning  = @{ Icon = "!"; Color = "Yellow" }
        Info     = @{ Icon = "i"; Color = "Gray" }
    }
    if ($statusMap.ContainsKey($StatusType)) {
        $status = $statusMap[$StatusType]
    } else {
        $status = $statusMap["Info"]
    }
    $formatted = "[$($status.Icon)] $Message"
    Write-ColorText $formatted $status.Color
}

function Test-FontInstalled {
    param([string]$FontName = "UbuntuMono Nerd Font")
    # Check Registry for standard install
    $fontRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
    if (Test-Path $fontRegPath) {
        $installed = Get-ItemProperty -Path $fontRegPath
        if (($installed.PSObject.Properties | Where-Object { $_.Value -like "*$FontName*" }).Count -gt 0) {
            return $true
        }
    }
    
    # Check User local font path (common with manual installs)
    $userFontPath = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    if (Test-Path $userFontPath) {
         if (Get-ChildItem -Path $userFontPath -Filter "*UbuntuMonoNerdFont*" -ErrorAction SilentlyContinue) {
             return $true
         }
    }

    return $false
}

# ========================================================================================
# Section 6: Backup and Restore
# ========================================================================================

function Backup-Settings {
    try {
        $timestampDir = Join-Path $BACKUP_DIR $BACKUP_TIMESTAMP
        New-Item -Path $timestampDir -ItemType Directory -Force | Out-Null

        # PuTTY Default Settings
        $puttyRegPath = "HKCU\Software\SimonTatham\PuTTY\Sessions\Default%20Settings"
        $puttyBackup = Join-Path $timestampDir "putty-default-settings.reg"
        if (Test-Path "HKCU:\Software\SimonTatham\PuTTY\Sessions\Default%20Settings") {
            reg export "$puttyRegPath" $puttyBackup /y | Out-Null
            Write-Log "Backed up PuTTY Default Settings"
        }

        # Windows Terminal
        $wtPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        if (Test-Path $wtPath) {
            Copy-Item $wtPath (Join-Path $timestampDir "windows-terminal-settings.json")
            Write-Log "Backed up Windows Terminal settings"
        }

        # Metadata
        $metadata = @{ Timestamp = $BACKUP_TIMESTAMP; Actions = $script:ActionsPerformed }
        $metadata | ConvertTo-Json | Set-Content (Join-Path $timestampDir "metadata.json")

        Add-Action "Backup created at $timestampDir"
        Write-Status "Backup created successfully" "Success"
    } catch {
        Write-Log "Backup failed: $_" "ERROR"
        Write-Status "Backup failed" "Error"
    }
}

function Restore-Settings {
    try {
        $backups = Get-ChildItem -Path $BACKUP_DIR -Directory | Sort-Object Name -Descending
        if ($backups.Count -eq 0) {
            Write-Status "No backups found" "Warning"
            return
        }

        Write-ColorText "Available backups:" "Cyan"
        for ($i = 0; $i -lt $backups.Count; $i++) {
            Write-Host "$($i+1). $($backups[$i].Name)"
        }

        $selection = Read-Host "Select backup number (0 to cancel)"
        if ($selection -eq "0" -or -not ($selection -match '^\d+$') -or $selection -gt $backups.Count) {
            Write-Status "Restore cancelled" "Info"
            return
        }

        $selected = $backups[$selection - 1].FullName

        # Restore PuTTY
        $puttyFile = Join-Path $selected "putty-default-settings.reg"
        if (Test-Path $puttyFile) {
            reg import $puttyFile | Out-Null
            Write-Log "Restored PuTTY Default Settings"
        }

        # Restore Windows Terminal
        $wtFile = Join-Path $selected "windows-terminal-settings.json"
        $wtTarget = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        if (Test-Path $wtFile) {
            Copy-Item $wtFile $wtTarget -Force
            Write-Log "Restored Windows Terminal settings"
        }

        Add-Action "Restored settings from $selected"
        Write-Status "Restore completed" "Success"
    } catch {
        Write-Log "Restore failed: $_" "ERROR"
        Write-Status "Restore failed" "Error"
    }
}

# ========================================================================================
# Section 7: Installation Functions
# ========================================================================================

function Install-NerdFont {
    try {
        Write-Host "Downloading UbuntuMono Nerd Font..." -ForegroundColor Cyan
        
        New-Item -Path $TEMP_DIR -ItemType Directory -Force | Out-Null
        $zipFile = Join-Path $TEMP_DIR "UbuntuMono.zip"

        Invoke-WebRequest -Uri $FONT_DOWNLOAD_URL -OutFile $zipFile
        Expand-Archive -Path $zipFile -DestinationPath $TEMP_DIR -Force

        $fontFiles = Get-ChildItem -Path $TEMP_DIR -Filter "*.ttf" -Recurse
        
        # Method 1: Shell.Application (Silent and Standard)
        $shell = New-Object -ComObject Shell.Application
        $fontsFolder = $shell.Namespace(0x14)  # Special Fonts folder
        
        foreach ($font in $fontFiles) {
            Write-Host "Installing: $($font.Name)" -ForegroundColor Cyan
            $fontsFolder.CopyHere($font.FullName, 0x10)  # 0x10 = silent
            
            # Method 2: Manual Registry Fallback (System-Wide)
            # Sometimes CopyHere fails silently or puts it in a user path that Admin apps don't see.
            # We add it to HKLM just to be robust.
            try {
                $destPath = "$env:SystemRoot\Fonts\$($font.Name)"
                if (-not (Test-Path $destPath)) {
                    Copy-Item -Path $font.FullName -Destination $destPath -Force
                    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -Name "$($font.Name) (TrueType)" -Value "$($font.Name)" -PropertyType String -Force | Out-Null
                }
            } catch {
                Write-Log "Registry method failed (ignoring if CopyHere worked): $_" "WARNING"
            }
        }

        Remove-Item -Path $TEMP_DIR -Recurse -Force
        Add-Action "Installed UbuntuMono Nerd Font"
        Write-Status "Nerd Font installed successfully" "Success"
    } catch {
        Write-Status "Font installation failed" "Error"
        Write-Log "Font install error: $_" "ERROR"
        if (Test-Path $TEMP_DIR) { Remove-Item $TEMP_DIR -Recurse -Force }
    }
}

function Configure-WindowsTerminal {
    try {
        $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        if (-not (Test-Path $settingsPath)) {
            Write-Status "Windows Terminal not detected" "Warning"
            Write-Host "Is Windows Terminal installed?" -ForegroundColor Yellow
            return
        }

        $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json

        if (-not $settings.profiles.defaults) {
            $settings.profiles | Add-Member -MemberType NoteProperty -Name defaults -Value ([PSCustomObject]@{})
        }
        $settings.profiles.defaults | Add-Member -MemberType NoteProperty -Name font -Value @{ face = "UbuntuMono Nerd Font" } -Force

        # Set depth to 100 to avoid object truncation in large configs
        $settings | ConvertTo-Json -Depth 100 | Set-Content $settingsPath -Encoding UTF8

        Add-Action "Configured Windows Terminal font face"
        Write-Status "Windows Terminal configured" "Success"
    } catch {
        Write-Status "Windows Terminal config failed" "Error"
        Write-Log "WT config error: $_" "ERROR"
    }
}

function Configure-PuTTY {
    try {
        $regPath = "HKCU:\Software\SimonTatham\PuTTY\Sessions\Default%20Settings"
        
        # Ensure Default Settings key exists
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }

        Set-ItemProperty -Path $regPath -Name "Font" -Value "UbuntuMono Nerd Font" -Type String
        Set-ItemProperty -Path $regPath -Name "FontHeight" -Value 12 -Type DWord
        Set-ItemProperty -Path $regPath -Name "FontIsBold" -Value 0 -Type DWord
        
        # Extra: Ensure ANSI colors are enabled in PuTTY if possible (handled by default usually, but good to check)
        # Set-ItemProperty -Path $regPath -Name "UseSystemColours" -Value 0 -Type DWord

        Add-Action "Configured PuTTY Default Settings (KeePass compatible)"
        Write-Status "PuTTY Default Settings configured" "Success"
    } catch {
        Write-Status "PuTTY configuration failed" "Error"
        Write-Log "PuTTY config error: $_" "ERROR"
    }
}

# ========================================================================================
# Section 8: Summary and Remote Guidance
# ========================================================================================

function Save-InstallationSummary {
    try {
        $summary = @"
DOTFILES WINDOWS SETUP — INSTALLATION SUMMARY
============================================
Run: $(Get-Date)
PowerShell: $($PSVersionTable.PSVersion)
Backup: $BACKUP_DIR\$BACKUP_TIMESTAMP

ACTIONS PERFORMED:
$($script:ActionsPerformed -join "`n" -replace '^', '  • ')

NEXT STEPS:
- Restart terminals for changes to take effect
- Connect via KeePass/PuTTY/Windows Terminal — icons should now appear!
"@

        Clear-Host
        Write-ColorText "══════════════════════════════════════════════" "Cyan"
        Write-ColorText "          INSTALLATION COMPLETE" "Green"
        Write-ColorText "══════════════════════════════════════════════" "Cyan"
        Write-Host $summary
        Write-Host ""
        
        # Output log locations
        $script:InstallationLog | Set-Content $LOG_FILE
        $summary | Set-Content "$env:USERPROFILE\Documents\dotfiles-summary-$BACKUP_TIMESTAMP.txt"

        Write-ColorText "Log Saved: $LOG_FILE" "Gray"
        Write-ColorText "Summary Saved: Documents\dotfiles-summary-$BACKUP_TIMESTAMP.txt" "Gray"
    } catch {
        Write-Status "Failed to save summary" "Warning"
    }
}

function Install-RemoteDotfiles {
    Write-ColorText "`nREMOTE SERVER SETUP" "Cyan"
    Write-Host "Connect to your server, then run:"
    Write-ColorText "bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/deey001/dotfiles/master/install.sh)\"" "Yellow"
    Write-Host "`nThis will install your dotfiles on the server."

    $launch = Read-Host "`nLaunch Windows Terminal now? (y/n)"
    if ($launch -match "^[Yy]") {
        Start-Process wt.exe
    }
}

# ========================================================================================
# Section 9: Menu and Main Loop
# ========================================================================================

function Show-Menu {
    Clear-Host
    Write-ColorText "╔══════════════════════════════════════════════════╗" "Cyan"
    Write-ColorText "║          DOTFILES WINDOWS SETUP TOOL             ║" "Cyan"
    Write-ColorText "║      Nerd Fonts + Terminal Configuration         ║" "Cyan"
    Write-ColorText "╚══════════════════════════════════════════════════╝" "Cyan"
    Write-Host ""
    Write-ColorText " [1] Install Nerd Fonts only" "Yellow"
    Write-ColorText " [2] Configure Windows Terminal only" "Yellow"
    Write-ColorText " [3] Configure PuTTY Default Settings (KeePass!)" "Yellow"
    Write-ColorText " [4] Full Local Setup (Recommended)" "Green"
    Write-Host "     (Installs Fonts + Configures WT & PuTTY)" -ForegroundColor Gray
    Write-Host ""
    Write-ColorText " [5] Install dotfiles on remote server (guide)" "Yellow"
    Write-ColorText " [6] Complete Workflow (Local + Remote)" "Yellow"
    Write-ColorText " [7] Reset / Remove Configuration" "Yellow"
    Write-ColorText " [8] Restore from Backup" "Yellow"
    Write-ColorText " [0] Exit" "Red"
    Write-Host ""
    Write-Host "Enter choice: " -NoNewline
}

function Main {
    try {
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
                }
                "5" { Install-RemoteDotfiles }
                "6" {
                    Install-NerdFont
                    Configure-WindowsTerminal
                    Configure-PuTTY
                    Install-RemoteDotfiles
                }
                "7" {
                    $confirm = Read-Host "Reset all settings? This will restore from latest backup (y/n)"
                    if ($confirm -match "^[Yy]") { Restore-Settings }
                }
                "8" { Restore-Settings }
                "0" { break }
                default { Write-Status "Invalid choice" "Warning" }
            }

            if ($choice -ne "0") {
                Read-Host "`nPress Enter to continue"
            }
        } while ($choice -ne "0")

        Save-InstallationSummary
    } catch {
        Write-Error "An unexpected error occurred: $_"
        Read-Host "Press Enter to exit"
    }
}

Main