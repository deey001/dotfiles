<#
.SYNOPSIS
    Dotfiles Windows Local Setup — Installs Nerd Fonts and configures terminals for proper icon display
    One-liner: irm "https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.ps1" | iex

.DESCRIPTION
    This script prepares Windows machines so that Nerd Font icons display correctly
    when colleagues connect (via Windows Terminal, PuTTY, or KeePass) to Linux servers running your dotfiles.

    Key Features:
    - [FIX] Enforces TLS 1.2 for GitHub connectivity
    - [FIX] Auto-Elevates to Administrator if run as standard user
    - Automatically upgrades PowerShell 5 → PowerShell 7 with no prompts
    - Installs JetBrainsMono Nerd Font (System-wide)
    - Configures Windows Terminal and PuTTY **Default Settings** (critical for KeePass compatibility)
    - Creates timestamped backups before any changes
    - Chris Titus-style interactive menu with descriptions
    - Comprehensive logging and summary saved to Documents folder
    - Restore and reset options
    - Full idiot-proof status messages

    Philosophy: KISS — everything via one simple one-liner.

    DIFFERENCES FROM LINUX INSTALLER (scripts/install.sh):
    - Linux installer: full dotfiles setup (symlinks, packages, shell config, ble.sh, etc.)
    - This script: Windows-side companion focused on font + terminal configuration so
      that icons from the Linux dotfiles render correctly in Windows SSH clients.
    - This script uses winget for package management (vs apt/dnf/pacman/brew on Linux).
    - Symlink creation requires Administrator privileges on Windows (not needed on Linux).
    - Neovim on Windows lives in $env:LOCALAPPDATA\nvim (not ~/.config/nvim).

    SUGGESTED ADDITIONS (not yet implemented):
    TODO: Install additional winget packages: Microsoft.WindowsTerminal, JanDeDobbeleer.OhMyPosh
    TODO: Configure Windows Defender exclusions for ~/.local and ~/dotfiles (performance)
    TODO: Set up SSH agent service (ssh-agent) auto-start on Windows
    TODO: Add winget package list export/import for reproducible Windows dev environments
#>

# VERSION: 1.0.5 (ASCII-SAFE + NO-CACHE)
# ========================================================================================

