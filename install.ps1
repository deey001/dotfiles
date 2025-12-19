# ==============================================================================
# DOTFILES WINDOWS INSTALLER - INTERACTIVE MENU
# ==============================================================================
# PURPOSE:
#   This script installs Nerd Fonts on Windows and configures terminal emulators
#   (Windows Terminal and PuTTY) to use them. It provides an interactive menu
#   similar to Chris Titus's Windows Utility.
#
# ONE-LINER INSTALL:
#   irm "https://raw.githubusercontent.com/deey001/dotfiles/master/install.ps1" | iex
#
#   Breakdown of one-liner:
#   - irm = Invoke-RestMethod (downloads the script from GitHub)
#   - | = pipe operator (sends downloaded script to next command)
#   - iex = Invoke-Expression (executes the downloaded script)
#
# WHAT THIS SCRIPT DOES:
#   1. Checks PowerShell version (auto-upgrades to v7 if needed)
#   2. Detects installed components (fonts, terminals, admin rights)
#   3. Shows interactive menu with 8 options
#   4. Installs fonts and configures terminals per user selection
#   5. Creates automatic backups before any changes
#   6. Logs all actions to Documents folder
#   7. Shows detailed summary at exit
#
# SPECIAL FEATURES:
#   - KeePass Compatible: Modifies PuTTY "Default Settings" so ALL connections
#     from KeePass automatically inherit the Nerd Font configuration
#   - Idiot-Proof: Automatic backups, admin checks, detailed logging
#   - Rollback Support: Can restore previous configurations from backup
# ==============================================================================

# ==============================================================================
# SECTION 1: POWERSHELL VERSION CHECK AND AUTO-UPGRADE
# ==============================================================================
# WHY THIS IS NEEDED:
#   PowerShell 5 (built into Windows) doesn't support ANSI color codes properly.
#   PowerShell 7 (separate download) has full ANSI support for colors and icons.
#
# WHAT THIS DOES:
#   - Checks if running PowerShell version is less than 7
#   - If yes: Automatically installs PowerShell 7 via winget (no user prompt)
#   - After install: Exits and tells user to restart PowerShell
#   - On failure: Shows manual installation instructions
# ==============================================================================
if ($PSVersionTable.PSVersion.Major -lt 7) {
    # $PSVersionTable = Built-in PowerShell variable containing version info
    # .PSVersion.Major = Gets major version number (5, 7, etc.)
    # -lt = "less than" comparison operator
    # Print blank line for spacing
    Write-Host ""

    # Print header banner to notify user of auto-upgrade
    # -ForegroundColor Yellow = Makes text yellow to grab attention
    Write-Host "================================================================================" -ForegroundColor Yellow
    Write-Host "  PowerShell 7 Required - Auto-Upgrading..." -ForegroundColor Yellow
    Write-Host "================================================================================" -ForegroundColor Yellow
    Write-Host ""

    # Show current PowerShell version in red (bad/outdated)
    # $(...) = Subexpression operator - evaluates code inside and inserts result
    Write-Host "Current version: PowerShell $($PSVersionTable.PSVersion.Major)" -ForegroundColor Red

    # Show target version in green (good/desired)
    Write-Host "Installing:      PowerShell 7+" -ForegroundColor Green
    Write-Host ""

    # Set expectations for installation time
    Write-Host "This will take about 1-2 minutes..." -ForegroundColor Cyan
    Write-Host ""

    try {
        # TRY BLOCK: Attempt automatic installation, catch errors if it fails

        # Check if winget command exists on this system
        # Get-Command = Searches for available commands/programs
        # -ErrorAction SilentlyContinue = Don't show error if winget not found, just return $null
        $wingetAvailable = Get-Command winget -ErrorAction SilentlyContinue

        if ($wingetAvailable) {
            # WINGET IS AVAILABLE - Proceed with automatic installation

            Write-Host "[→] Installing PowerShell 7 via winget..." -ForegroundColor Cyan

            # Execute winget command to install PowerShell 7
            # winget = Windows Package Manager (like apt for Windows)
            # install Microsoft.PowerShell = Official PowerShell 7 package ID
            # --silent = No user prompts during installation
            # --accept-package-agreements = Auto-accept license agreements
            # --accept-source-agreements = Auto-accept source (repository) agreements
            # 2>&1 = Redirect stderr (error stream) to stdout (standard output) so we capture all output
            $result = winget install Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements 2>&1

            # Check if installation succeeded
            # $LASTEXITCODE = Automatic variable containing exit code of last external command (0 = success)
            # -match = Regular expression match operator
            if ($LASTEXITCODE -eq 0 -or $result -match "successfully installed") {
                # INSTALLATION SUCCESSFUL
                Write-Host "[✓] PowerShell 7 installed successfully!" -ForegroundColor Green
                Write-Host ""
                Write-Host "================================================================================" -ForegroundColor Yellow
                Write-Host "  Auto-Launching PowerShell 7..." -ForegroundColor Yellow
                Write-Host "================================================================================" -ForegroundColor Yellow
                Write-Host ""

                # AUTO-LAUNCH POWERSHELL 7 AS ADMIN AND CONTINUE INSTALLATION
                # PowerShell 7 is installed to: C:\Program Files\PowerShell\7\pwsh.exe

                try {
                    # Find PowerShell 7 executable
                    # Common install locations for PowerShell 7
                    $pwsh7Paths = @(
                        "C:\Program Files\PowerShell\7\pwsh.exe",
                        "$env:ProgramFiles\PowerShell\7\pwsh.exe"
                    )

                    $pwsh7Path = $null
                    foreach ($path in $pwsh7Paths) {
                        if (Test-Path $path) {
                            $pwsh7Path = $path
                            break
                        }
                    }

                    if ($pwsh7Path) {
                        Write-Host "[→] Launching PowerShell 7 as Administrator..." -ForegroundColor Cyan
                        Write-Host "[i] The installer will continue automatically in the new window" -ForegroundColor Blue
                        Write-Host ""

                        # Build command to download and run the installer in PowerShell 7
                        # -NoProfile = Don't load user profile (faster startup)
                        # -ExecutionPolicy Bypass = Allow script execution
                        # -Command = Execute the following command
                        $installCommand = "irm 'https://raw.githubusercontent.com/deey001/dotfiles/master/install.ps1' | iex"

                        # Launch PowerShell 7 as Administrator with the install command
                        # Start-Process = Starts a new process (program)
                        # -FilePath = Path to pwsh.exe (PowerShell 7)
                        # -Verb RunAs = Run as Administrator (triggers UAC prompt)
                        # -ArgumentList = Commands to pass to pwsh.exe
                        Start-Process -FilePath $pwsh7Path -Verb RunAs -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $installCommand

                        Write-Host "[✓] PowerShell 7 launched!" -ForegroundColor Green
                        Write-Host "[i] This window will now close" -ForegroundColor Gray
                        Write-Host "[i] Continue installation in the new PowerShell 7 window" -ForegroundColor Gray
                        Write-Host ""

                        # Wait 3 seconds so user can read the message
                        Start-Sleep -Seconds 3
                        exit 0
                    } else {
                        # PowerShell 7 was installed but we can't find it
                        # Fall back to manual instructions
                        throw "PowerShell 7 executable not found in expected locations"
                    }
                } catch {
                    # AUTO-LAUNCH FAILED - Show manual instructions
                    Write-Host "[!] Could not auto-launch PowerShell 7: $_" -ForegroundColor Yellow
                    Write-Host ""
                    Write-Host "Manual steps:" -ForegroundColor Cyan
                    Write-Host "  1. Close this window" -ForegroundColor Gray
                    Write-Host "  2. Search for 'PowerShell 7' in Start Menu" -ForegroundColor Gray
                    Write-Host "  3. Right-click → Run as Administrator" -ForegroundColor Gray
                    Write-Host "  4. Run: irm 'https://raw.githubusercontent.com/deey001/dotfiles/master/install.ps1' | iex" -ForegroundColor White
                    Write-Host ""
                    Write-Host "Press any key to exit..." -ForegroundColor Gray
                    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                    exit 0
                }
            } else {
                throw "Installation failed or was skipped"
            }
        } else {
            throw "winget not available"
        }

    } catch {
        Write-Host "[!] Automatic installation failed: $_" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Manual installation required:" -ForegroundColor Cyan
        Write-Host "  1. Visit: https://aka.ms/powershell" -ForegroundColor Gray
        Write-Host "  2. Download and install PowerShell 7" -ForegroundColor Gray
        Write-Host "  3. Restart your terminal" -ForegroundColor Gray
        Write-Host "  4. Run this installer again" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Installation cancelled." -ForegroundColor Red
        Write-Host ""
        exit 1
    }
}

