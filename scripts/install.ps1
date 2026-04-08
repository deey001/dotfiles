# VERSION: 1.0.7 (FIX-ELEVATION-PATH)
# ========================================================================================
# install.ps1 — Dotfiles Windows Setup Tool
# ========================================================================================
#
# DESCRIPTION
#   Interactive menu-driven installer for the dotfiles repository on Windows.
#   Handles font installation, Windows Terminal theming, PuTTY configuration,
#   core tool installation via winget, PowerShell profile setup, CMD prompt
#   theming via Clink/Starship, and symlink creation for tracked dotfiles.
#
# USAGE
#   Remote (one-liner, recommended):
#     irm https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.ps1 | iex
#   Local clone:
#     Set-ExecutionPolicy Bypass -Scope Process -Force
#     .\scripts\install.ps1
#
# PREREQUISITES
#   • Windows 10 / 11
#   • PowerShell 5.1+ (script auto-upgrades to PS7 if needed)
#   • Administrator privileges (auto-elevates via UAC if not already elevated)
#   • winget (pre-installed on Windows 11; available via App Installer on Win10)
#   • Internet access for font download and winget packages
#
# AUTO-ELEVATION
#   If not running as Administrator the script re-launches itself elevated via
#   UAC (Start-Process -Verb RunAs).
#   • When run from a local clone ($PSCommandPath is set) the SAME script file
#     is relaunched — no download required.
#   • When run via irm|iex (in-memory) the script is downloaded to %TEMP% for
#     the elevated launch.
#   In both cases the resolved dotfiles repo path is passed as -DotfilesDir so
#   the elevated process can find windows\settings.json and the PS profile.
#   Admin is required for: creating SymbolicLinks, installing fonts system-wide,
#   and writing to protected registry keys.
#
# EXECUTION ORDER (Full Workflow — option A)
#   1.  Auto-backup existing settings
#   2.  Install JetBrainsMono Nerd Font
#   3.  Configure Windows Terminal (font + Catppuccin Mocha theme)
#   4.  Configure PuTTY font
#   5.  Install core CLI tools via winget
#   6.  Configure PowerShell profiles (PS5 + PS7)
#   7.  Configure CMD prompt via Clink + Starship
#   8.  Symlink dotfiles into %USERPROFILE%
#   9.  Display remote server setup instructions
#
# ========================================================================================

# ── Script Parameters ───────────────────────────────────────────────────────────
# param() MUST be the first executable statement in the script (after comments).
#
# -DotfilesDir:
#   Absolute path to the dotfiles repository root.  Passed automatically when the
#   script re-launches itself elevated via UAC or switches from PS5 to PS7.
#
#   Why this is needed:
#     When the script triggers UAC elevation it must re-launch as a new process.
#     If running from a local clone the relaunched process receives the original
#     file path (via $PSCommandPath).  If running via irm|iex (in-memory) there
#     is no file path — the script is downloaded to %TEMP% for the relaunch.
#     In either case $PSScriptRoot in the elevated process points somewhere other
#     than the dotfiles repo root, so Get-DotfilesDir cannot auto-detect the path.
#     Passing -DotfilesDir explicitly preserves the correct path across all
#     relaunch scenarios without any user interaction.
#
# -Theme:
#   Name of the colour theme to deploy (without the .ps1 extension).
#   Must match a file under themes/windows/<Theme>.ps1 in the repo.
#   Defaults to "catppuccin-mocha".  Pass a different value to switch themes:
#     .\install.ps1 -Theme catppuccin-latte
#   When running via irm|iex the default (catppuccin-mocha) is always used.
[CmdletBinding()]
param(
    [string]$DotfilesDir = "",
    [string]$Theme       = "catppuccin-mocha"
)