# Force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Helper: Check if the current user has Administrator privileges.
function Test-AdminPrivileges {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Auto-Elevate: If not running as Admin, download the script to a temp file and
# relaunch in an elevated PowerShell window.
if (-not (Test-AdminPrivileges)) {
    Write-Host "█▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█" -ForegroundColor Red
    Write-Host "█  ADMINISTRATOR PRIVILEGES REQUIRED - AUTO-ELEVATING    █" -ForegroundColor Yellow
    Write-Host "█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█" -ForegroundColor Red
    Write-Host "`nPlease accept the UAC prompt to continue..." -ForegroundColor Gray
    
    $TempScript = "$env:TEMP\DotfilesSetup.ps1"
    try {
        Write-Host "Downloading latest version..." -ForegroundColor Cyan
        # Use a random number to bust the GitHub cache
        $v = Get-Random
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.ps1?v=$v" -OutFile $TempScript -UseBasicParsing
        
        Start-Process powershell -Verb RunAs -ArgumentList "-NoExit", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$TempScript`""
    } catch {
        Write-Host "`n[ERROR] Failed to prepare auto-elevation: $_" -ForegroundColor Red
    }
    exit
}

# ========================================================================================
# Section 1: PowerShell Version Check and Auto-Upgrade
# ========================================================================================
# PowerShell 5 (bundled with Windows) lacks modern features used by this script:
# ANSI escape codes, improved JSON handling, and better error messages.
# This section auto-upgrades to PowerShell 7 using winget (primary) or the
# official Microsoft install script (fallback).
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
            
            # Wait for MSI to finish (Checking file existence loop)
            Write-Host "Waiting for installer to complete (this may take a few minutes)..." -ForegroundColor Cyan
            $maxRetries = 60 # 60 * 5s = 5 minutes
            $retryCount = 0
            
            do {
                Start-Sleep -Seconds 5
                $pwsh7Path = $pwsh7Paths | Where-Object { Test-Path $_ } | Select-Object -First 1
                $retryCount++
                if ($retryCount % 6 -eq 0) { Write-Host "." -NoNewline }
            } until ($pwsh7Path -or $retryCount -ge $maxRetries)
            Write-Host "" # Newline
        } catch {
            Write-Host "Fallback failed: $_" -ForegroundColor Red
        }
    }

    if ($pwsh7Path) {
        Write-Host "PowerShell 7 installed. Relaunching in new elevated window..." -ForegroundColor Green

        # Use same temp file strategy for reliability
        $TempScript = "$env:TEMP\DotfilesSetup.ps1"
        $v = Get-Random
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.ps1?v=$v" -OutFile $TempScript -UseBasicParsing

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
# PowerShell 7 supports ANSI escape sequences natively, but we need UTF-8 encoding
# for Nerd Font icons. If the console doesn't support it, fall back to Write-Host
# -ForegroundColor (no icons, but still readable).
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
# Centralized paths and URLs used throughout the script.
# FONT_DOWNLOAD_URL: GitHub Releases always has the latest Nerd Fonts version.
# BACKUP_DIR: Timestamped backups of PuTTY/WT settings live here.
# LOG_FILE: Saved to Documents so it's easy to find and share for debugging.
# ========================================================================================
$FONT_DOWNLOAD_URL = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
$TEMP_DIR = "$env:TEMP\nerd-fonts-install"
$BACKUP_DIR = "$env:USERPROFILE\.dotfiles-backup"
$BACKUP_TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"
$LOG_FILE = "$env:USERPROFILE\Documents\dotfiles-install-log-$BACKUP_TIMESTAMP.txt"

# Script-scoped arrays to accumulate log entries and action summaries
$script:InstallationLog = @()
$script:ActionsPerformed = @()

# ========================================================================================
# Section 4: ANSI Color Definitions
# ========================================================================================
# Uses `e (backtick-e) escape sequences — only works in PowerShell 7+.
# Section 2 sets $script:UseColors=false if the console doesn't support ANSI.
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
# Write-Log:       Appends timestamped entries to the in-memory log (saved at exit)
# Add-Action:      Records a user-visible action for the installation summary
# Write-ColorText: Wraps Write-Host with ANSI color support and automatic logging
# Write-Status:    Prints a status icon (✓/✗/→/!/i) with contextual coloring
# Test-FontInstalled: Checks Windows font registry + user font directory
# ========================================================================================

# Append a timestamped log entry to the in-memory log array
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    $script:InstallationLog += $logEntry
}

# Record a user-facing action for the final summary report
function Add-Action {
    param([string]$Action)
    $script:ActionsPerformed += $Action
    Write-Log $Action "ACTION"
}

# Print colored text — uses ANSI escapes when available, falls back to -ForegroundColor
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

# Print a status line with icon prefix (✓ Success, ✗ Error, → Progress, ! Warning, i Info)
function Write-Status {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [ValidateSet("Success","Error","Progress","Warning","Info")][string]$StatusType
    )
    $statusMap = @{
        Success  = @{ Icon = "[OK]"; Color = "Green" }
        Error    = @{ Icon = "[!!]"; Color = "Red" }
        Progress = @{ Icon = "[>>]"; Color = "Cyan" }
        Warning  = @{ Icon = "[! ]"; Color = "Yellow" }
        Info     = @{ Icon = "[i ]"; Color = "Gray" }
    }
    if ($statusMap.ContainsKey($StatusType)) {
        $status = $statusMap[$StatusType]
    } else {
        $status = $statusMap["Info"]
    }
    $formatted = "$($status.Icon) $Message"
    Write-ColorText $formatted $status.Color
}

# Check if JetBrainsMono Nerd Font is already installed.
# Searches both the system font registry (HKLM) and user-local font directory.
# Returns $true if found in either location to avoid redundant installs.
function Test-FontInstalled {
    param([string]$FontName = "JetBrainsMono Nerd Font")
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
         if (Get-ChildItem -Path $userFontPath -Filter "*JetBrainsMonoNerdFont*" -ErrorAction SilentlyContinue) {
             return $true
         }
    }

    return $false
}