# ==============================================================================
# SECTION 2: ENABLE ANSI COLOR SUPPORT
# ==============================================================================
# WHY THIS IS NEEDED:
#   ANSI escape codes are special character sequences that produce colors and
#   formatting in terminals. Example: `e[91m = red text, `e[0m = reset
#
# WHAT THIS DOES:
#   - Sets console encoding to UTF-8 (required for Unicode characters like ✓ ✗ →)
#   - Sets $script:UseColors flag to true if ANSI is supported
#   - If encoding fails, falls back to $script:UseColors = false
#   - This flag is checked by Write-ColorText and Write-Status functions
# ==============================================================================
try {
    # TRY BLOCK: Attempt to enable UTF-8 encoding for console output

    # Set console output encoding to UTF-8
    # [System.Console]::OutputEncoding = Accesses the .NET Console class
    # [System.Text.Encoding]::UTF8 = Gets UTF-8 encoding object
    # $null = Suppresses output (assignment returns value, we don't need to see it)
    $null = [System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8

    # Set script-level variable to indicate ANSI colors are supported
    # $script:UseColors = Creates/modifies variable at script scope (accessible by all functions)
    # PowerShell 7 supports ANSI, so this should succeed
    $script:UseColors = $true

} catch {
    # CATCH BLOCK: If UTF-8 encoding fails (rare), disable color support
    # This ensures script doesn't crash if console doesn't support UTF-8
    $script:UseColors = $false
}

# ==============================================================================
# SECTION 3: ASCII ART BANNER
# ==============================================================================
# This ASCII art banner displays "DOTFILES" in large block letters
# Uses box-drawing characters (╔ ═ ╗ ║ ╚ ╝) to create a border
# The @ symbol creates a "here-string" which preserves all formatting/spacing
# ==============================================================================
$banner = @"
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║   ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗             ║
║   ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝             ║
║   ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗             ║
║   ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║             ║
║   ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║             ║
║   ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝             ║
║                                                                              ║
║                   Windows Setup Utility v1.0                                 ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
"@
# @" = End marker for here-string

# ==============================================================================
# SECTION 4: CONFIGURATION VARIABLES
# ==============================================================================
# These variables define URLs, paths, and settings used throughout the script
# ==============================================================================

# Font name to install (used for detection and messaging)
$FONT_NAME = "UbuntuMono Nerd Font"

# Direct download URL for the latest UbuntuMono Nerd Font ZIP file
# https://github.com/ryanoasis/nerd-fonts = Nerd Fonts repository
# /releases/latest/download/ = GitHub's latest release download URL
# UbuntuMono.zip = The specific font package
$FONT_DOWNLOAD_URL = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/UbuntuMono.zip"

# Git repository URL for the dotfiles (used in remote server installation)
$REPO_URL = "https://github.com/deey001/dotfiles.git"

# Temporary directory for downloading and extracting fonts
# $env:TEMP = Windows TEMP folder (typically C:\Users\{username}\AppData\Local\Temp)
# Example result: C:\Users\Danny\AppData\Local\Temp\nerd-fonts-install
$TEMP_DIR = "$env:TEMP\nerd-fonts-install"

# Directory where backups of terminal configurations are stored
# $env:USERPROFILE = User's home directory (C:\Users\{username})
# Example result: C:\Users\Danny\.dotfiles-backup
$BACKUP_DIR = "$env:USERPROFILE\.dotfiles-backup"

# Timestamp for unique backup folder and log file names
# Get-Date -Format "yyyyMMdd_HHmmss" = Current date/time formatted as: 20250115_143022
$BACKUP_TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"

# Path to installation log file saved in user's Documents folder
# Example result: C:\Users\Danny\Documents\dotfiles-install-log-20250115_143022.txt
$LOG_FILE = "$env:USERPROFILE\Documents\dotfiles-install-log-$BACKUP_TIMESTAMP.txt"

# Array to store all log entries (timestamped messages)
# @() = Empty array literal
# $script: scope = Variable accessible by all functions in this script
$script:InstallationLog = @()

# Array to store high-level actions performed (for summary)
# Example contents: "Installed UbuntuMono Nerd Font", "Configured PuTTY"
$script:ActionsPerformed = @()

# ==============================================================================
# SECTION 5: ANSI COLOR CODE DEFINITIONS
# ==============================================================================
# ANSI escape codes for terminal colors
# `e = Escape character in PowerShell (equivalent to \e or \033 in other languages)
# [91m = ANSI code for bright red, [0m = reset to default color
# These codes work in PowerShell 7 and modern terminals that support ANSI
# ==============================================================================
$colors = @{
    # @{} = Hash table (dictionary/map) literal
    Reset = "`e[0m"      # Reset all formatting to default
    Bold = "`e[1m"       # Bold/bright text
    Red = "`e[91m"       # Bright red foreground
    Green = "`e[92m"     # Bright green foreground
    Yellow = "`e[93m"    # Bright yellow foreground
    Blue = "`e[94m"      # Bright blue foreground
    Magenta = "`e[95m"   # Bright magenta foreground
    Cyan = "`e[96m"      # Bright cyan foreground
    White = "`e[97m"     # Bright white foreground
    Gray = "`e[90m"      # Dark gray foreground
}

# ==============================================================================
# SECTION 6: HELPER FUNCTIONS
# ==============================================================================
# These functions are used throughout the script to provide logging, colored
# output, and action tracking functionality
# ==============================================================================

# ------------------------------------------------------------------------------
# FUNCTION: Write-Log
# PURPOSE: Adds a timestamped entry to the installation log
# PARAMETERS:
#   $Message = The log message text
#   $Level = Log level (INFO, WARNING, ERROR, ACTION, etc.)
# EXAMPLE OUTPUT: "[2025-01-15 14:30:22] [INFO] Starting installation..."
# ------------------------------------------------------------------------------
function Write-Log {
    param(
        # [string] = Parameter type constraint (ensures value is a string)
        [string]$Message,
        # = "INFO" = Default value if not provided
        [string]$Level = "INFO"
    )

    # Get current timestamp formatted as: 2025-01-15 14:30:22
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Build log entry string with timestamp and level
    # Example: "[2025-01-15 14:30:22] [INFO] Font installation started"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Add log entry to the script-level array
    # += operator appends to array
    $script:InstallationLog += $logEntry
}

# ------------------------------------------------------------------------------
# FUNCTION: Add-Action
# PURPOSE: Records a high-level action and logs it
# PARAMETERS:
#   $Action = Description of action performed
# EXAMPLE USAGE: Add-Action "Installed UbuntuMono Nerd Font (4 files)"
# RESULT: Adds to both $ActionsPerformed array and installation log
# ------------------------------------------------------------------------------
function Add-Action {
    param(
        [string]$Action
    )

    # Add action to the actions array (used in summary)
    $script:ActionsPerformed += $Action

    # Also log the action with ACTION level
    Write-Log $Action "ACTION"
}

function Write-ColorText {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    if ($script:UseColors) {
        Write-Host "$($colors[$Color])$Text$($colors.Reset)"
    } else {
        # Fallback to Write-Host -ForegroundColor for terminals without ANSI support
        $fgColor = switch ($Color) {
            "Red"     { "Red" }
            "Green"   { "Green" }
            "Yellow"  { "Yellow" }
            "Blue"    { "Blue" }
            "Magenta" { "Magenta" }
            "Cyan"    { "Cyan" }
            "Gray"    { "Gray" }
            default   { "White" }
        }
        Write-Host $Text -ForegroundColor $fgColor
    }
}

function Write-Status {
    param(
        [string]$Status,
        [string]$Message
    )

    # Log all status messages
    Write-Log $Message $Status.ToUpper()

    if ($script:UseColors) {
        switch ($Status) {
            "info"    { Write-Host "$($colors.Blue)[i]$($colors.Reset) $Message" }
            "success" { Write-Host "$($colors.Green)[✓]$($colors.Reset) $Message" }
            "warning" { Write-Host "$($colors.Yellow)[!]$($colors.Reset) $Message" }
            "error"   { Write-Host "$($colors.Red)[✗]$($colors.Reset) $Message" }
            "working" { Write-Host "$($colors.Cyan)[→]$($colors.Reset) $Message" }
        }
    } else {
        # Fallback for terminals without ANSI support
        switch ($Status) {
            "info"    { Write-Host "[i] $Message" -ForegroundColor Blue }
            "success" { Write-Host "[OK] $Message" -ForegroundColor Green }
            "warning" { Write-Host "[!] $Message" -ForegroundColor Yellow }
            "error"   { Write-Host "[X] $Message" -ForegroundColor Red }
            "working" { Write-Host "[>] $Message" -ForegroundColor Cyan }
        }
    }
}

function Test-AdminPrivileges {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-FontInstalled {
    $fontInstalled = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -ErrorAction SilentlyContinue |
        Select-String -Pattern "UbuntuMono" -Quiet
    return $fontInstalled
}

function Test-WindowsTerminalInstalled {
    return (Get-Command wt.exe -ErrorAction SilentlyContinue) -ne $null
}

function Test-PuTTYInstalled {
    return (Get-Command putty.exe -ErrorAction SilentlyContinue) -ne $null
}

function Get-ComponentStatus {
    return @{
        FontInstalled = Test-FontInstalled
        WindowsTerminal = Test-WindowsTerminalInstalled
        PuTTY = Test-PuTTYInstalled
        IsAdmin = Test-AdminPrivileges
    }
}

function Backup-Settings {
    Write-Host ""
    Write-ColorText "═══ Backing Up Current Settings ═══" "Cyan"
    Write-Host ""

    $backupPath = "$BACKUP_DIR\backup_$BACKUP_TIMESTAMP"

    try {
        # Create backup directory
        if (-not (Test-Path $BACKUP_DIR)) {
            New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null
        }
        New-Item -ItemType Directory -Path $backupPath -Force | Out-Null

        Write-Status "working" "Creating backup at: $backupPath"

        # Backup Windows Terminal settings
        $wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        if (Test-Path $wtSettingsPath) {
            Copy-Item -Path $wtSettingsPath -Destination "$backupPath\wt_settings.json" -Force
            Write-Status "success" "Windows Terminal settings backed up"
        }

        # Backup PuTTY Default Settings (export registry)
        $puttyRegPath = "HKCU:\Software\SimonTatham\PuTTY\Sessions\Default%20Settings"
        if (Test-Path $puttyRegPath) {
            $regBackup = "$backupPath\putty_default_settings.reg"
            reg export "HKCU\Software\SimonTatham\PuTTY\Sessions\Default%20Settings" $regBackup /y | Out-Null
            Write-Status "success" "PuTTY Default Settings backed up"
        }

        # Save backup metadata
        $metadata = @{
            Timestamp = $BACKUP_TIMESTAMP
            Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            FontInstalled = Test-FontInstalled
            WindowsTerminalConfigured = (Test-Path $wtSettingsPath)
            PuTTYConfigured = (Test-Path $puttyRegPath)
        }
        $metadata | ConvertTo-Json | Set-Content "$backupPath\metadata.json"

        Write-Host ""
        Write-Status "success" "Backup completed: $backupPath"
        return $backupPath

    } catch {
        Write-Status "error" "Backup failed: $_"
        return $null
    }
}

function Restore-Settings {
    Write-Host ""
    Write-ColorText "═══ Restore Settings ═══" "Cyan"
    Write-Host ""

    # List available backups
    if (-not (Test-Path $BACKUP_DIR)) {
        Write-Status "warning" "No backups found"
        Write-Status "info" "Backups are created automatically before making changes"
        return
    }

    $backups = Get-ChildItem -Path $BACKUP_DIR -Directory | Sort-Object Name -Descending

    if ($backups.Count -eq 0) {
        Write-Status "warning" "No backups found"
        return
    }

    Write-Host "Available backups:" -ForegroundColor Cyan
    Write-Host ""

    for ($i = 0; $i -lt $backups.Count; $i++) {
        $backup = $backups[$i]
        $metadataPath = Join-Path $backup.FullName "metadata.json"

        if (Test-Path $metadataPath) {
            $metadata = Get-Content $metadataPath | ConvertFrom-Json
            Write-Host "  [$($i + 1)] $($metadata.Date)" -ForegroundColor Yellow
            Write-Host "      Path: $($backup.FullName)" -ForegroundColor Gray
        } else {
            Write-Host "  [$($i + 1)] $($backup.Name)" -ForegroundColor Yellow
            Write-Host "      Path: $($backup.FullName)" -ForegroundColor Gray
        }
        Write-Host ""
    }

    Write-Host "  [0] Cancel" -ForegroundColor Red
    Write-Host ""

    $choice = Read-Host "Select backup to restore (0-$($backups.Count))"

    if ($choice -eq "0" -or [string]::IsNullOrWhiteSpace($choice)) {
        Write-Status "info" "Restore cancelled"
        return
    }

    $selectedIndex = [int]$choice - 1
    if ($selectedIndex -lt 0 -or $selectedIndex -ge $backups.Count) {
        Write-Status "error" "Invalid selection"
        return
    }

    $selectedBackup = $backups[$selectedIndex]

    Write-Host ""
    Write-ColorText "═══ Restoring from: $($selectedBackup.Name) ═══" "Yellow"
    Write-Host ""

    $confirm = Read-Host "This will overwrite current settings. Continue? (y/N)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Status "info" "Restore cancelled"
        return
    }

    try {
        # Restore Windows Terminal settings
        $wtBackup = Join-Path $selectedBackup.FullName "wt_settings.json"
        if (Test-Path $wtBackup) {
            $wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
            Copy-Item -Path $wtBackup -Destination $wtSettingsPath -Force
            Write-Status "success" "Windows Terminal settings restored"
        }

        # Restore PuTTY Default Settings
        $puttyBackup = Join-Path $selectedBackup.FullName "putty_default_settings.reg"
        if (Test-Path $puttyBackup) {
            reg import $puttyBackup | Out-Null
            Write-Status "success" "PuTTY Default Settings restored"
        }

        Write-Host ""
        Write-Status "success" "Settings restored successfully!"
        Write-Status "info" "Restart your terminals to apply changes"

    } catch {
        Write-Status "error" "Restore failed: $_"
    }
}

function Remove-DotfilesConfiguration {
    Write-Host ""
    Write-ColorText "═══ Remove Dotfiles Configuration ═══" "Red"
    Write-Host ""

    Write-Host "This will:" -ForegroundColor Yellow
    Write-Host "  • Remove Nerd Font configurations from terminals" -ForegroundColor Gray
    Write-Host "  • Reset Windows Terminal to default font" -ForegroundColor Gray
    Write-Host "  • Reset PuTTY Default Settings to system defaults" -ForegroundColor Gray
    Write-Host "  • NOT uninstall fonts (keep for other apps)" -ForegroundColor Gray
    Write-Host ""

    Write-Status "warning" "A backup will be created before removing settings"
    Write-Host ""

    $confirm = Read-Host "Continue with removal? (y/N)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Status "info" "Removal cancelled"
        return
    }

    # Create backup first
    $backupPath = Backup-Settings

    if (-not $backupPath) {
        Write-Status "error" "Backup failed. Aborting removal for safety."
        return
    }

    try {
        Write-Host ""
        Write-ColorText "═══ Removing Configurations ═══" "Yellow"
        Write-Host ""

        # Reset Windows Terminal
        $wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        if (Test-Path $wtSettingsPath) {
            Write-Status "working" "Resetting Windows Terminal..."

            $settings = Get-Content -Raw $wtSettingsPath | ConvertFrom-Json

            if ($settings.profiles.defaults.font) {
                $settings.profiles.defaults.PSObject.Properties.Remove('font')
                $settings | ConvertTo-Json -Depth 10 | Set-Content $wtSettingsPath
                Write-Status "success" "Windows Terminal reset to default font"
            } else {
                Write-Status "info" "Windows Terminal already using default font"
            }
        }

        # Reset PuTTY Default Settings
        $puttyRegPath = "HKCU:\Software\SimonTatham\PuTTY\Sessions\Default%20Settings"
        if (Test-Path $puttyRegPath) {
            Write-Status "working" "Resetting PuTTY Default Settings..."

            # Remove our custom settings
            Remove-ItemProperty -Path $puttyRegPath -Name "Font" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $puttyRegPath -Name "FontHeight" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $puttyRegPath -Name "LineCodePage" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $puttyRegPath -Name "AllowPasteControls" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $puttyRegPath -Name "TerminalType" -ErrorAction SilentlyContinue

            Write-Status "success" "PuTTY Default Settings reset"
        }

        Write-Host ""
        Write-Status "success" "Configuration removed successfully"
        Write-Status "info" "Backup saved at: $backupPath"
        Write-Status "info" "Fonts remain installed (can be used by other applications)"
        Write-Status "info" "To restore: use option [8] and select the backup"

    } catch {
        Write-Status "error" "Removal failed: $_"
        Write-Status "info" "You can restore from backup: $backupPath"
    }
}

