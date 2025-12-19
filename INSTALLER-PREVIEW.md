# Interactive Installer Preview

This document shows what your colleagues will see when they run the installer.

## One-Liner Command

```powershell
irm "https://raw.githubusercontent.com/deey001/dotfiles/master/install.ps1" | iex
```

---

## Interactive Menu (Screenshot Preview)

```
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


═══ CURRENT STATUS ═══

  Nerd Font:        ✓ Installed
  Windows Terminal: ✓ Detected
  PuTTY:            ✓ Detected
  Privileges:       ✓ Administrator

═══ INSTALLATION OPTIONS ═══

[1] Install Nerd Fonts (Required for icons)
    → Downloads UbuntuMono Nerd Font from GitHub
    → Installs to Windows for all users
    → Enables icon rendering in terminals

[2] Configure Windows Terminal
    → Sets default font to UbuntuMono Nerd Font
    → Applies to all profiles automatically

[3] Configure PuTTY Default Settings
    → Modifies Default Settings (not individual sessions)
    → All connections from KeePass inherit settings
    → Enables UTF-8, OSC 52 clipboard, xterm-256color

[4] Full Setup (Recommended) - All of the above
    → Install fonts + configure all detected terminals

[5] Install Dotfiles on Remote Server
    → SSH to Linux server and run dotfiles installation
    → Requires SSH client (OpenSSH/PuTTY)

[6] Complete Workflow (Fonts + Terminals + Remote)
    → Does everything: local setup + server install

[X] Exit

═══════════════════════════════

Select an option: _
```

---

## Example: Running Option [4] Full Setup

```powershell
Select an option: 4

═══ Installing Nerd Fonts ═══

[→] Downloading UbuntuMono Nerd Font...
[→] Extracting fonts...
[→] Installing fonts to system...
    Installing: UbuntuMono NF Regular.ttf
    Installing: UbuntuMono NF Bold.ttf
    Installing: UbuntuMono NF Italic.ttf
    Installing: UbuntuMono NF Bold Italic.ttf
[✓] Nerd Fonts installed successfully

═══ Configuring Windows Terminal ═══

[→] Updating settings.json...
[✓] Windows Terminal configured
[i] Font: UbuntuMono Nerd Font, Size: 11
[i] Restart Windows Terminal to apply changes

═══ Configuring PuTTY Default Settings ═══

[→] Modifying PuTTY Default Settings...
[✓] PuTTY Default Settings configured
[i] Font: UbuntuMono Nerd Font, Size: 11
[i] UTF-8: Enabled | OSC 52: Enabled | Terminal: xterm-256color
[i] All connections (including from KeePass) will inherit these settings

═══════════════════════════════════════════════════════════
                  ✓ Installation Complete!
═══════════════════════════════════════════════════════════

[✓] Nerd Fonts installed and terminals configured

NEXT STEPS:

  1. Restart your terminal (Windows Terminal or PuTTY)
  2. Connect to your server via SSH
  3. Icons should now display correctly! 🎨

For PuTTY + KeePass users:
  → Default Settings are now configured
  → All connections from KeePass will use Nerd Font
  → No need to configure individual sessions!

Press Enter to continue...
```

---

## Example: Status When Components Missing

If fonts not installed and Windows Terminal not found:

```
═══ CURRENT STATUS ═══

  Nerd Font:        ✗ Not Installed
  Windows Terminal: ✗ Not Found
  PuTTY:            ✓ Detected
  Privileges:       ✓ Administrator

═══ INSTALLATION OPTIONS ═══

[1] Install Nerd Fonts (Required for icons)
    ...

[2] Configure Windows Terminal (Not detected)
    ...

[!] Some options require Administrator privileges
  Right-click PowerShell → Run as Administrator
```

---

## Example: Running Without Admin Privileges

```
═══ CURRENT STATUS ═══

  Nerd Font:        ✗ Not Installed
  Windows Terminal: ✓ Detected
  PuTTY:            ✓ Detected
  Privileges:       ✗ Not Admin

═══ INSTALLATION OPTIONS ═══

[1] Install Nerd Fonts (Required for icons)
    ...

[!] Some options require Administrator privileges
  Right-click PowerShell → Run as Administrator

Select an option: 1

═══ Installing Nerd Fonts ═══

[✗] Administrator privileges required for font installation
[i] Right-click PowerShell and select 'Run as Administrator'

Press Enter to continue...
```

---

## Example: Option [5] Remote Server Install