# ========================================================================================
# Section 6: Backup and Restore
# ========================================================================================
# Creates timestamped backups of PuTTY registry settings and Windows Terminal
# settings.json before making any changes. Backups are stored in
# $env:USERPROFILE\.dotfiles-backup\<timestamp>\ with a metadata.json manifest.
# ========================================================================================

# Create a timestamped backup of current terminal settings
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

# Restore settings from a previous backup (interactive selection)
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
# Each function handles one installation task and can be run independently from
# the interactive menu. All functions follow the pattern:
#   1. Download/detect resources
#   2. Apply changes (with error handling)
#   3. Record the action via Add-Action for the summary
# ========================================================================================

# Download and install JetBrainsMono Nerd Font system-wide.
# Uses Shell.Application COM object (primary) with manual registry fallback.
# Installs to C:\Windows\Fonts so all users and applications can see the font.
function Install-NerdFont {
    try {
        Write-Host "Downloading JetBrainsMono Nerd Font..." -ForegroundColor Cyan
        
        New-Item -Path $TEMP_DIR -ItemType Directory -Force | Out-Null
        $zipFile = Join-Path $TEMP_DIR "JetBrainsMono.zip"

        Invoke-WebRequest -Uri $FONT_DOWNLOAD_URL -OutFile $zipFile
        Expand-Archive -Path $zipFile -DestinationPath $TEMP_DIR -Force

        $fontFiles = Get-ChildItem -Path $TEMP_DIR -Filter "*.ttf" -Recurse
        
        # Method 1: Shell.Application (Silent and Standard)
        $shell = New-Object -ComObject Shell.Application
        $fontsFolder = $shell.Namespace(0x14)  # Special Fonts folder
        
        foreach ($font in $fontFiles) {
            $destPath = "$env:SystemRoot\Fonts\$($font.Name)"
            
            if (Test-Path $destPath) {
                Write-Host "Skipping installed: $($font.Name)" -ForegroundColor Gray
            } else {
                Write-Host "Installing: $($font.Name)" -ForegroundColor Cyan
                $fontsFolder.CopyHere($font.FullName, 0x10)  # 0x10 = silent
                
                # Method 2: Manual Registry Fallback (System-Wide)
                try {
                    if (-not (Test-Path $destPath)) {
                        Copy-Item -Path $font.FullName -Destination $destPath -Force
                        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" -Name "$($font.Name) (TrueType)" -Value "$($font.Name)" -PropertyType String -Force | Out-Null
                    }
                } catch {
                    Write-Log "Registry method failed (ignoring if CopyHere worked): $_" "WARNING"
                }
            }
        }

        Remove-Item -Path $TEMP_DIR -Recurse -Force
        Add-Action "Installed JetBrainsMono Nerd Font"
        Write-Status "Nerd Font installed successfully" "Success"
    } catch {
        Write-Status "Font installation failed" "Error"
        Write-Log "Font install error: $_" "ERROR"
        if (Test-Path $TEMP_DIR) { Remove-Item $TEMP_DIR -Recurse -Force }
    }
}

