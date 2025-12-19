# ==============================================================================
# local-setup.ps1 - Windows Local Setup for Dotfiles
# ==============================================================================
# This script runs on your LOCAL Windows machine BEFORE connecting to servers.
# It installs Nerd Fonts and configures Windows Terminal/PuTTY automatically.
#
# USAGE:
#   1. Open PowerShell as Administrator
#   2. Run: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   3. Run: .\local-setup.ps1
#   4. Script will:
#      - Install Ubuntu Nerd Font on Windows
#      - Configure Windows Terminal (if installed)
#      - Create PuTTY session template with Nerd Font
#      - Optionally run remote installation via SSH
#
# ==============================================================================

# Requires Administrator privileges
#Requires -RunAsAdministrator

Write-Host "=============================================================================="
Write-Host "Dotfiles Local Setup for Windows"
Write-Host "=============================================================================="
Write-Host ""

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

$FONT_NAME = "UbuntuMono Nerd Font"
$FONT_DOWNLOAD_URL = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/UbuntuMono.zip"
$TEMP_DIR = "$env:TEMP\nerd-fonts-install"
$FONT_INSTALL_DIR = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------

function Test-AdminPrivileges {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-NerdFont {
    Write-Host "[1/4] Installing Ubuntu Nerd Font..." -ForegroundColor Cyan

    # Check if font already installed
    $fontInstalled = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -ErrorAction SilentlyContinue |
        Select-String -Pattern "UbuntuMono" -Quiet

    if ($fontInstalled) {
        Write-Host "  ✓ Ubuntu Nerd Font already installed" -ForegroundColor Green
        return $true
    }

    try {
        # Create temp directory
        if (Test-Path $TEMP_DIR) {
            Remove-Item -Recurse -Force $TEMP_DIR
        }
        New-Item -ItemType Directory -Path $TEMP_DIR -Force | Out-Null

        Write-Host "  → Downloading Ubuntu Nerd Font..." -ForegroundColor Yellow
        $zipPath = "$TEMP_DIR\UbuntuMono.zip"

        # Download with progress
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $FONT_DOWNLOAD_URL -OutFile $zipPath -UseBasicParsing
        $ProgressPreference = 'Continue'

        Write-Host "  → Extracting fonts..." -ForegroundColor Yellow
        Expand-Archive -Path $zipPath -DestinationPath "$TEMP_DIR\fonts" -Force

        # Install fonts
        Write-Host "  → Installing fonts to system..." -ForegroundColor Yellow
        $fonts = Get-ChildItem -Path "$TEMP_DIR\fonts" -Include *.ttf, *.otf -Recurse

        $shellApp = New-Object -ComObject Shell.Application
        $fontsFolder = $shellApp.Namespace(0x14)

        foreach ($font in $fonts) {
            Write-Host "    Installing: $($font.Name)" -ForegroundColor Gray
            $fontsFolder.CopyHere($font.FullName, 0x10)

            # Register font in registry (for current user)
            $fontName = [System.IO.Path]::GetFileNameWithoutExtension($font.Name)
            $registryPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
            Set-ItemProperty -Path $registryPath -Name "$fontName (TrueType)" -Value $font.Name -Force
        }

        # Clean up
        Remove-Item -Recurse -Force $TEMP_DIR

        Write-Host "  ✓ Ubuntu Nerd Font installed successfully" -ForegroundColor Green
        return $true

    } catch {
        Write-Host "  ✗ Failed to install font: $_" -ForegroundColor Red
        return $false
    }
}

function Configure-WindowsTerminal {
    Write-Host "[2/4] Configuring Windows Terminal..." -ForegroundColor Cyan

    # Check if Windows Terminal is installed
    $wtInstalled = Get-Command wt.exe -ErrorAction SilentlyContinue

    if (-not $wtInstalled) {
        Write-Host "  ⊘ Windows Terminal not installed (skipping)" -ForegroundColor Yellow
        return
    }

    $settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

    if (-not (Test-Path $settingsPath)) {
        Write-Host "  ⊘ Windows Terminal settings not found (skipping)" -ForegroundColor Yellow
        return
    }

    try {
        # Read settings
        $settings = Get-Content -Raw $settingsPath | ConvertFrom-Json

        # Update default profile font
        if (-not $settings.profiles.defaults) {
            $settings.profiles | Add-Member -MemberType NoteProperty -Name "defaults" -Value @{} -Force
        }

        $settings.profiles.defaults | Add-Member -MemberType NoteProperty -Name "font" -Value @{
            face = "UbuntuMono Nerd Font"
            size = 11
        } -Force

        # Save settings
        $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath

        Write-Host "  ✓ Windows Terminal configured with UbuntuMono Nerd Font" -ForegroundColor Green

    } catch {
        Write-Host "  ⚠ Could not update Windows Terminal settings: $_" -ForegroundColor Yellow
    }
}

function Configure-PuTTY {
    Write-Host "[3/4] Configuring PuTTY..." -ForegroundColor Cyan

    # Check if PuTTY is installed
    $puttyInstalled = Get-Command putty.exe -ErrorAction SilentlyContinue

    if (-not $puttyInstalled) {
        Write-Host "  ⊘ PuTTY not installed (skipping)" -ForegroundColor Yellow
        Write-Host "    Install from: https://www.putty.org/" -ForegroundColor Gray
        return
    }

    try {
        # Create a template session in registry with Nerd Font
        $puttyRegPath = "HKCU:\Software\SimonTatham\PuTTY\Sessions\Dotfiles-Template"

        # Create registry path if it doesn't exist
        if (-not (Test-Path $puttyRegPath)) {
            New-Item -Path $puttyRegPath -Force | Out-Null
        }

        # Set font configuration
        Set-ItemProperty -Path $puttyRegPath -Name "Font" -Value "UbuntuMono Nerd Font" -Type String
        Set-ItemProperty -Path $puttyRegPath -Name "FontHeight" -Value 11 -Type DWord
        Set-ItemProperty -Path $puttyRegPath -Name "FontCharSet" -Value 0 -Type DWord
        Set-ItemProperty -Path $puttyRegPath -Name "FontIsBold" -Value 0 -Type DWord

        # Enable UTF-8
        Set-ItemProperty -Path $puttyRegPath -Name "LineCodePage" -Value "UTF-8" -Type String
        Set-ItemProperty -Path $puttyRegPath -Name "CJKAmbigAsWide" -Value 0 -Type DWord

        # Enable clipboard integration (OSC 52)
        Set-ItemProperty -Path $puttyRegPath -Name "AllowPasteControls" -Value 1 -Type DWord

        # Terminal type
        Set-ItemProperty -Path $puttyRegPath -Name "TerminalType" -Value "xterm-256color" -Type String

        Write-Host "  ✓ PuTTY template session 'Dotfiles-Template' created" -ForegroundColor Green
        Write-Host "    → Load this session in PuTTY as a template for new connections" -ForegroundColor Gray
        Write-Host "    → Go to: Session → Saved Sessions → 'Dotfiles-Template' → Load" -ForegroundColor Gray

    } catch {
        Write-Host "  ⚠ Could not configure PuTTY: $_" -ForegroundColor Yellow
    }
}

function Install-RemoteDotfiles {
    Write-Host "[4/4] Remote Server Installation..." -ForegroundColor Cyan
    Write-Host ""

    $response = Read-Host "Do you want to install dotfiles on a remote server now? (y/N)"

    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Host "  ⊘ Skipping remote installation" -ForegroundColor Yellow
        Write-Host "    You can manually SSH and run:" -ForegroundColor Gray
        Write-Host "    git clone https://github.com/deey001/dotfiles.git ~/dotfiles && cd ~/dotfiles && ./install.sh" -ForegroundColor Gray
        return
    }

    Write-Host ""
    $sshHost = Read-Host "Enter SSH host (e.g., user@hostname or IP)"

    if ([string]::IsNullOrWhiteSpace($sshHost)) {
        Write-Host "  ✗ No host provided, skipping" -ForegroundColor Red
        return
    }

    Write-Host ""
    Write-Host "  → Connecting to $sshHost..." -ForegroundColor Yellow

    # Check if ssh is available
    $sshInstalled = Get-Command ssh -ErrorAction SilentlyContinue

    if (-not $sshInstalled) {
        Write-Host "  ✗ SSH client not found. Install OpenSSH or use PuTTY manually." -ForegroundColor Red
        Write-Host "    Manual command:" -ForegroundColor Gray
        Write-Host "    ssh $sshHost" -ForegroundColor Gray
        Write-Host "    git clone https://github.com/deey001/dotfiles.git ~/dotfiles && cd ~/dotfiles && ./install.sh" -ForegroundColor Gray
        return
    }

    try {
        # Create remote installation command
        $remoteCommand = @"
git clone https://github.com/deey001/dotfiles.git ~/dotfiles 2>/dev/null || (cd ~/dotfiles && git pull);
cd ~/dotfiles && ./install.sh
"@

        Write-Host "  → Running remote installation..." -ForegroundColor Yellow
        Write-Host ""

        # Execute via SSH
        ssh -t $sshHost $remoteCommand

        Write-Host ""
        Write-Host "  ✓ Remote installation completed" -ForegroundColor Green

    } catch {
        Write-Host "  ✗ Remote installation failed: $_" -ForegroundColor Red
        Write-Host "    Try connecting manually with your configured terminal" -ForegroundColor Gray
    }
}