function Show-Menu {
    $status = Get-ComponentStatus

    Clear-Host
    Write-Host $banner -ForegroundColor Cyan
    Write-Host ""

    # Status display
    Write-ColorText "═══ CURRENT STATUS ═══" "Cyan"
    Write-Host ""

    $fontStatus = if ($status.FontInstalled) { "$($colors.Green)✓ Installed$($colors.Reset)" } else { "$($colors.Red)✗ Not Installed$($colors.Reset)" }
    $wtStatus = if ($status.WindowsTerminal) { "$($colors.Green)✓ Detected$($colors.Reset)" } else { "$($colors.Gray)✗ Not Found$($colors.Reset)" }
    $puttyStatus = if ($status.PuTTY) { "$($colors.Green)✓ Detected$($colors.Reset)" } else { "$($colors.Gray)✗ Not Found$($colors.Reset)" }
    $adminStatus = if ($status.IsAdmin) { "$($colors.Green)✓ Administrator$($colors.Reset)" } else { "$($colors.Red)✗ Not Admin$($colors.Reset)" }

    Write-Host "  Nerd Font:        $fontStatus"
    Write-Host "  Windows Terminal: $wtStatus"
    Write-Host "  PuTTY:            $puttyStatus"
    Write-Host "  Privileges:       $adminStatus"
    Write-Host ""

    # Menu options
    Write-ColorText "═══ INSTALLATION OPTIONS ═══" "Cyan"
    Write-Host ""

    Write-ColorText "[1]" "Yellow"
    Write-Host " Install Nerd Fonts" -NoNewline
    Write-Host " (Required for icons)"
    Write-ColorText "    " "Gray"
    Write-Host "→ Downloads UbuntuMono Nerd Font from GitHub" -ForegroundColor Gray
    Write-ColorText "    " "Gray"
    Write-Host "→ Installs to Windows for all users" -ForegroundColor Gray
    Write-ColorText "    " "Gray"
    Write-Host "→ Enables icon rendering in terminals" -ForegroundColor Gray
    Write-Host ""

    Write-ColorText "[2]" "Yellow"
    Write-Host " Configure Windows Terminal" -NoNewline
    if (-not $status.WindowsTerminal) {
        Write-Host " (Not detected)" -ForegroundColor Gray
    } else {
        Write-Host ""
    }
    Write-ColorText "    " "Gray"
    Write-Host "→ Sets default font to UbuntuMono Nerd Font" -ForegroundColor Gray
    Write-ColorText "    " "Gray"
    Write-Host "→ Applies to all profiles automatically" -ForegroundColor Gray
    Write-Host ""

    Write-ColorText "[3]" "Yellow"
    Write-Host " Configure PuTTY Default Settings" -NoNewline
    if (-not $status.PuTTY) {
        Write-Host " (Not detected)" -ForegroundColor Gray
    } else {
        Write-Host ""
    }
    Write-ColorText "    " "Gray"
    Write-Host "→ Modifies Default Settings (not individual sessions)" -ForegroundColor Gray
    Write-ColorText "    " "Gray"
    Write-Host "→ All connections from KeePass inherit settings" -ForegroundColor Gray
    Write-ColorText "    " "Gray"
    Write-Host "→ Enables UTF-8, OSC 52 clipboard, xterm-256color" -ForegroundColor Gray
    Write-Host ""

    Write-ColorText "[4]" "Yellow"
    Write-Host " Full Setup (Recommended)" -NoNewline
    Write-Host " - All of the above"
    Write-ColorText "    " "Gray"
    Write-Host "→ Install fonts + configure all detected terminals" -ForegroundColor Gray
    Write-Host ""

    Write-ColorText "[5]" "Yellow"
    Write-Host " Install Dotfiles on Remote Server"
    Write-ColorText "    " "Gray"
    Write-Host "→ SSH to Linux server and run dotfiles installation" -ForegroundColor Gray
    Write-ColorText "    " "Gray"
    Write-Host "→ Requires SSH client (OpenSSH/PuTTY)" -ForegroundColor Gray
    Write-Host ""

    Write-ColorText "[6]" "Yellow"
    Write-Host " Complete Workflow (Fonts + Terminals + Remote)"
    Write-ColorText "    " "Gray"
    Write-Host "→ Does everything: local setup + server install" -ForegroundColor Gray
    Write-Host ""

    Write-ColorText "[7]" "Magenta"
    Write-Host " Remove Dotfiles Configuration (Reset to Default)"
    Write-ColorText "    " "Gray"
    Write-Host "→ Removes Nerd Font settings from terminals" -ForegroundColor Gray
    Write-ColorText "    " "Gray"
    Write-Host "→ Creates backup before removal" -ForegroundColor Gray
    Write-ColorText "    " "Gray"
    Write-Host "→ Keeps fonts installed (for other apps)" -ForegroundColor Gray
    Write-Host ""

    Write-ColorText "[8]" "Magenta"
    Write-Host " Restore from Backup"
    Write-ColorText "    " "Gray"
    Write-Host "→ Lists available backups" -ForegroundColor Gray
    Write-ColorText "    " "Gray"
    Write-Host "→ Restores previous terminal configurations" -ForegroundColor Gray
    Write-Host ""

    Write-ColorText "[X]" "Red"
    Write-Host " Exit"
    Write-Host ""

    Write-ColorText "═══════════════════════════════" "Cyan"
    Write-Host ""

    # Check for existing backups
    if (Test-Path $BACKUP_DIR) {
        $backupCount = (Get-ChildItem -Path $BACKUP_DIR -Directory).Count
        if ($backupCount -gt 0) {
            Write-Status "info" "$backupCount backup(s) available (use option 8 to restore)"
            Write-Host ""
        }
    }

    if (-not $status.IsAdmin) {
        Write-Status "warning" "Some options require Administrator privileges"
        Write-Host "  Right-click PowerShell → Run as Administrator" -ForegroundColor Gray
        Write-Host ""
    }
}