# Configure Windows Terminal to use JetBrainsMono Nerd Font.
# Updates profiles.defaults.font.face (modern) and fontFace (legacy) in settings.json.
# Handles both stable and preview versions of Windows Terminal.
# This is critical because without the correct font, Nerd Font icons (used by
# starship prompt, eza, nvim) appear as empty boxes or question marks.
function Configure-WindowsTerminal {
    try {
        Write-Host "Configuring Windows Terminal..." -ForegroundColor Cyan
        Write-Log "Configuring WT as user: $env:USERNAME" "INFO"

        # Check for both Stable and Preview
        $packages = @(
            "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
            "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
        )

        $found = $false
        foreach ($settingsPath in $packages) {
            if (Test-Path $settingsPath) {
                Write-Host "Found settings at: $settingsPath" -ForegroundColor Gray
                $found = $true
                
                try {
                    $jsonContent = Get-Content $settingsPath -Raw
                    if ([string]::IsNullOrWhiteSpace($jsonContent)) {
                        Write-Status "Settings file empty: $settingsPath" "Warning"
                        continue
                    }

                    $settings = $jsonContent | ConvertFrom-Json

                    # Ensure structure exists
                    if (-not $settings.profiles) {
                        Write-Status "Invalid settings JSON (no profiles)" "Warning"
                        continue
                    }
                    if (-not $settings.profiles.defaults) {
                         $settings.profiles | Add-Member -MemberType NoteProperty -Name defaults -Value ([PSCustomObject]@{})
                    }

                    # 1. Modern: profiles.defaults.font.face
                    if (-not $settings.profiles.defaults.font) {
                        # Create font object if missing
                        $settings.profiles.defaults | Add-Member -MemberType NoteProperty -Name font -Value ([PSCustomObject]@{ face = "JetBrainsMono Nerd Font" })
                    } else {
                        # Update existing font object (preserve size/weight)
                        if ($settings.profiles.defaults.font -is [PSCustomObject]) {
                            if (-not $settings.profiles.defaults.font.PSObject.Properties.Match("face")) {
                                $settings.profiles.defaults.font | Add-Member -MemberType NoteProperty -Name face -Value "JetBrainsMono Nerd Font"
                            } else {
                                $settings.profiles.defaults.font.face = "JetBrainsMono Nerd Font"
                            }
                        } elseif ($settings.profiles.defaults.font -is [System.Collections.IDictionary]) {
                             $settings.profiles.defaults.font["face"] = "JetBrainsMono Nerd Font"
                        }
                    }

                    # 2. Legacy: profiles.defaults.fontFace (older versions)
                    try {
                        if ($settings.profiles.defaults -is [PSCustomObject]) {
                            if (-not $settings.profiles.defaults.PSObject.Properties.Match("fontFace")) {
                                $settings.profiles.defaults | Add-Member -MemberType NoteProperty -Name fontFace -Value "JetBrainsMono Nerd Font" -Force
                            } else {
                                $settings.profiles.defaults.fontFace = "JetBrainsMono Nerd Font"
                            }
                        } elseif ($settings.profiles.defaults.font -is [System.Collections.IDictionary]) {
                            $settings.profiles.defaults["fontFace"] = "JetBrainsMono Nerd Font"
                        }
                    } catch {
                        Write-Log "Legacy fontFace property not supported (using modern font.face instead)" "INFO"
                    }

                    # Save
                    $settings | ConvertTo-Json -Depth 100 | Set-Content $settingsPath -Encoding UTF8
                    Write-Status "Updated: $settingsPath" "Success"
                    Add-Action "Configured Windows Terminal ($settingsPath)"
                } catch {
                    Write-Status "Failed to update $settingsPath : $_" "Error"
                }
            }
        }

        if (-not $found) {
            Write-Status "Windows Terminal settings file not found" "Warning"
        }

    } catch {
        Write-Status "Windows Terminal config failed" "Error"
        Write-Log "WT config error: $_" "ERROR"
    }
}

# Configure PuTTY's Default Settings to use JetBrainsMono Nerd Font.
# IMPORTANT: This sets the "Default Settings" session in the registry, which is
# what KeePass uses when launching SSH connections. Without this, KeePass-launched
# PuTTY sessions show broken icons because they use the Default Settings profile.
function Configure-PuTTY {
    try {
        Write-Host "Configuring PuTTY Default Settings..." -ForegroundColor Cyan
        Write-Log "Configuring PuTTY as user: $env:USERNAME" "INFO"

        $regPath = "HKCU:\Software\SimonTatham\PuTTY\Sessions\Default%20Settings"
        
        # Ensure Default Settings key exists
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }

        Set-ItemProperty -Path $regPath -Name "Font" -Value "JetBrainsMono Nerd Font" -Type String
        Set-ItemProperty -Path $regPath -Name "FontHeight" -Value 12 -Type DWord
        Set-ItemProperty -Path $regPath -Name "FontIsBold" -Value 0 -Type DWord
        
        Add-Action "Configured PuTTY Default Settings"
        Write-Status "PuTTY Default Settings configured" "Success"
    } catch {
        Write-Status "PuTTY configuration failed" "Error"
        Write-Log "PuTTY config error: $_" "ERROR"
    }
}

