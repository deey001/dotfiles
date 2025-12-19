# ==============================================================================
# Dotfiles Windows Installer - Interactive Menu
# ==============================================================================
# One-liner install: irm "https://raw.githubusercontent.com/deey001/dotfiles/master/install.ps1" | iex
#
# This script provides an interactive menu for installing Nerd Fonts and
# configuring Windows terminals (Windows Terminal & PuTTY).
# ==============================================================================

# ASCII Art Banner
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

# Configuration
$FONT_NAME = "UbuntuMono Nerd Font"
$FONT_DOWNLOAD_URL = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/UbuntuMono.zip"
$REPO_URL = "https://github.com/deey001/dotfiles.git"
$TEMP_DIR = "$env:TEMP\nerd-fonts-install"
$BACKUP_DIR = "$env:USERPROFILE\.dotfiles-backup"
$BACKUP_TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"

# Colors
$colors = @{
    Reset = "`e[0m"
    Bold = "`e[1m"
    Red = "`e[91m"
    Green = "`e[92m"
    Yellow = "`e[93m"
    Blue = "`e[94m"
    Magenta = "`e[95m"
    Cyan = "`e[96m"
    White = "`e[97m"
    Gray = "`e[90m"
}

# Helper Functions
function Write-ColorText {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    Write-Host "$($colors[$Color])$Text$($colors.Reset)"
}

function Write-Status {
    param(
        [string]$Status,
        [string]$Message
    )
    switch ($Status) {
        "info"    { Write-Host "$($colors.Blue)[i]$($colors.Reset) $Message" }
        "success" { Write-Host "$($colors.Green)[✓]$($colors.Reset) $Message" }
        "warning" { Write-Host "$($colors.Yellow)[!]$($colors.Reset) $Message" }
        "error"   { Write-Host "$($colors.Red)[✗]$($colors.Reset) $Message" }
        "working" { Write-Host "$($colors.Cyan)[→]$($colors.Reset) $Message" }
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
        return $true

    } catch {
        Write-Status "error" "Failed to install fonts: $_"
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
        return $true

    } catch {
        Write-Status "error" "Failed to configure Windows Terminal: $_"
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
        return $true

    } catch {
        Write-Status "error" "Failed to configure PuTTY: $_"
        return $false
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