```
Select an option: 5

═══ Remote Server Installation ═══

Enter SSH host (e.g., user@hostname or IP): root@192.168.1.100

[→] Connecting to root@192.168.1.100...

git clone https://github.com/deey001/dotfiles.git ~/dotfiles 2>/dev/null || (cd ~/dotfiles && git pull)
Cloning into '/root/dotfiles'...
remote: Enumerating objects: 342, done.
remote: Counting objects: 100% (342/342), done.
remote: Compressing objects: 100% (234/234), done.
remote: Total 342 (delta 145), reused 298 (delta 101), pack-reused 0
Receiving objects: 100% (342/342), 287.43 KiB | 3.21 MiB/s, done.
Resolving deltas: 100% (145/145), done.

cd ~/dotfiles && ./install.sh
Dotfiles directory detected at: /root/dotfiles
Checking internet connectivity...
Status: ONLINE
Detected Operating System: Linux
Installing tools via apt...
...
Installation Complete!

[✓] Remote installation completed

Press Enter to continue...
```

---

## Color Legend

The installer uses these color-coded indicators:

| Indicator | Color | Meaning |
|-----------|-------|---------|
| `[i]` | Blue | Information |
| `[✓]` | Green | Success |
| `[!]` | Yellow | Warning |
| `[✗]` | Red | Error |
| `[→]` | Cyan | Working/In Progress |

---

## How Colleagues Use It

### Scenario 1: New User (Windows Terminal)

```bash
# Open PowerShell as Admin
# Run one-liner
irm "https://raw.githubusercontent.com/deey001/dotfiles/master/install.ps1" | iex

# Select option 4 (Full Setup)
# Wait 2 minutes
# Restart Windows Terminal
# SSH to server → Icons work! ✓
```

### Scenario 2: KeePass + PuTTY User

```bash
# Open PowerShell as Admin
# Run one-liner
irm "https://raw.githubusercontent.com/deey001/dotfiles/master/install.ps1" | iex

# Select option 3 (PuTTY Default Settings)
# Done!
# Open KeePass
# Double-click any SSH entry
# PuTTY launches with Nerd Font automatically
# Connect to server → Icons work! ✓
```

### Scenario 3: Complete Workflow

```bash
# Open PowerShell as Admin
# Run one-liner
irm "https://raw.githubusercontent.com/deey001/dotfiles/master/install.ps1" | iex

# Select option 6 (Complete Workflow)
# Fonts install → Terminals configure → Prompts for server
# Enter: user@myserver.com
# Remote install runs automatically
# Done! Local + Remote setup complete ✓
```

---

## Key Features

### ✅ Idempotent
Running the installer multiple times is safe:
- Checks if fonts already installed
- Skips unnecessary steps
- Updates only what needs updating

### ✅ Smart Detection
Automatically detects:
- Administrator privileges
- Windows Terminal installation
- PuTTY installation
- Font installation status

### ✅ KeePass Compatible
**Critical for your use case:**
- Modifies PuTTY "Default Settings" (not sessions)
- All KeePass connections inherit settings
- No per-session configuration needed
- Works immediately with existing KeePass database

### ✅ User-Friendly
- Clear menu with descriptions
- Real-time status updates
- Helpful error messages
- Next-step guidance

---

## Sharing with Colleagues

### Email Template

```
Subject: Quick Setup for Dotfiles (2 minutes!)

Hey team,

Want icons and better terminal experience on your Linux servers?

Quick setup (Windows users):
1. Open PowerShell as Administrator
2. Run this:
   irm "https://raw.githubusercontent.com/deey001/dotfiles/master/install.ps1" | iex
3. Select option 4 (Full Setup)
4. Done!

For KeePass users: This configures PuTTY Default Settings,
so all your existing connections will automatically use the
correct font. No need to reconfigure anything!

- Your Name
```

### Slack/Teams Message

```
🚀 New Dotfiles Installer!

One-liner install (PowerShell as Admin):
irm "https://raw.githubusercontent.com/deey001/dotfiles/master/install.ps1" | iex

Interactive menu with options:
[1] Fonts only
[2] Windows Terminal
[3] PuTTY (works with KeePass!)
[4] Full setup ⭐

Takes 2 minutes. Icons work immediately! 🎨
```

---

## Troubleshooting

### "Script won't run"

**Issue:** Execution policy blocks script

**Fix:**
```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
irm "https://raw.githubusercontent.com/deey001/dotfiles/master/install.ps1" | iex
```

### "Fonts installed but not showing in PuTTY"

**Check:**
1. Did you run option [3] to configure PuTTY?
2. Registry path: `HKCU:\Software\SimonTatham\PuTTY\Sessions\Default%20Settings`
3. Verify "Font" = "UbuntuMono Nerd Font"

### "KeePass connections still use old font"

**Fix:**
- Close all PuTTY windows
- Close KeePass
- Reopen KeePass
- Launch connection → Should use new font

---

## What's Different from Chris Titus?

### Similar:
- ✅ One-liner install (`irm ... | iex`)
- ✅ Interactive menu with numbered options
- ✅ Color-coded status indicators
- ✅ Component detection
- ✅ ASCII art banner

### Different:
- 🎯 Focused on dotfiles/fonts (not Windows tweaks)
- 🎯 KeePass + PuTTY integration (Default Settings)
- 🎯 Remote server installation option
- 🎯 Terminal-specific (not system-wide changes)

---

Enjoy your new dotfiles installer! 🎉