# Install core developer tools via winget (Windows Package Manager).
# These mirror the tools installed by scripts/install.sh on Linux:
# neovim, git, ripgrep, fd, starship, eza, fastfetch.
# Note: tmux, bat, btop, lazygit, fzf are not included yet — they're either
# Linux-only or have limited Windows support.
function Install-CoreTools {
    try {
        Write-Host "Installing Core Developer Tools via Winget..." -ForegroundColor Cyan
        
        $tools = @(
            "Neovim.Neovim",
            "Git.Git",
            "BurntSushi.Ripgrep",
            "sharkdp.fd",
            "starship.starship",
            "eza-community.eza",
            "fastfetch-cli.fastfetch"
        )

        foreach ($tool in $tools) {
            Write-Status "Installing $tool..." "Progress"
            winget install --id $tool --silent --accept-package-agreements --accept-source-agreements | Out-Null
        }

        Add-Action "Installed Core Tools: $($tools -join ', ')"
        Write-Status "Core Tools installed successfully" "Success"
    } catch {
        Write-Status "Core Tools installation failed" "Error"
        Write-Log "Winget install error: $_" "ERROR"
    }
}

# Create symbolic links from the dotfiles repo into the Windows user home.
# Enables Git Bash (and WSL) to use the same dotfiles as Linux.
# Windows symlinks require Administrator privileges (unlike Linux).
# Also links Neovim config to $env:LOCALAPPDATA\nvim (Windows-native path).
function Symlink-Dotfiles {
    try {
        Write-Host "Symlinking dotfiles to User Home..." -ForegroundColor Cyan
        
        # 1. Determine where the dotfiles are
        $dotfilesDir = ""
        $userHome = $env:USERPROFILE
        
        if (Test-Path (Join-Path (Get-Location) "stow")) {
            $dotfilesDir = (Get-Location).Path
        } elseif (Test-Path (Join-Path $userHome "dotfiles\stow")) {
            $dotfilesDir = Join-Path $userHome "dotfiles"
        } else {
            # Auto-Clone Fallback
            $dotfilesDir = Join-Path $userHome "dotfiles"
            Write-Status "Dotfiles not found at $dotfilesDir. Cloning repository..." "Warning"
            
            if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
                Write-Status "Git not found. Installing via Winget..." "Progress"
                winget install --id Git.Git --silent --accept-package-agreements --accept-source-agreements | Out-Null
            }

            git clone "https://github.com/deey001/dotfiles.git" $dotfilesDir
            if (-not (Test-Path $dotfilesDir)) {
                throw "Failed to clone repository to $dotfilesDir"
            }
        }

        Write-Host "  Using Source: $dotfilesDir" -ForegroundColor Gray

        # 2. Link Individual Files
        $fileMap = @{
            ".bashrc"       = "stow\bash\.bashrc"
            ".bash_profile" = "stow\bash\.bash_profile"
            ".bash_aliases" = "stow\bash\.bash_aliases"
            ".blerc"        = "stow\bash\.blerc"
            ".tmux.conf"    = "stow\tmux\.tmux.conf"
            ".gitconfig"    = "stow\git\.gitconfig"
            ".inputrc"      = "stow\shell\.inputrc"
            ".common_shell" = "stow\shell\.common_shell"
        }

        foreach ($file in $fileMap.Keys) {
            $source = Join-Path $dotfilesDir $fileMap[$file]
            $target = Join-Path $userHome $file

            if (Test-Path $source) {
                if (Test-Path $target) {
                    $bak = "$target.bak"
                    if (Test-Path $bak) { Remove-Item $bak -Force }
                    Move-Item $target $bak -Force
                }
                New-Item -Path $target -ItemType SymbolLink -Value $source -Force | Out-Null
                Write-Log "Linked $file"
            }
        }

        # 3. Link .config Subdirectories
        $configSourceBase = Join-Path $dotfilesDir "stow\config\.config"
        $configTargetBase = Join-Path $userHome ".config"
        
        if (Test-Path $configSourceBase) {
            if (-not (Test-Path $configTargetBase)) {
                New-Item -Path $configTargetBase -ItemType Directory -Force | Out-Null
            }
            
            Get-ChildItem $configSourceBase | ForEach-Object {
                $itemSource = $_.FullName
                $itemTarget = Join-Path $configTargetBase $_.Name
                
                if (Test-Path $itemTarget) {
                    $bak = "$itemTarget.bak"
                    if (Test-Path $bak) { 
                        if ($_.PSIsContainer) { Remove-Item $bak -Recurse -Force } else { Remove-Item $bak -Force }
                    }
                    Move-Item $itemTarget $bak -Force
                }
                New-Item -Path $itemTarget -ItemType SymbolLink -Value $itemSource -Force | Out-Null
            }
        }

        # 4. Neovim AppData Link
        $nvimSource = Join-Path $configSourceBase "nvim"
        $nvimTarget = Join-Path $env:LOCALAPPDATA "nvim"
        if (Test-Path $nvimSource) {
            if (Test-Path $nvimTarget) {
                $bak = Join-Path $env:LOCALAPPDATA "nvim.bak"
                if (Test-Path $bak) { Remove-Item $bak -Recurse -Force }
                Move-Item $nvimTarget $bak -Force
            }
            New-Item -Path $nvimTarget -ItemType SymbolLink -Value $nvimSource -Force | Out-Null
        }

        Add-Action "Symlinked all dotfiles successfully"
        Write-Status "Dotfiles symlinked successfully" "Success"
    } catch {
        Write-Status "Symlinking failed: $($_.Exception.Message)" "Error"
        Write-Log "Symlink error: $_" "ERROR"
    }
}