function Install-NerdFont {
    Write-Host ""
    Write-ColorText "═══ Installing Nerd Fonts ═══" "Cyan"
    Write-Host ""

    if (-not (Test-AdminPrivileges)) {
        Write-Status "error" "Administrator privileges required for font installation"
        Write-Status "info" "Right-click PowerShell and select 'Run as Administrator'"
        return $false
    }

    if (Test-FontInstalled) {
        Write-Status "success" "UbuntuMono Nerd Font already installed"
        return $true
    }

    try {
        # Create temp directory
        if (Test-Path $TEMP_DIR) {
            Remove-Item -Recurse -Force $TEMP_DIR
        }
        New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null

        Write-Status "working" "Downloading UbuntuMono Nerd Font..."
        $zipPath = "$TEMP_DIR\UbuntuMono.zip"

        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $FONT_DOWNLOAD_URL -OutFile $zipPath -UseBasicParsing
        $ProgressPreference = 'Continue'

        Write-Status "working" "Extracting fonts..."
        Expand-Archive -Path $zipPath -DestinationPath "$TEMP_DIR\fonts" -Force

        Write-Status "working" "Installing fonts to system..."
        $fonts = Get-ChildItem -Path "$TEMP_DIR\fonts" -Include *.ttf, *.otf -Recurse

        $shellApp = New-Object -ComObject Shell.Application
        $fontsFolder = $shellApp.Namespace(0x14)

        foreach ($font in $fonts) {
            Write-Host "    Installing: $($font.Name)" -ForegroundColor Gray
            $fontsFolder.CopyHere($font.FullName, 0x10)

            $fontName = [System.IO.Path]::GetFileNameWithoutExtension($font.Name)
            $registryPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
            Set-ItemProperty -Path $registryPath -Name "$fontName (TrueType)" -Value $font.Name -Force
        }

        Remove-Item -Recurse -Force $TEMP_DIR

        Write-Status "success" "Nerd Fonts installed successfully"
        Add-Action "Installed UbuntuMono Nerd Font ($($fonts.Count) font files)"
        return $true

    } catch {
        Write-Status "error" "Failed to install fonts: $_"
        Write-Log "Font installation failed: $_" "ERROR"
        return $false
    }
}