# ------------------------------------------------------------------------------
# Main Execution
# ------------------------------------------------------------------------------

# Check admin privileges
if (-not (Test-AdminPrivileges)) {
    Write-Host "ERROR: This script requires Administrator privileges" -ForegroundColor Red
    Write-Host "Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

Write-Host "This script will:"
Write-Host "  1. Install Ubuntu Nerd Font on Windows"
Write-Host "  2. Configure Windows Terminal (if installed)"
Write-Host "  3. Create PuTTY template session (if installed)"
Write-Host "  4. Optionally install dotfiles on remote server"
Write-Host ""

$confirm = Read-Host "Continue? (Y/n)"
if ($confirm -eq 'n' -or $confirm -eq 'N') {
    Write-Host "Aborted by user" -ForegroundColor Yellow
    exit 0
}

Write-Host ""

# Run installation steps
$fontSuccess = Install-NerdFont

if ($fontSuccess) {
    Configure-WindowsTerminal
    Configure-PuTTY
    Write-Host ""
    Install-RemoteDotfiles
} else {
    Write-Host ""
    Write-Host "Font installation failed. Cannot proceed with terminal configuration." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=============================================================================="
Write-Host "Local Setup Complete!"
Write-Host "=============================================================================="
Write-Host ""
Write-Host "NEXT STEPS:"
Write-Host ""
Write-Host "For Windows Terminal users:"
Write-Host "  → Restart Windows Terminal"
Write-Host "  → Font should automatically be set to UbuntuMono Nerd Font"
Write-Host ""
Write-Host "For PuTTY users:"
Write-Host "  1. Open PuTTY"
Write-Host "  2. Go to: Session → Saved Sessions"
Write-Host "  3. Select 'Dotfiles-Template'"
Write-Host "  4. Click 'Load'"
Write-Host "  5. Enter your host details"
Write-Host "  6. Save as a new session"
Write-Host "  7. Connect!"
Write-Host ""
Write-Host "Icons should now display correctly! 🎨"
Write-Host "=============================================================================="