# ========================================================================================
# Section 8: Summary and Remote Guidance
# ========================================================================================
# Save-InstallationSummary: Writes the action log and summary to Documents/ folder
# Install-RemoteDotfiles: Shows the one-liner to install dotfiles on Linux servers
# ========================================================================================

# Save the installation log and a human-readable summary to the Documents folder
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

# Display the one-liner for installing dotfiles on remote Linux servers.
# This bridges the Windows setup to the Linux setup workflow.
function Install-RemoteDotfiles {
    Write-ColorText "`nREMOTE SERVER SETUP" "Cyan"
    Write-Host "Connect to your server, then run this one-liner:"
    Write-ColorText "curl -fsSL https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.sh | bash" "Yellow"

    $launch = Read-Host "`nLaunch Windows Terminal now? (y/n)"
    if ($launch -match "^[Yy]") {
        Start-Process wt.exe
    }
}

# ========================================================================================
# Section 9: Interactive Menu and Main Loop
# ========================================================================================
# Chris Titus-style menu: numbered choices, color-coded, with descriptions.
# Options 1-4 are individual tasks, 5 is "full local setup", 6 is symlinks,
# 7-8 bridge to remote server setup, 9-10 handle reset/restore.
# ========================================================================================

# Configure PowerShell Profiles to use Starship and clean up old errors.
function Configure-PowerShell {
    try {
        Write-Host "Cleaning and Configuring PowerShell Profiles..." -ForegroundColor Cyan
        
        # We target both Windows PowerShell (5.1) and PowerShell (7+) profiles
        $profilePaths = @(
            "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1",
            "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1",
            $PROFILE # The current session's profile
        ) | Select-Object -Unique

        $starshipLine = 'starship init powershell | Invoke-Expression'
        
        foreach ($path in $profilePaths) {
            if (Test-Path $path) {
                Write-Host "  Processing: $path" -ForegroundColor Gray
                $content = Get-Content $path
                
                # Aggressively filter out any lines containing starship, oh-my-posh, or malformed commands
                $newContent = $content | Where-Object { 
                    $_ -notmatch "starship" -and 
                    $_ -notmatch "oh-my-posh" -and
                    $_ -notmatch ".omp.json" -and
                    $_ -notmatch "Invoke-Expression" -and # Removing all IEX lines to be safe
                    -not [string]::IsNullOrWhiteSpace($_)
                }
                
                # Add a clean Starship initialization
                $finalContent = @(
                    "# Added by Dotfiles Setup ($BACKUP_TIMESTAMP)",
                    $starshipLine
                )
                if ($newContent) { $finalContent = $newContent + $finalContent }
                
                $finalContent | Set-Content $path -Force
                Write-Log "Cleaned profile: $path"
            } else {
                # If it doesn't exist, create it cleanly
                $dir = Split-Path -Parent $path
                if (-not (Test-Path $dir)) { New-Item $dir -ItemType Directory -Force | Out-Null }
                "# Added by Dotfiles Setup`n$starshipLine" | Set-Content $path -Force
                Write-Log "Created new profile: $path"
            }
        }

        Add-Action "Configured all PowerShell Profiles with Starship"
        Write-Status "All PowerShell Profiles cleaned and configured" "Success"
    } catch {
        Write-Status "PowerShell configuration failed: $($_.Exception.Message)" "Error"
    }
}