function Configure-WindowsTerminal {
    param([bool]$SkipBackup = $false)

    Write-Host ""
    Write-ColorText "═══ Configuring Windows Terminal ═══" "Cyan"
    Write-Host ""

    if (-not (Test-WindowsTerminalInstalled)) {
        Write-Status "warning" "Windows Terminal not detected (skipping)"
        Write-Status "info" "Install from Microsoft Store or winget install Microsoft.WindowsTerminal"
        return $false
    }

    $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

    if (-not (Test-Path $settingsPath)) {
        Write-Status "warning" "Windows Terminal settings.json not found (skipping)"
        return $false
    }

    # Create backup before modifying
    if (-not $SkipBackup) {
        Backup-Settings | Out-Null
    }

    try {
        Write-Status "working" "Updating settings.json..."

        $settings = Get-Content -Raw $settingsPath | ConvertFrom-Json

        if (-not $settings.profiles.defaults) {
            $settings.profiles | Add-Member -MemberType NoteProperty -Name "defaults" -Value @{} -Force
        }

        $settings.profiles.defaults | Add-Member -MemberType NoteProperty -Name "font" -Value @{
            face = "UbuntuMono Nerd Font"
            size = 11
        } -Force

        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath

        Write-Status "success" "Windows Terminal configured"
        Write-Status "info" "Font: UbuntuMono Nerd Font, Size: 11"
        Write-Status "info" "Restart Windows Terminal to apply changes"
        Add-Action "Configured Windows Terminal (Font: UbuntuMono Nerd Font, Size: 11)"
        return $true

    } catch {
        Write-Status "error" "Failed to configure Windows Terminal: $_"
        Write-Log "Windows Terminal configuration failed: $_" "ERROR"
        return $false
    }
}