# Force TLS 1.2 for all web requests made in this session.
# PowerShell 5 defaults to TLS 1.0 which many modern servers (GitHub, etc.) reject.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ── Test-AdminPrivileges ────────────────────────────────────────────────────────
# Returns $true if the current process is running with Administrator privileges.
#
# Why this is needed:
#   Several operations in this script require elevation:
#     • New-Item -ItemType SymbolicLink  — requires SeCreateSymbolicLinkPrivilege
#       (granted to Administrators by default; standard users need Developer Mode).
#     • Shell.Namespace(0x14) font install — writes to %SystemRoot%\Fonts and the
#       HKLM font registry key, both of which are Administrator-only.
#     • Registry keys under HKLM (if any future step writes there).
#   We check early and auto-re-launch via UAC rather than failing mid-install.
#
# What it modifies: nothing — pure query, no side effects.
# Prerequisites: none — uses only .NET BCL types available in all PS versions.
function Test-AdminPrivileges {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ── Auto-Elevation Block ────────────────────────────────────────────────────────
# If not running as Administrator, re-launch elevated via UAC.
#
# Strategy (two cases):
#   Local clone  ($PSCommandPath is a real file):
#     Relaunch the EXACT same script file elevated.  This avoids downloading a
#     fresh copy and, crucially, lets us pass -DotfilesDir so the elevated process
#     finds the repo without any detection logic.
#
#   In-memory (irm | iex — $PSCommandPath is empty):
#     Download the script to %TEMP% and relaunch that.  We cannot pass
#     -DotfilesDir because there is no local clone yet; Symlink-Dotfiles will
#     git-clone the repo into $env:USERPROFILE\dotfiles on demand.
#
# The -DotfilesDir argument propagates the resolved repo root so the elevated
# process sets $script:dotfilesDir correctly and finds windows\settings.json and
# windows\Microsoft.PowerShell_profile.ps1 without falling back to stubs.
if (-not (Test-AdminPrivileges)) {
    Write-Host "█▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀█" -ForegroundColor Red
    Write-Host "█  ADMINISTRATOR PRIVILEGES REQUIRED - AUTO-ELEVATING    █" -ForegroundColor Yellow
    Write-Host "█▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄█" -ForegroundColor Red
    Write-Host "`nPlease accept the UAC prompt to continue..." -ForegroundColor Gray

    try {
        # Detect the repo root NOW, before we lose context in the elevated process.
        $preElevateDir = $null
        if ($DotfilesDir -and (Test-Path (Join-Path $DotfilesDir "stow"))) {
            $preElevateDir = $DotfilesDir          # already passed from a prior relaunch
        } elseif ($PSCommandPath -and (Test-Path $PSCommandPath)) {
            $candidate = Split-Path (Split-Path $PSCommandPath -Parent) -Parent
            if (Test-Path (Join-Path $candidate "stow")) { $preElevateDir = $candidate }
        }

        # Decide which script file to run elevated.
        # Prefer relaunching the current local file to avoid stale CDN copies.
        $scriptToRun = if ($PSCommandPath -and (Test-Path $PSCommandPath)) {
            $PSCommandPath
        } else {
            $TempScript = "$env:TEMP\DotfilesSetup.ps1"
            $v = Get-Random
            # Write with UTF-8 BOM so PS5 reads the file correctly.
            # Invoke-WebRequest -OutFile writes raw bytes (no BOM) which PS5 misinterprets as Windows-1252.
            $response = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.ps1?v=$v" `
                -UseBasicParsing
            [System.IO.File]::WriteAllText($TempScript, $response.Content, [System.Text.UTF8Encoding]::new($true))
            $TempScript
        }

        # Build argument list; append -DotfilesDir and -Theme only when set.
        $relaunchArgs = @("-NoExit", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$scriptToRun`"")
        if ($preElevateDir) { $relaunchArgs += "-DotfilesDir", "`"$preElevateDir`"" }
        if ($Theme -and $Theme -ne "catppuccin-mocha") { $relaunchArgs += "-Theme", "`"$Theme`"" }

        # Prefer pwsh.exe (PS7) for the elevated process; fall back to powershell.exe (PS5) if not installed.
        # PS7 handles UTF-8 correctly and supports all features used in this script.
        $shell = if (Test-Path "C:\Program Files\PowerShell\7\pwsh.exe") { "C:\Program Files\PowerShell\7\pwsh.exe" } else { "powershell" }
        Start-Process $shell -Verb RunAs -ArgumentList $relaunchArgs
    } catch {
        Write-Host "`n[ERROR] Failed to prepare auto-elevation: $_" -ForegroundColor Red
    }
    exit
}

# ── PowerShell Version Check ────────────────────────────────────────────────────
# Ensure we are running on PowerShell 7+.  PS 5 lacks several features used here
# (e.g. improved ConvertTo-Json depth handling) and its UTF-8 output is less
# reliable in some terminal hosts.
#
# If PS 7 is not present, winget installs it silently, then this script re-
# launches itself inside pwsh.exe (the PS7 executable) so all subsequent code
# runs under the correct version.
# -DotfilesDir is forwarded so the relaunched PS7 process also finds the repo.
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host "Detected PowerShell $($PSVersionTable.PSVersion.Major). Installing PowerShell 7..." -ForegroundColor Yellow
    winget install --id Microsoft.PowerShell --silent --accept-package-agreements --accept-source-agreements | Out-Null

    $pwsh7Path = "C:\Program Files\PowerShell\7\pwsh.exe"
    if (Test-Path $pwsh7Path) {
        # Resolve dotfiles dir before relaunching so we can pass it forward.
        $preUpgradeDir = if ($DotfilesDir -and (Test-Path (Join-Path $DotfilesDir "stow"))) {
            $DotfilesDir
        } elseif ($PSCommandPath -and (Test-Path $PSCommandPath)) {
            $candidate = Split-Path (Split-Path $PSCommandPath -Parent) -Parent
            if (Test-Path (Join-Path $candidate "stow")) { $candidate } else { $null }
        } else { $null }

        $scriptToRun = if ($PSCommandPath -and (Test-Path $PSCommandPath)) {
            $PSCommandPath
        } else {
            $TempScript = "$env:TEMP\DotfilesSetup.ps1"
            $v = Get-Random
            # Write with UTF-8 BOM so PS5 reads the file correctly (see elevation block above for rationale).
            $response = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.ps1?v=$v" `
                -UseBasicParsing
            [System.IO.File]::WriteAllText($TempScript, $response.Content, [System.Text.UTF8Encoding]::new($true))
            $TempScript
        }

        $relaunchArgs = @("-NoExit", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$scriptToRun`"")
        if ($preUpgradeDir) { $relaunchArgs += "-DotfilesDir", "`"$preUpgradeDir`"" }
        if ($Theme -and $Theme -ne "catppuccin-mocha") { $relaunchArgs += "-Theme", "`"$Theme`"" }

        Start-Process -FilePath $pwsh7Path -Verb RunAs -ArgumentList $relaunchArgs
        exit 0
    }
}

# ── Console Encoding & Colour Support ──────────────────────────────────────────
# Force UTF-8 output so box-drawing characters and emoji render correctly in
# Windows Terminal and modern conhost.  If the console doesn't support UTF-8
# (older conhost, redirected output) we fall back gracefully and disable ANSI
# colour sequences, using Write-Host's -ForegroundColor parameter instead.
try {
    $script:UseColors = $true
} catch {
    $script:UseColors = $false
}

# ── Global Constants & Paths ────────────────────────────────────────────────────
# Centralised here so every function references the same values and changes only
# need to happen in one place.

$FONT_DOWNLOAD_URL = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
$TEMP_DIR          = "$env:TEMP\nerd-fonts-install"         # Scratch dir for font zip extraction
$BACKUP_DIR        = "$env:USERPROFILE\.dotfiles-backup"     # Root for all timestamped backups
$BACKUP_TIMESTAMP  = Get-Date -Format "yyyyMMdd_HHmmss"      # Unique suffix for this run's backup
$LOG_FILE          = "$env:USERPROFILE\Documents\dotfiles-install-log-$BACKUP_TIMESTAMP.txt"

# Script-scope arrays for accumulating log messages and a human-readable action
# summary that can be written to $LOG_FILE at the end of the session.
$script:InstallationLog  = @()
$script:ActionsPerformed = @()

# ── Get-DotfilesDir ─────────────────────────────────────────────────────────────
# Resolves the absolute path to the dotfiles repository root and returns it, or
# $null if the repo cannot be found.
#
# Detection order (first match wins):
#   1. $DotfilesDir script parameter — set when the script re-launches itself
#      elevated (via UAC) or upgrades to PS7.  This is the only reliable path
#      in those scenarios because $PSScriptRoot in the re-launched process points
#      to %TEMP% or C:\Program Files\PowerShell\7, not the repo.
#   2. $PSScriptRoot parent — works when running directly from a local clone
#      (e.g. .\scripts\install.ps1).  PSScriptRoot = ..\scripts; parent = repo root.
#      Validated by checking for the stow\ sub-directory (canonical repo marker).
#   3. $env:USERPROFILE\dotfiles — default clone location assumed by Symlink-
#      Dotfiles' auto-clone step.  Checked as last resort.
#
# What it modifies: nothing — pure resolver, no side effects.
# What can go wrong: returns $null if none of the three candidates exist; every
#   caller that uses the result must guard with `if ($script:dotfilesDir)`.
function Get-DotfilesDir {
    # 1. Explicit parameter (passed by the re-launch / elevation logic)
    if ($DotfilesDir -and (Test-Path (Join-Path $DotfilesDir "stow"))) { return $DotfilesDir }

    # 2. $PSScriptRoot — works for local clone direct invocation
    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
    $candidate = Split-Path $scriptDir -Parent
    if (Test-Path (Join-Path $candidate "stow")) { return $candidate }

    # 3. Default clone location
    $candidate = Join-Path $env:USERPROFILE "dotfiles"
    if (Test-Path $candidate) { return $candidate }

    return $null
}
$script:dotfilesDir = Get-DotfilesDir

# ── ANSI Colour Map ─────────────────────────────────────────────────────────────
# Escape sequences for 256-colour terminals (Windows Terminal, modern conhost).
# Used by Write-ColorText when $script:UseColors is $true; ignored otherwise.
$colors = @{
    Reset   = "`e[0m"; Red = "`e[91m"; Green = "`e[92m"; Yellow = "`e[93m"
    Cyan    = "`e[96m"; Magenta = "`e[95m"; Gray = "`e[90m"; White = "`e[97m"
}

# ── Write-Log ───────────────────────────────────────────────────────────────────
# Appends a timestamped entry to the in-memory $script:InstallationLog array.
# The array is flushed to $LOG_FILE at the end of the session so the user has
# a full audit trail without verbose console output during the run.
#
# Parameters:
#   $Message – Human-readable description of the event.
#   $Level   – Severity/category tag (INFO, ACTION, OUTPUT, ERROR).  Defaults to INFO.
#
# What it modifies: $script:InstallationLog (in-memory only during the run).
# What can go wrong: nothing — array append cannot fail.
function Write-Log {
    param([string]$Message, $Level = "INFO")
    $script:InstallationLog += "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message"
}

# ── Add-Action ──────────────────────────────────────────────────────────────────
# Records a completed action in the $script:ActionsPerformed summary array AND
# logs it at the ACTION level.  The summary is printed at session end so the
# user can see exactly what changed without scrolling through all log output.
#
# Parameters:
#   $Action – Short past-tense description (e.g. "Installed JetBrainsMono Nerd Font").
#
# What it modifies: $script:ActionsPerformed, $script:InstallationLog.
function Add-Action { param($Action) $script:ActionsPerformed += $Action; Write-Log $Action "ACTION" }

# ── Write-ColorText ─────────────────────────────────────────────────────────────
# Logs a message and writes it to the console with colour.
#
# Colour strategy:
#   • If $script:UseColors is $true (UTF-8 console detected at startup) output
#     is wrapped in raw ANSI escape codes from the $colors map — this produces
#     the richest colours in Windows Terminal.
#   • Otherwise falls back to Write-Host -ForegroundColor, which works in older
#     conhost and in redirected/piped output scenarios where ANSI codes would
#     appear as literal characters.
#
# Parameters:
#   $Message – Text to display.
#   $Color   – Key into the $colors hashtable (e.g. "Green", "Red", "Cyan").
#
# What can go wrong: if $Color is not a valid key in $colors the ANSI branch
#   produces garbled output; always use one of the defined key names.
function Write-ColorText {
    param($Message, $Color)
    Write-Log $Message "OUTPUT"
    if ($script:UseColors) { Write-Host "$($colors[$Color])$Message$($colors.Reset)" } else { Write-Host $Message -ForegroundColor $Color }
}

# ── Write-Status ────────────────────────────────────────────────────────────────
# Displays a status line with a bracketed icon and colour appropriate to the
# status type, then delegates to Write-ColorText (which also logs the message).
#
# Status types and their visual indicators:
#   Success  → [OK]  green    — operation completed without error
#   Error    → [!!]  red      — operation failed; check the log for details
#   Progress → [>>]  cyan     — operation is in progress
#   Warning  → [! ]  yellow   — operation completed with caveats
#   Info     → [i ]  gray     — informational, no action required
#
# Parameters:
#   $Message    – Description of the event.
#   $StatusType – One of the five keys above.
#
# What can go wrong: unknown $StatusType falls through to the Info style — safe
#   but may mislead; always use one of the five defined types.
function Write-Status {
    param($Message, $StatusType)
    $map = @{ Success = @{I='[OK]';C='Green'}; Error = @{I='[!!]';C='Red'}; Progress = @{I='[>>]';C='Cyan'}; Warning = @{I='[! ]';C='Yellow'}; Info = @{I='[i ]';C='Gray'} }
    $s = $map[$StatusType]; if (-not $s) { $s = $map['Info'] }
    Write-ColorText "$($s.I) $Message" $s.C
}

# ── Backup-Settings ─────────────────────────────────────────────────────────────
# Creates a timestamped snapshot of user settings that will be modified by this
# script, so they can be restored manually if something goes wrong.
#
# What it backs up:
#   • Windows Terminal settings.json — because Configure-WindowsTerminal merges
#     new properties into this file and the merge is not easily reversible.
#
# Where backups are stored:
#   $env:USERPROFILE\.dotfiles-backup\<YYYYMMDD_HHmmss>\
#   A new subdirectory is created for each script run using $BACKUP_TIMESTAMP,
#   so multiple runs produce independent snapshots that never overwrite each other.
#
# What can go wrong:
#   If the backup directory cannot be created (e.g. disk full, permissions) the
#   catch block logs the error and continues — a failed backup should not abort
#   the install.
#
# Prerequisites: $BACKUP_DIR and $BACKUP_TIMESTAMP must be set (set at script scope).
function Backup-Settings {
    try {
        $timestampDir = Join-Path $BACKUP_DIR $BACKUP_TIMESTAMP
        New-Item -Path $timestampDir -ItemType Directory -Force | Out-Null
        $wtPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        if (Test-Path $wtPath) { Copy-Item $wtPath (Join-Path $timestampDir "settings.json") }
        Add-Action "Backup created at $timestampDir"
    } catch { Write-Log "Backup failed: $_" "ERROR" }
}

# ── Install-NerdFont ────────────────────────────────────────────────────────────
# Downloads and installs JetBrainsMono Nerd Font for all users via the Windows
# Shell COM object, then cleans up the temporary download directory.
#
# How the COM font install works:
#   Shell.Namespace(0x14) returns a reference to the system Fonts folder as a
#   Shell folder object.  Calling .CopyHere() on a .ttf file triggers the same
#   code path as dragging a font file into the Fonts folder in Explorer — Windows
#   copies it to %SystemRoot%\Fonts and registers it in the registry automatically.
#   The 0x10 flag suppresses the "overwrite?" progress dialog.
#
# Why check for existing fonts before copying:
#   CopyHere with 0x10 would silently overwrite, but checking first avoids the
#   overhead of re-registering fonts that are already present (faster re-runs).
#
# What it modifies:
#   • %SystemRoot%\Fonts — copies *.ttf files extracted from the zip
#   • HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts — font registry
#
# What can go wrong:
#   • Download failure (no internet, GitHub rate-limit) — caught, logged, reported.
#   • CopyHere is asynchronous internally, but Expand-Archive blocks long enough
#     that fonts are fully extracted before the copy loop starts in practice.
#
# Prerequisites: Administrator privileges (font registry is HKLM).
function Install-NerdFont {
    try {
        Write-Host "Installing Nerd Font..." -ForegroundColor Cyan
        New-Item $TEMP_DIR -ItemType Directory -Force | Out-Null
        $zip = Join-Path $TEMP_DIR "font.zip"
        Invoke-WebRequest -Uri $FONT_DOWNLOAD_URL -OutFile $zip
        Expand-Archive $zip $TEMP_DIR -Force
        $shell = New-Object -ComObject Shell.Application
        $fontsFolder = $shell.Namespace(0x14)   # 0x14 = CSIDL_FONTS — the system Fonts folder
        Get-ChildItem $TEMP_DIR -Filter "*.ttf" -Recurse | ForEach-Object {
            # Skip fonts that are already installed to avoid unnecessary re-registration.
            if (-not (Test-Path "$env:SystemRoot\Fonts\$($_.Name)")) {
                $fontsFolder.CopyHere($_.FullName, 0x10)   # 0x10 = suppress progress dialogs
            }
        }
        Remove-Item $TEMP_DIR -Recurse -Force
        Add-Action "Installed JetBrainsMono Nerd Font"
        Write-Status "Nerd Font installed" "Success"
    } catch { Write-Status "Font failed: $_" "Error" }
}

# ── Configure-WindowsTerminal ───────────────────────────────────────────────────
# Merges dotfiles repository settings into the live Windows Terminal settings.json,
# setting the default font to JetBrainsMono Nerd Font and the colour scheme to
# Catppuccin Mocha.  If the repo's windows\settings.json exists, its colour
# schemes array is also merged in (additive — existing schemes are preserved).
#
# How JSON merging works:
#   PowerShell's ConvertFrom-Json deserialises the JSON into a PSCustomObject.
#   Add-Member -Force is used to set (or overwrite) specific properties on the
#   nested object graph without touching unrelated settings.  The final object is
#   re-serialised with ConvertTo-Json -Depth 100 to preserve deep nesting.
#
# What properties are set:
#   profiles.defaults.font.face   → "JetBrainsMono Nerd Font"
#   profiles.defaults.colorScheme → "Catppuccin Mocha"
#   schemes[]                     → any schemes from repo settings.json not already
#                                   present (matched by .name property)
#
# What can go wrong:
#   • settings.json not found — Windows Terminal may not be installed or has never
#     been opened (the file is created on first launch).  Reported as a warning.
#   • Malformed existing JSON — ConvertFrom-Json throws; caught and reported.
#   • File locked by Windows Terminal — Set-Content fails; caught and reported.
#
# Prerequisites: Windows Terminal must be installed; $script:dotfilesDir should be
#   set for repo-side colour scheme injection to work.
function Configure-WindowsTerminal {
    try {
        Write-Host "Configuring Windows Terminal..." -ForegroundColor Cyan
        $wtPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

        if (-not (Test-Path $wtPath)) {
            Write-Status "Windows Terminal settings.json not found - is Windows Terminal installed?" "Warning"
            return
        }

        # Catppuccin Mocha colour scheme — embedded so it is always applied even
        # when the repo clone is not available.  This is the single source of truth
        # for the Windows Terminal colour scheme; windows/settings.json in the repo
        # carries the same values but is not required.
        $catppuccinMocha = [PSCustomObject]@{
            name                = "Catppuccin Mocha"
            background          = "#1E1E2E"
            foreground          = "#CDD6F4"
            black               = "#45475A"
            red                 = "#F38BA8"
            green               = "#A6E3A1"
            yellow              = "#F9E2AF"
            blue                = "#89B4FA"
            purple              = "#F5C2E7"
            cyan                = "#94E2D5"
            white               = "#BAC2DE"
            brightBlack         = "#585B70"
            brightRed           = "#F38BA8"
            brightGreen         = "#A6E3A1"
            brightYellow        = "#F9E2AF"
            brightBlue          = "#89B4FA"
            brightPurple        = "#F5C2E7"
            brightCyan          = "#94E2D5"
            brightWhite         = "#A6ADC8"
            cursorColor         = "#F5E0DC"
            selectionBackground = "#585B70"
        }

        $existing = Get-Content $wtPath -Raw | ConvertFrom-Json

        # Ensure nested objects exist before setting properties.
        if (-not $existing.profiles) {
            $existing | Add-Member NoteProperty profiles ([PSCustomObject]@{}) -Force
        }
        if (-not $existing.profiles.defaults) {
            $existing.profiles | Add-Member NoteProperty defaults ([PSCustomObject]@{}) -Force
        }
        if (-not $existing.profiles.defaults.font) {
            $existing.profiles.defaults | Add-Member NoteProperty font ([PSCustomObject]@{}) -Force
        }

        # Apply font and colour scheme — always, regardless of whether the repo is present.
        $existing.profiles.defaults.font | Add-Member NoteProperty face "JetBrainsMono Nerd Font" -Force
        $existing.profiles.defaults | Add-Member NoteProperty colorScheme "Catppuccin Mocha" -Force

        # Merge colour schemes — additive only; never remove user-added schemes.
        if (-not $existing.schemes) {
            $existing | Add-Member NoteProperty schemes @() -Force
        }
        $schemeExists = $existing.schemes | Where-Object { $_.name -eq "Catppuccin Mocha" }
        if (-not $schemeExists) { $existing.schemes += $catppuccinMocha }

        # If the repo is available, also merge any additional schemes it defines.
        $repoSettings = if ($script:dotfilesDir) { Join-Path $script:dotfilesDir "windows\settings.json" } else { $null }
        if ($repoSettings -and (Test-Path $repoSettings)) {
            $repo = Get-Content $repoSettings -Raw | ConvertFrom-Json
            foreach ($scheme in $repo.schemes) {
                $exists = $existing.schemes | Where-Object { $_.name -eq $scheme.name }
                if (-not $exists) { $existing.schemes += $scheme }
            }
        } else {
            Write-Status "Repo windows/settings.json not found - using embedded scheme" "Info"
        }

        $existing | ConvertTo-Json -Depth 100 | Set-Content $wtPath -Encoding UTF8
        Write-Status "Windows Terminal configured (font + Catppuccin Mocha)" "Success"
    } catch { Write-Status "WT config failed: $_" "Error" }
}

# ── Configure-PuTTY ─────────────────────────────────────────────────────────────
# Writes font settings into PuTTY's "Default Settings" registry key so that new
# sessions inherit the Nerd Font without manual GUI configuration.
#
# Which registry keys are set:
#   HKCU:\Software\SimonTatham\PuTTY\Sessions\Default%20Settings
#     Font       (REG_SZ)    → "JetBrainsMono Nerd Font"
#     FontHeight (REG_DWORD) → 12
#
# Why HKCU, not HKLM:
#   PuTTY stores all settings per-user under HKCU.  Writing to HKCU does not
#   require Administrator rights, but this function runs after elevation anyway.
#
# Why "Default%20Settings" (URL-encoded space):
#   PuTTY uses URL-encoded session names as registry key names; the built-in
#   default session is literally called "Default Settings" and stored URL-encoded.
#
# What can go wrong:
#   • PuTTY is not installed — the registry key won't exist.  New-Item -Force
#     creates it harmlessly; PuTTY will read these values when eventually installed.
#   • Set-ItemProperty fails on an invalid path — caught and reported.
function Configure-PuTTY {
    try {
        $reg = "HKCU:\Software\SimonTatham\PuTTY\Sessions\Default%20Settings"
        if (-not (Test-Path $reg)) { New-Item $reg -Force | Out-Null }
        Set-ItemProperty $reg -Name "Font" -Value "JetBrainsMono Nerd Font"
        Set-ItemProperty $reg -Name "FontHeight" -Value 12
        Write-Status "PuTTY configured" "Success"
    } catch { Write-Status "PuTTY failed: $_" "Error" }
}

# ── Install-CoreTools ───────────────────────────────────────────────────────────
# Installs a curated set of CLI tools via winget, the Windows Package Manager.
# Each tool is installed silently with auto-accepted license agreements so the
# install can run unattended.
#
# Tool list and purpose:
#   Neovim.Neovim            – Modern Vim-compatible modal text editor
#   Git.Git                  – Distributed version control system
#   BurntSushi.Ripgrep       – Extremely fast regex file search (rg)
#   sharkdp.fd               – User-friendly alternative to `find`
#   starship.starship         – Cross-shell prompt (used by PS, CMD, WSL bash/zsh)
#   eza-community.eza        – Modern replacement for `ls` with colour + icons
#   fastfetch-cli.fastfetch  – Fast system information display (neofetch successor)
#   sharkdp.bat              – Better `cat` with syntax highlighting (bat)
#   zig.zig                  – Zig compiler; provides a C compiler for Neovim
#                              Treesitter parser compilation (the lightest option)
#   chrisant996.Clink        – Readline extension for cmd.exe; required for the
#                              Starship CMD prompt (Configure-CMD)
#
# NOTE: tmux, ble.sh, and atuin are Linux/macOS tools and are NOT installed here.
#   Use WSL and run the Linux installer for those tools inside your WSL distro.
#
# What it modifies:
#   Winget installs each tool to its default location (%ProgramFiles% or
#   %LOCALAPPDATA%) and updates PATH automatically via the Windows installer.
#
# What can go wrong:
#   • winget not available — install "App Installer" from the Microsoft Store.
#   • Package already installed — winget returns non-zero but | Out-Null suppresses
#     it; the tool is already present so this is acceptable.
#   • No internet access — winget download fails; caught and reported.
#
# Prerequisites: winget must be available; internet access required.
function Install-CoreTools {
    try {
        $tools = @(
            "Neovim.Neovim",            # Modal text editor
            "Git.Git",                  # Version control
            "BurntSushi.Ripgrep",       # Fast grep (rg)
            "sharkdp.fd",               # Fast find
            "starship.starship",        # Cross-shell prompt
            "eza-community.eza",        # Modern ls
            "fastfetch-cli.fastfetch",  # System info
            "sharkdp.bat",              # Better cat (syntax highlighting)
            "zig.zig",                  # C compiler for Neovim Treesitter parsers
            "chrisant996.Clink"         # CMD readline (needed for Starship in cmd.exe)
        )
        foreach ($t in $tools) {
            Write-Status "Installing $t..." "Progress"
            winget install --id $t --silent --accept-package-agreements --accept-source-agreements | Out-Null
        }
        # Refresh the current session's PATH so newly installed tools are immediately
        # visible without opening a new terminal window.  winget updates the system
        # registry but the running process does not inherit the change automatically.
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" +
                    [System.Environment]::GetEnvironmentVariable("PATH","User")
        Write-Status "Core Tools installed" "Success"
    } catch { Write-Status "Winget failed: $_" "Error" }
}

# ── Configure-PowerShell ────────────────────────────────────────────────────────
# Configures the PowerShell profile for both Windows PowerShell 5 and PowerShell 7.
#
# What it does, in order:
#   1. Sets STARSHIP_CONFIG as a persistent User env var (so Starship finds the
#      symlinked starship.toml regardless of which PS version is running).
#   2. Deploys the active Windows theme to ~/.config\dotfiles\theme.ps1 so the
#      PS profile can source it for PSReadLine colors and $env:DOTFILES_COLOR_*.
#      Defaults to catppuccin-mocha.ps1; other themes live in themes/windows/.
#   3. Writes a thin wrapper profile to the PS5 and PS7 profile paths that
#      dot-sources the repo's tracked profile (windows\Microsoft.PowerShell_profile.ps1).
#      This means edits to the tracked file are picked up on the next PS session
#      without re-running setup.
#   4. Strips stale oh-my-posh / inline Starship lines from any existing profile.
#
# Prerequisites: $script:dotfilesDir should be set (resolved by Get-DotfilesDir).
function Configure-PowerShell {
    try {
        Write-Host "Configuring PowerShell Profiles..." -ForegroundColor Cyan

        # Set STARSHIP_CONFIG as a persistent User environment variable so Starship
        # finds the symlinked config regardless of which PS version is running.
        [Environment]::SetEnvironmentVariable("STARSHIP_CONFIG", "$env:USERPROFILE\.config\starship.toml", "User")
        $env:STARSHIP_CONFIG = "$env:USERPROFILE\.config\starship.toml"
        Add-Action "Set STARSHIP_CONFIG=$env:USERPROFILE\.config\starship.toml"

        # ── Deploy active theme to ~/.config\dotfiles\theme.ps1 ──────────────
        # The PS profile dot-sources this file for PSReadLine colors + palette vars.
        # Try the repo file first; if unavailable write the Catppuccin Mocha theme
        # inline so the profile always gets colours regardless of clone state.
        $dstThemeDir = "$env:USERPROFILE\.config\dotfiles"
        $dstTheme    = "$dstThemeDir\theme.ps1"
        if (-not (Test-Path $dstThemeDir)) { New-Item $dstThemeDir -ItemType Directory -Force | Out-Null }

        $srcTheme = if ($script:dotfilesDir) { Join-Path $script:dotfilesDir "themes\windows\$Theme.ps1" } else { $null }
        if ($srcTheme -and (Test-Path $srcTheme)) {
            Copy-Item -Path $srcTheme -Destination $dstTheme -Force
            Add-Action "Deployed theme from repo ($Theme): $dstTheme"
            Write-Status "Theme deployed ($Theme)" "Success"
        } else {
            # Inline Catppuccin Mocha theme — written when repo is not yet available.
            # Matches themes/windows/catppuccin-mocha.ps1 exactly.
            $inlineTheme = @'
# Catppuccin Mocha - inline fallback written by install.ps1
# This file is overwritten with the repo version on next setup run.
$env:DOTFILES_COLOR_BASE        = "#1E1E2E"
$env:DOTFILES_COLOR_TEXT        = "#CDD6F4"
$env:DOTFILES_COLOR_BLUE        = "#89B4FA"
$env:DOTFILES_COLOR_GREEN       = "#A6E3A1"
$env:DOTFILES_COLOR_RED         = "#F38BA8"
$env:DOTFILES_COLOR_YELLOW      = "#F9E2AF"
$env:DOTFILES_COLOR_MAUVE       = "#CBA6F7"
$env:DOTFILES_COLOR_PEACH       = "#FAB387"
$env:DOTFILES_COLOR_TEAL        = "#94E2D5"
$env:DOTFILES_COLOR_SURFACE0    = "#313244"
$env:DOTFILES_COLOR_OVERLAY1    = "#7F849C"
$env:DOTFILES_COLOR_SUBTEXT1    = "#BAC2DE"
$env:DOTFILES_WEZTERM_THEME     = "Catppuccin Mocha"
$env:DOTFILES_THEME_NAME        = "catppuccin-mocha"
if (Get-Module -ListAvailable -Name PSReadLine) {
    Set-PSReadLineOption -Colors @{
        Command            = "#89B4FA"
        Parameter          = "#A6E3A1"
        String             = "#A6E3A1"
        Variable           = "#CBA6F7"
        Comment            = "#7F849C"
        Keyword            = "#CBA6F7"
        Error              = "#F38BA8"
        Operator           = "#94E2D5"
        Number             = "#FAB387"
        Type               = "#F9E2AF"
        Member             = "#89DCEB"
        InlinePrediction   = "#7F849C"
        ContinuationPrompt = "#7F849C"
    }
}
'@
            [System.IO.File]::WriteAllText($dstTheme, $inlineTheme, [System.Text.UTF8Encoding]::new($true))
            Add-Action "Wrote inline Catppuccin Mocha theme to $dstTheme"
            Write-Status "Theme deployed inline (Catppuccin Mocha)" "Success"
        }

        # Locate the tracked PowerShell profile from the dotfiles repo
        $repoProfile = if ($script:dotfilesDir) { Join-Path $script:dotfilesDir "windows\Microsoft.PowerShell_profile.ps1" } else { $null }

        # All profile paths to configure (PS5 + PS7 for current and all users)
        $profilePaths = @(
            "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1",
            "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
        )
        # Also include $PROFILE if it resolves to a different path
        if ($PROFILE -and ($profilePaths -notcontains $PROFILE)) {
            $profilePaths += $PROFILE
        }
        $profilePaths = $profilePaths | Select-Object -Unique

        foreach ($path in $profilePaths) {
            $dir = Split-Path -Parent $path
            if (-not (Test-Path $dir)) { New-Item $dir -ItemType Directory -Force | Out-Null }

            if ($repoProfile -and (Test-Path $repoProfile)) {
                # Deploy the tracked profile — strip any old oh-my-posh/inline starship lines
                $existing = @()
                if (Test-Path $path) {
                    $existing = Get-Content $path | Where-Object {
                        $_ -notmatch "starship" -and
                        $_ -notmatch "oh-my-posh" -and
                        $_ -notmatch "Invoke-Expression" -and
                        $_ -notmatch "Added by Dotfiles"
                    }
                }
                # Prepend preserved custom content (if any), then dot-source the repo profile
                $final = @("# Dotfiles - sourced from repo (do not edit directly)")
                if ($existing) { $final += $existing }
                $final += ". `"$repoProfile`""
                $final | Out-File $path -Encoding UTF8 -Force
            } else {
                # Repo profile not found — fall back to minimal inline config
                Write-Status "Repo PS profile not found - writing minimal profile" "Warning"
                $final = @(
                    "# Added by Dotfiles Setup",
                    "[Environment]::SetEnvironmentVariable('STARSHIP_CONFIG', `"$env:USERPROFILE\.config\starship.toml`", 'User')",
                    'if (Get-Command starship -ErrorAction SilentlyContinue) { Invoke-Expression (&starship init powershell) }'
                )
                $final | Out-File $path -Encoding UTF8 -Force
            }
        }
        Write-Status "PowerShell Profiles configured" "Success"
    } catch { Write-Status "PowerShell failed: $_" "Error" }
}

# ── Symlink-Dotfiles ────────────────────────────────────────────────────────────
# Creates symbolic links in %USERPROFILE% pointing to the tracked source files in
# the dotfiles repository's stow\ directory tree.
#
# Why SymbolicLink requires Administrator:
#   By default, creating symbolic links on Windows requires the
#   SeCreateSymbolicLinkPrivilege, which is only granted to the Administrators
#   group.  Standard users can create symlinks only if Developer Mode is enabled.
#   This script always runs elevated, so this is not an issue.
#
# What each symlink does:
#   .bashrc          → stow\bash\.bashrc         — Bash config (WSL sessions)
#   .bash_aliases    → stow\bash\.bash_aliases   — Shared aliases (WSL + cross-platform tools)
#   .tmux.conf       → stow\tmux\.tmux.conf      — tmux config (WSL/SSH sessions)
#   .gitconfig       → stow\git\.gitconfig       — Git user/alias/tool settings (native Windows)
#   .inputrc         → stow\shell\.inputrc       — Readline keybindings (bash + python REPL)
#   .common_shell    → stow\shell\.common_shell  — Cross-shell env vars
#
#   NOT symlinked on Windows (Linux/WSL-only):
#   .blerc           — ble.sh is a Linux bash enhancement, irrelevant in PS/CMD
#
# .config\ directory:
#   Each subdirectory of stow\config\.config\ is symlinked into %USERPROFILE%\.config\.
#   This covers Starship (starship.toml), Neovim (nvim\), and any other XDG config.
#   starship.toml also gets a root-level symlink at %USERPROFILE%\starship.toml for
#   compatibility with tools that look there instead of .config\.
#
# What can go wrong:
#   • Source file not found — silently skipped (guarded by Test-Path).
#   • Target already exists as a directory (not a symlink) — Remove-Item -Recurse
#     deletes it; this is intentional but destructive if the directory has data.
#   • Dotfiles repo not found and git clone fails — caught and reported.
#
# Prerequisites: Administrator privileges for SymbolicLink creation.
function Symlink-Dotfiles {
    try {
        Write-Host "Symlinking dotfiles..." -ForegroundColor Cyan
        $userHome = $env:USERPROFILE
        $dotfilesDir = $script:dotfilesDir
        if (-not $dotfilesDir) {
            $dotfilesDir = Join-Path $userHome "dotfiles"
            if (-not (Test-Path $dotfilesDir)) {
                Write-Status "Cloning repository..." "Info"
                git clone "https://github.com/deey001/dotfiles.git" $dotfilesDir
            } else {
                # Hard-reset to origin/master so newly-added files (themes, settings.json)
                # are always present.  pull --ff-only can silently fail when tracking is
                # misconfigured or the local HEAD has diverged.
                Write-Status "Updating repository (fetch + reset)..." "Info"
                git -C $dotfilesDir fetch origin master 2>&1 | Out-Null
                git -C $dotfilesDir reset --hard origin/master 2>&1 | Out-Null
            }
            # Update the script-scoped variable so subsequent functions
            # (Configure-WindowsTerminal, Configure-PowerShell) can find
            # the repo even when this script was invoked via irm|iex and
            # $PSScriptRoot pointed to %TEMP%.
            $script:dotfilesDir = $dotfilesDir
            Add-Action "Resolved dotfiles dir: $dotfilesDir"
        } else {
            # Repo was already known — still hard-reset to get any new files.
            Write-Status "Updating repository (fetch + reset)..." "Info"
            git -C $dotfilesDir fetch origin master 2>&1 | Out-Null
            git -C $dotfilesDir reset --hard origin/master 2>&1 | Out-Null
        }
        # Symlink files that are useful on Windows (including WSL sessions).
        # Excluded intentionally:
        #   .blerc  — ble.sh is a Linux/WSL bash enhancement, not used in PS/CMD
        #   (tmux.conf is kept because WSL users benefit from it)
        $fileMap = @{
            ".bashrc"       = "stow\bash\.bashrc"          # WSL bash config
            ".bash_aliases" = "stow\bash\.bash_aliases"    # Shared aliases (WSL + tools)
            ".tmux.conf"    = "stow\tmux\.tmux.conf"       # tmux (WSL/SSH sessions)
            ".gitconfig"    = "stow\git\.gitconfig"        # Git — used natively on Windows
            ".inputrc"      = "stow\shell\.inputrc"        # Readline keybindings
            ".common_shell" = "stow\shell\.common_shell"   # Cross-shell env vars
        }
        foreach ($f in $fileMap.Keys) {
            $src = Join-Path $dotfilesDir $fileMap[$f]; $tgt = Join-Path $userHome $f
            if (Test-Path $src) { if (Test-Path $tgt) { Remove-Item $tgt -Force }; New-Item -ItemType SymbolicLink -Path $tgt -Value $src -Force | Out-Null }
        }
        $configSrc = Join-Path $dotfilesDir "stow\config\.config"; $configTgt = Join-Path $userHome ".config"
        if (Test-Path $configSrc) {
            if (-not (Test-Path $configTgt)) { New-Item $configTgt -ItemType Directory -Force | Out-Null }
            Get-ChildItem $configSrc | ForEach-Object {
                $iSrc = $_.FullName; $iTgt = Join-Path $configTgt $_.Name
                if (Test-Path $iTgt) { if ($_.PSIsContainer) { Remove-Item $iTgt -Recurse -Force } else { Remove-Item $iTgt -Force } }
                New-Item -ItemType SymbolicLink -Path $iTgt -Value $iSrc -Force | Out-Null
                if ($_.Name -eq "starship.toml") { $rTgt = Join-Path $userHome "starship.toml"; if (Test-Path $rTgt) { Remove-Item $rTgt -Force }; New-Item -ItemType SymbolicLink -Path $rTgt -Value $iSrc -Force | Out-Null }
            }
        }
        Write-Status "Dotfiles symlinked" "Success"
    } catch { Write-Status "Symlinking failed: $_" "Error" }
}

# ── Configure-CMD ───────────────────────────────────────────────────────────────
# Configures the Windows Command Prompt (cmd.exe) to use Starship as its prompt
# via the Clink readline extension.
#
# Why Clink is needed:
#   cmd.exe has no native support for custom prompts beyond the static %PROMPT%
#   environment variable.  Clink (https://chrisant996.github.io/clink/) injects
#   a Lua scripting layer into cmd.exe at startup, enabling Readline editing,
#   history improvements, and — critically — arbitrary Lua-driven prompt rendering.
#   Starship provides a `starship init cmd` command that outputs a Lua snippet
#   designed to be loaded by Clink.
#
# How the Lua file works:
#   The single line:
#     load(io.popen("starship init cmd"):read("*a"))()
#   runs `starship init cmd` as a subprocess, captures its Lua output, and
#   executes it in the Clink context.  This is the officially documented method
#   for Starship + Clink integration.
#
# What it modifies:
#   %LOCALAPPDATA%\clink\starship.lua — Clink auto-loads all *.lua files from its
# ── Configure-CMD ───────────────────────────────────────────────────────────────
# Configures the Windows Command Prompt (cmd.exe) to use Starship as its prompt
# via the Clink readline extension.
#
# Why Clink is needed:
#   cmd.exe has no native support for custom prompts beyond the static %PROMPT%
#   environment variable.  Clink (https://chrisant996.github.io/clink/) injects
#   a Lua scripting layer into cmd.exe at startup, enabling Readline editing,
#   history improvements, and Lua-driven prompt rendering.
#   Starship provides `starship init cmd` which outputs a Lua snippet for Clink.
#
# How detection works:
#   Clink is installed via winget in Install-CoreTools, but its exe may not be
#   on PATH in the running session yet.  We therefore check common install paths.
#   Critically, we do NOT need to RUN clink here — we only need to write a
#   one-line Lua file into its auto-load directory (%LOCALAPPDATA%\clink\).
#   Clink loads all *.lua files from that directory on every cmd.exe launch.
#
# What it modifies:
#   %LOCALAPPDATA%\clink\starship.lua — written unconditionally (safe if Clink is
#   absent; activates automatically on the next cmd.exe session after Clink installs)
#
# What can go wrong:
#   • starship is not on PATH at CMD launch time — Clink will silently skip the
#     prompt; installing Starship via Install-CoreTools fixes this.
#
# Prerequisites: Clink should be installed (done by Install-CoreTools).
function Configure-CMD {
    try {
        Write-Host "Configuring Command Prompt (CMD) with Starship..." -ForegroundColor Cyan

        # Write the Clink Lua loader regardless of whether clink is detected.
        # Clink auto-loads every *.lua file from %LOCALAPPDATA%\clink\ at cmd.exe startup.
        # Writing this file is safe even if Clink is not yet installed — it will
        # simply take effect the next time cmd.exe starts after Clink is present.
        $clinkDir    = "$env:LOCALAPPDATA\clink"
        $starshipLua = "$clinkDir\starship.lua"
        if (-not (Test-Path $clinkDir)) { New-Item $clinkDir -ItemType Directory -Force | Out-Null }
        'load(io.popen("starship init cmd"):read("*a"))()' | Out-File $starshipLua -Encoding UTF8 -Force
        Add-Action "Wrote Clink Starship loader: $starshipLua"

        # Determine whether Clink is currently installed so we can give an accurate status.
        # Check common install paths — winget may not have updated PATH in this session.
        $clinkInstalled = (Get-Command clink -ErrorAction SilentlyContinue) -or
                          (Test-Path "$env:LOCALAPPDATA\Programs\clink\clink.bat") -or
                          (Test-Path "${env:ProgramFiles(x86)}\clink\clink.bat") -or
                          (Test-Path "$env:ProgramFiles\clink\clink.bat")

        if ($clinkInstalled) {
            Write-Status "CMD configured via Clink + Starship" "Success"
        } else {
            # Clink may have just been installed by Install-CoreTools but its installer
            # may not have finished unpacking.  The Lua file is already written and will
            # activate on the next cmd.exe session once Clink's install completes.
            Write-Status "Clink lua written; open a new CMD window after Clink install completes" "Info"
        }
    } catch { Write-Status "CMD config failed: $_" "Error" }
}

        if ($clinkInstalled) {
            Write-Status "CMD configured via Clink + Starship" "Success"
        } else {
            # Clink may have just been installed by Install-CoreTools but winget's
            # unpack may not have finished.  The Lua file is written; it will activate
            # on the next cmd.exe session once Clink's installer completes.
            Write-Status "Clink lua written; open a new CMD window after Clink install completes" "Info"
        }
    } catch { Write-Status "CMD config failed: $_" "Error" }
}

# ── Install-RemoteDotfiles ──────────────────────────────────────────────────────
# Displays the one-liner curl command for bootstrapping dotfiles on a remote
# Linux / macOS server.  This function contains no install logic — it is purely
# informational, giving the user the exact command to run on a fresh server to
# replicate the shell environment set up by install.sh.
#
# Why this is in the Windows installer:
#   Many users manage remote servers from Windows.  After setting up the local
#   Windows environment they typically want to apply the same dotfiles to their
#   servers.  Providing the command here, in context, removes the need to look
#   it up elsewhere.
#
# What it modifies: nothing — read-only display function.
# What can go wrong: nothing — no network calls, no file writes.
function Install-RemoteDotfiles {
    Write-ColorText "`nREMOTE SERVER SETUP" "Cyan"
    Write-Host "Run this on your server:"
    Write-ColorText "curl -fsSL https://raw.githubusercontent.com/deey001/dotfiles/master/scripts/install.sh | bash" "Yellow"
}

# ── Show-Menu ───────────────────────────────────────────────────────────────────
# Clears the console and renders the interactive selection menu.
#
# Structure:
#   Items 1–6  — individual configuration steps (can be run in any order)
#   Item 7     — Full Local Setup: runs items 1–6 in the recommended sequence
#   Item 8     — Symlink Dotfiles: links repo files into %USERPROFILE%
#   Item 9     — Remote Setup Guide: prints the Linux/macOS one-liner
#   Item A     — Complete Workflow: runs all of 1–8 then shows the remote guide
#   Item 0     — Exit the menu loop
#
# Why a menu instead of a linear script?
#   Different machines need different subsets of the setup.  A menu lets the user
#   re-run individual steps (e.g. just re-link dotfiles after adding a new file)
#   without re-running the full install.
#
# What it modifies: nothing — display only.  Input reading is done in Main.
function Show-Menu {
    Clear-Host
    Write-ColorText "╔══════════════════════════════════════════════════╗" "Cyan"
    Write-ColorText "║          DOTFILES WINDOWS SETUP TOOL             ║" "Cyan"
    Write-ColorText "╚══════════════════════════════════════════════════╝" "Cyan"
    Write-Host ""
    Write-ColorText " [1] Install Nerd Font" "Yellow"
    Write-ColorText " [2] Configure Windows Terminal Font + Theme" "Yellow"
    Write-ColorText " [3] Configure PuTTY Font" "Yellow"
    Write-ColorText " [4] Install Core Tools (Winget)" "Yellow"
    Write-ColorText " [5] Configure PowerShell Profile" "Yellow"
    Write-ColorText " [6] Configure CMD Prompt (requires Clink)" "Yellow"
    Write-ColorText " [7] Full Local Setup (1-6)" "Green"
    Write-ColorText " [8] Symlink Dotfiles" "Green"
    Write-ColorText " [9] Remote Setup Guide" "Yellow"
    Write-ColorText " [A] Complete Workflow (1-8)" "Yellow"
    Write-ColorText " [0] Exit" "Red"
    Write-Host "`nEnter choice: " -NoNewline
}

# ── Main ────────────────────────────────────────────────────────────────────────
# Entry point.  Backs up existing settings once, then runs the interactive menu
# loop until the user chooses to exit (option 0).
#
# Structure:
#   • Backup-Settings is called once before the loop so a snapshot exists
#     regardless of which options the user chooses during the session.
#   • The do…while loop re-renders the menu and reads input after each action,
#     allowing the user to run multiple steps in one session.
#   • After any non-exit choice, Read-Host pauses so the user can read the output
#     of the just-completed action before the menu clears the screen.
#
# Switch dispatch:
#   "7" and "A"/"a" call multiple functions in the recommended sequence.
#   Both "A" and "a" are matched explicitly to handle Shift and CapsLock states.
#
# What can go wrong:
#   Any unhandled exception from a called function bubbles up to the outer catch
#   and is printed via Write-Error; the menu loop does not restart after a fatal
#   error, so the -NoExit window stays open and the user can inspect the error.
function Main {
    try {
        Backup-Settings
        do {
            Show-Menu
            $c = Read-Host
        # Use -CaseSensitive to prevent PS default case-insensitive matching from
        # running both "A" and "a" cases when the user types uppercase A.
        switch -CaseSensitive ($c) {
                "1" { Install-NerdFont }
                "2" { Configure-WindowsTerminal }
                "3" { Configure-PuTTY }
                "4" { Install-CoreTools }
                "5" { Configure-PowerShell }
                "6" { Configure-CMD }
                # Option 7: Full local setup - Symlink-Dotfiles runs FIRST so the repo
                # is cloned/updated before Configure-* functions try to read repo files.
                "7" { Install-NerdFont; Install-CoreTools; Symlink-Dotfiles; Configure-WindowsTerminal; Configure-PuTTY; Configure-PowerShell; Configure-CMD }
                "8" { Symlink-Dotfiles }
                "9" { Install-RemoteDotfiles }
                # Option A/a: Complete workflow - same ordering rationale as option 7.
                { $_ -in "A","a" } { Install-NerdFont; Install-CoreTools; Symlink-Dotfiles; Configure-WindowsTerminal; Configure-PuTTY; Configure-PowerShell; Configure-CMD; Install-RemoteDotfiles }
                "0" { break }
        }
            if ($c -ne "0") { Read-Host "`nPress Enter to continue" }
        } while ($c -ne "0")
    } catch { Write-Error "Error: $_" }
}
Main