# Display the interactive menu — called in a loop by Main
function Show-Menu {
    Clear-Host
    Write-ColorText "╔══════════════════════════════════════════════════╗" "Cyan"
    Write-ColorText "║          DOTFILES WINDOWS SETUP TOOL             ║" "Cyan"
    Write-ColorText "║      Nerd Fonts + Terminal Configuration         ║" "Cyan"
    Write-ColorText "╚══════════════════════════════════════════════════╝" "Cyan"
    Write-Host ""
    Write-ColorText " [1] Install JetBrainsMono Nerd Font (System-wide)" "Yellow"
    Write-ColorText " [2] Set Nerd Font in Windows Terminal (Default Profile)" "Yellow"
    Write-ColorText " [3] Set Nerd Font in PuTTY (Default Settings for KeePass)" "Yellow"
    Write-ColorText " [4] Install Core Developer Tools via Winget (Nvim, Git, etc)" "Yellow"
    Write-Host "     (Installs Neovim, Git, Ripgrep, Fd, Starship, Eza, Fastfetch)" -ForegroundColor Gray
    Write-ColorText " [5] Configure PowerShell Profile (Starship + Cleanup)" "Yellow"
    Write-Host "     (Fixes startup errors and sets up the modern prompt)" -ForegroundColor Gray
    Write-ColorText " [6] Full Local Setup (Run tasks 1-5 automatically)" "Green"
    Write-ColorText " [7] Symlink Dotfiles to Windows Home (for Git Bash/WSL)" "Green"
    Write-Host "     (Creates links for .bashrc, .tmux.conf, .config, etc)" -ForegroundColor Gray
    Write-Host ""
    Write-ColorText " [8] Install dotfiles on remote server (guide)" "Yellow"
    Write-ColorText " [9] Complete Workflow (Tasks 1-8 in sequence)" "Yellow"
    Write-ColorText " [10] Reset / Remove Configuration (Restore from backup)" "Yellow"
    Write-ColorText " [11] Restore from Backup" "Yellow"
    Write-ColorText " [0] Exit" "Red"
    Write-Host ""
    Write-Host "Enter choice: " -NoNewline
}

# Main entry point — creates a backup, then loops the interactive menu until exit.
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
                "4" { Install-CoreTools }
                "5" { Configure-PowerShell }
                "6" {
                    Install-NerdFont
                    Configure-WindowsTerminal
                    Configure-PuTTY
                    Install-CoreTools
                    Configure-PowerShell
                }
                "7" { Symlink-Dotfiles }
                "8" { Install-RemoteDotfiles }
                "9" {
                    Install-NerdFont
                    Configure-WindowsTerminal
                    Configure-PuTTY
                    Install-CoreTools
                    Configure-PowerShell
                    Symlink-Dotfiles
                    Install-RemoteDotfiles
                }
                "10" {
                    $confirm = Read-Host "Reset all settings? This will restore from latest backup (y/n)"
                    if ($confirm -match "^[Yy]") { Restore-Settings }
                }
                "11" { Restore-Settings }
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