function Configure-PuTTY {
    param([bool]$SkipBackup = $false)

    Write-Host ""
    Write-ColorText "═══ Configuring PuTTY Default Settings ═══" "Cyan"
    Write-Host ""

    if (-not (Test-PuTTYInstalled)) {
        Write-Status "warning" "PuTTY not detected (skipping)"
        Write-Status "info" "Install from https://www.putty.org/"
        return $false
    }

    # Create backup before modifying
    if (-not $SkipBackup) {
        Backup-Settings | Out-Null
    }

    try {
        Write-Status "working" "Modifying PuTTY Default Settings..."

        # PuTTY's Default Settings are stored in the registry under the session name "Default%20Settings"
        $puttyRegPath = "HKCU:\Software\SimonTatham\PuTTY\Sessions\Default%20Settings"

        # Create path if it doesn't exist
        if (-not (Test-Path $puttyRegPath)) {
            New-Item -Path $puttyRegPath -Force | Out-Null
        }

        # Font configuration
        Set-ItemProperty -Path $puttyRegPath -Name "Font" -Value "UbuntuMono Nerd Font" -Type String
        Set-ItemProperty -Path $puttyRegPath -Name "FontHeight" -Value 11 -Type DWord
        Set-ItemProperty -Path $puttyRegPath -Name "FontCharSet" -Value 0 -Type DWord
        Set-ItemProperty -Path $puttyRegPath -Name "FontIsBold" -Value 0 -Type DWord

        # UTF-8 encoding
        Set-ItemProperty -Path $puttyRegPath -Name "LineCodePage" -Value "UTF-8" -Type String
        Set-ItemProperty -Path $puttyRegPath -Name "CJKAmbigAsWide" -Value 0 -Type DWord

        # OSC 52 clipboard support
        Set-ItemProperty -Path $puttyRegPath -Name "AllowPasteControls" -Value 1 -Type DWord

        # Terminal type
        Set-ItemProperty -Path $puttyRegPath -Name "TerminalType" -Value "xterm-256color" -Type String

        # Window appearance (optional - makes it look nicer)
        Set-ItemProperty -Path $puttyRegPath -Name "TermWidth" -Value 120 -Type DWord
        Set-ItemProperty -Path $puttyRegPath -Name "TermHeight" -Value 30 -Type DWord

        Write-Status "success" "PuTTY Default Settings configured"
        Write-Status "info" "Font: UbuntuMono Nerd Font, Size: 11"
        Write-Status "info" "UTF-8: Enabled | OSC 52: Enabled | Terminal: xterm-256color"
        Write-Status "info" "All connections (including from KeePass) will inherit these settings"
        Add-Action "Configured PuTTY Default Settings (Font, UTF-8, OSC 52, xterm-256color)"
        return $true

    } catch {
        Write-Status "error" "Failed to configure PuTTY: $_"
        Write-Log "PuTTY configuration failed: $_" "ERROR"
        return $false
    }
}

function Save-InstallationSummary {
    Write-Host ""
    Write-ColorText "═══ Generating Installation Summary ═══" "Cyan"
    Write-Host ""

    try {
        # Gather system information
        $summary = @"
================================================================================
DOTFILES INSTALLATION SUMMARY
================================================================================

Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Computer: $env:COMPUTERNAME
User: $env:USERNAME
PowerShell Version: $($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)

================================================================================
ACTIONS PERFORMED
================================================================================

"@

        if ($script:ActionsPerformed.Count -gt 0) {
            foreach ($action in $script:ActionsPerformed) {
                $summary += "✓ $action`n"
            }
        } else {
            $summary += "(No actions performed)`n"
        }

        $summary += @"

================================================================================
CURRENT CONFIGURATION
================================================================================

Nerd Font Installed: $(if (Test-FontInstalled) { "YES" } else { "NO" })
Windows Terminal: $(if (Test-WindowsTerminalInstalled) { "Detected" } else { "Not Found" })
PuTTY: $(if (Test-PuTTYInstalled) { "Detected" } else { "Not Found" })

================================================================================
BACKUPS CREATED
================================================================================

Backup Directory: $BACKUP_DIR

"@

        if (Test-Path $BACKUP_DIR) {
            $backups = Get-ChildItem -Path $BACKUP_DIR -Directory | Sort-Object Name -Descending
            if ($backups.Count -gt 0) {
                foreach ($backup in $backups) {
                    $summary += "• $($backup.Name)`n"
                    $summary += "  Path: $($backup.FullName)`n"
                }
            } else {
                $summary += "(No backups yet)`n"
            }
        } else {
            $summary += "(No backup directory created)`n"
        }

        $summary += @"

================================================================================
NEXT STEPS
================================================================================

"@

        if ($script:ActionsPerformed.Count -gt 0) {
            $summary += @"
1. RESTART YOUR TERMINAL
   - Close all instances of Windows Terminal / PuTTY
   - Reopen to apply the new font settings

2. CONNECT TO YOUR SERVER
   - SSH to your Linux server
   - Icons and formatting should now display correctly

3. KEEPASS USERS (PuTTY)
   - All existing connections in KeePass will automatically use the new font
   - No need to reconfigure individual sessions
   - Just launch any connection from KeePass

4. IF SOMETHING GOES WRONG
   - Backup location: $BACKUP_DIR
   - Run this installer again and select option [8] to restore
   - All settings can be rolled back safely

"@
        } else {
            $summary += "• No changes were made during this session`n"
        }

        $summary += @"

================================================================================
INSTALLATION LOG
================================================================================

"@

        foreach ($logEntry in $script:InstallationLog) {
            $summary += "$logEntry`n"
        }

        $summary += @"

================================================================================
SUPPORT & DOCUMENTATION
================================================================================

GitHub Repository: https://github.com/deey001/dotfiles
Documentation: See README.md and WINDOWS-SETUP-GUIDE.md
Issues: https://github.com/deey001/dotfiles/issues

================================================================================
END OF SUMMARY
================================================================================
"@

        # Save to Documents folder
        $summary | Out-File -FilePath $LOG_FILE -Encoding UTF8
        Write-Status "success" "Installation summary saved to:"
        Write-Host "  $LOG_FILE" -ForegroundColor Cyan
        Write-Host ""

        # Display abbreviated summary to console
        Write-ColorText "═══ INSTALLATION COMPLETE ═══" "Green"
        Write-Host ""

        if ($script:ActionsPerformed.Count -gt 0) {
            Write-Host "Actions completed:" -ForegroundColor Cyan
            foreach ($action in $script:ActionsPerformed) {
                Write-Host "  ✓ $action" -ForegroundColor Green
            }
            Write-Host ""

            Write-Host "IMPORTANT: Restart your terminals to apply changes!" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Full details saved to:" -ForegroundColor Gray
            Write-Host "  $LOG_FILE" -ForegroundColor Cyan
        } else {
            Write-Host "No changes were made during this session." -ForegroundColor Gray
        }

    } catch {
        Write-Status "warning" "Could not save summary: $_"
    }
}

function Install-RemoteDotfiles {
    Write-Host ""
    Write-ColorText "═══ Remote Server Installation ═══" "Cyan"
    Write-Host ""

    $sshHost = Read-Host "Enter SSH host (e.g., user@hostname or IP)"

    if ([string]::IsNullOrWhiteSpace($sshHost)) {
        Write-Status "warning" "No host provided, skipping"
        return $false
    }

    $sshInstalled = Get-Command ssh -ErrorAction SilentlyContinue

    if (-not $sshInstalled) {
        Write-Status "error" "SSH client not found"
        Write-Status "info" "Install OpenSSH: Settings → Apps → Optional Features → OpenSSH Client"
        Write-Host ""
        Write-Status "info" "Alternatively, use PuTTY to connect manually and run:"
        Write-Host "  git clone $REPO_URL ~/dotfiles && cd ~/dotfiles && ./install.sh" -ForegroundColor Gray
        return $false
    }

    try {
        $remoteCommand = @"
git clone $REPO_URL ~/dotfiles 2>/dev/null || (cd ~/dotfiles && git pull);
cd ~/dotfiles && ./install.sh
"@

        Write-Status "working" "Connecting to $sshHost..."
        Write-Host ""

        ssh -t $sshHost $remoteCommand

        Write-Host ""
        Write-Status "success" "Remote installation completed"
        return $true

    } catch {
        Write-Status "error" "Remote installation failed: $_"
        Write-Status "info" "Try connecting manually and running:"
        Write-Host "  git clone $REPO_URL ~/dotfiles && cd ~/dotfiles && ./install.sh" -ForegroundColor Gray
        return $false
    }
}

function Show-CompletionMessage {
    Write-Host ""
    Write-ColorText "═══════════════════════════════════════════════════════════" "Green"
    Write-ColorText "                  ✓ Installation Complete!                  " "Green"
    Write-ColorText "═══════════════════════════════════════════════════════════" "Green"
    Write-Host ""
    Write-Status "success" "Nerd Fonts installed and terminals configured"
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. Restart your terminal (Windows Terminal or PuTTY)" -ForegroundColor White
    Write-Host "  2. Connect to your server via SSH" -ForegroundColor White
    Write-Host "  3. Icons should now display correctly! 🎨" -ForegroundColor White
    Write-Host ""
    Write-Host "For PuTTY + KeePass users:" -ForegroundColor Cyan
    Write-Host "  → Default Settings are now configured" -ForegroundColor Gray
    Write-Host "  → All connections from KeePass will use Nerd Font" -ForegroundColor Gray
    Write-Host "  → No need to configure individual sessions!" -ForegroundColor Gray
    Write-Host ""
}

# Main execution
function Main {
    # Check if running via one-liner (no console buffer)
    if (-not $Host.UI.RawUI.BufferSize) {
        Write-Host "This script should be run interactively. Please download and run locally." -ForegroundColor Red
        return
    }

    while ($true) {
        Show-Menu

        $choice = Read-Host "Select an option"

        switch ($choice.ToUpper()) {
            "1" {
                Install-NerdFont
                Write-Host ""
                Read-Host "Press Enter to continue"
            }
            "2" {
                Configure-WindowsTerminal
                Write-Host ""
                Read-Host "Press Enter to continue"
            }
            "3" {
                Configure-PuTTY
                Write-Host ""
                Read-Host "Press Enter to continue"
            }
            "4" {
                # Create one backup for all operations
                Backup-Settings | Out-Null

                $fontOk = Install-NerdFont
                if ($fontOk) {
                    Configure-WindowsTerminal -SkipBackup $true
                    Configure-PuTTY -SkipBackup $true
                    Show-CompletionMessage
                }
                Read-Host "Press Enter to continue"
            }
            "5" {
                Install-RemoteDotfiles
                Write-Host ""
                Read-Host "Press Enter to continue"
            }
            "6" {
                # Create one backup for all operations
                Backup-Settings | Out-Null

                $fontOk = Install-NerdFont
                if ($fontOk) {
                    Configure-WindowsTerminal -SkipBackup $true
                    Configure-PuTTY -SkipBackup $true
                    Install-RemoteDotfiles
                    Show-CompletionMessage
                }
                Read-Host "Press Enter to continue"
            }
            "7" {
                Remove-DotfilesConfiguration
                Write-Host ""
                Read-Host "Press Enter to continue"
            }
            "8" {
                Restore-Settings
                Write-Host ""
                Read-Host "Press Enter to continue"
            }
            "X" {
                Write-Host ""

                # Save summary if any actions were performed
                if ($script:ActionsPerformed.Count -gt 0) {
                    Save-InstallationSummary
                } else {
                    Write-Status "info" "No changes were made during this session"
                }

                Write-Host ""
                Write-Status "info" "Exiting... Goodbye!"
                Write-Host ""
                return
            }
            default {
                Write-Status "error" "Invalid option. Please select 1-8 or X"
                Start-Sleep -Seconds 1
            }
        }
    }
}

# Run
Main
