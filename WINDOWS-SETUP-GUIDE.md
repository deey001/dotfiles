# Windows Setup Guide for Dotfiles

Quick guide for colleagues setting up dotfiles from Windows.

## The Problem

When you connect to a Linux server from Windows and install these dotfiles, you'll see **broken icons** and **weird characters** instead of the beautiful interface. This happens because:

- The **server** installs Nerd Fonts in Linux
- Your **Windows terminal** doesn't have those fonts
- Result: �  instead of

## The Solution

**Install Nerd Fonts on your Windows machine FIRST, then connect to the server.**

---

## Step-by-Step Instructions

### Method 1: Automated (Recommended) ⚡

**For both Windows Terminal and PuTTY users:**

1. **Download the repo** to your Windows PC:
   - Go to: https://github.com/deey001/dotfiles
   - Click green "Code" button → Download ZIP
   - Extract to `C:\dotfiles` (or anywhere)

2. **Run the setup script**:
   - Navigate to the extracted folder
   - **Right-click** `setup-windows.bat`
   - Select **"Run as Administrator"**
   - ![Run as Administrator](https://i.imgur.com/example.png)

3. **Follow the prompts**:
   ```
   [1/4] Installing Ubuntu Nerd Font...
     → Downloading...
     → Installing...
     ✓ Font installed

   [2/4] Configuring Windows Terminal...
     ✓ Configured

   [3/4] Configuring PuTTY...
     ✓ Template session created

   [4/4] Remote Server Installation...
   Do you want to install dotfiles on a remote server now? (y/N): y
   Enter SSH host: user@yourserver.com
     → Connecting...
     → Running remote installation...
     ✓ Complete!
   ```

4. **Restart your terminal** (Windows Terminal or PuTTY)

5. **Connect to server** - Icons should now work! 🎉

---

### Method 2: Manual Setup 🛠️

**If the automated script doesn't work:**

#### Step 1: Install Font

1. Download [UbuntuMono Nerd Font](https://github.com/ryanoasis/nerd-fonts/releases/latest/download/UbuntuMono.zip)
2. Extract the ZIP file
3. Select all `.ttf` files
4. Right-click → **Install for all users**
5. Wait for installation to complete

#### Step 2A: Configure Windows Terminal

1. Open **Windows Terminal**
2. Press `Ctrl + ,` (opens Settings)
3. Click **"Profiles"** → **"Defaults"**
4. Scroll to **"Appearance"**
5. Change **"Font face"** to: `UbuntuMono Nerd Font`
6. Set **"Font size"** to: `11`
7. Click **"Save"**
8. Restart Windows Terminal

#### Step 2B: Configure PuTTY

1. Open **PuTTY**
2. In the left panel: **Window** → **Appearance**
3. Click **"Change"** button next to Font settings
4. Select **"UbuntuMono Nerd Font"**
5. Set size to **11**
6. Click **OK**
7. Go back to **Session** in left panel
8. Enter a session name (e.g., "MyServer")
9. Click **"Save"**
10. Now enter your host details and connect

#### Step 3: Install Dotfiles on Server

1. Connect to your server via SSH
2. Run these commands:
   ```bash
   git clone https://github.com/deey001/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ./install.sh
   ```
3. Wait for installation
4. Disconnect and reconnect

---

## Troubleshooting

### "Icons still don't show"

**Check font installation:**
1. Open Windows **Font Settings**
2. Search for "Ubuntu"
3. You should see "UbuntuMono Nerd Font" and variants

**Check terminal settings:**
- Windows Terminal: `Ctrl + ,` → Profiles → Defaults → Appearance → Font face
- PuTTY: Window → Appearance → Font

### "PowerShell script won't run"

**Error:** "Execution policy prevents this script"

**Fix:**
1. Open PowerShell as Administrator
2. Run: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`
3. Run the script: `.\local-setup.ps1`

### "Font looks wrong/blurry"

**Try:**
- Restart your terminal completely
- Log out and back in to Windows
- Use size 11 (not too small, not too big)
- Enable **ClearType** in Windows settings

### "Can't connect to server in script"

**Manual connection:**
1. Skip the remote installation (answer 'N')
2. Connect to server with your configured terminal
3. Run these commands manually:
   ```bash
   git clone https://github.com/deey001/dotfiles.git ~/dotfiles
   cd ~/dotfiles && ./install.sh
   ```

---

## For PuTTY Users: Using the Template

The automated script creates a **"Dotfiles-Template"** session with all the right settings:

1. Open PuTTY
2. In **"Saved Sessions"**, select **"Dotfiles-Template"**
3. Click **"Load"**
4. Change **"Host Name"** to your server
5. Change **"Saved Sessions"** name to something like "Production Server"
6. Click **"Save"**
7. Click **"Open"** to connect

Now you have a saved session with:
- ✅ Nerd Font configured
- ✅ UTF-8 encoding enabled
- ✅ Clipboard integration (OSC 52)
- ✅ xterm-256color terminal type

Just load, change host, save as new session!

---

## What Gets Installed (Windows Side)

### Fonts
- UbuntuMono Nerd Font Regular
- UbuntuMono Nerd Font Bold
- UbuntuMono Nerd Font Italic
- UbuntuMono Nerd Font Bold Italic

### Terminal Configurations

**Windows Terminal:**
- Default font → UbuntuMono Nerd Font
- Font size → 11
- Automatically applied to all profiles

**PuTTY:**
- Template session: "Dotfiles-Template"
- Font: UbuntuMono Nerd Font, size 11
- UTF-8 encoding enabled
- OSC 52 clipboard support enabled
- Terminal type: xterm-256color

---

## Visual Comparison

### Before Setup (No Font)
```
[?] CPU: 4 cores @ 2.4GHz
[?] RAM: 8GB
[?] ~/projects
```

### After Setup (With Font)
```
  CPU: 4 cores @ 2.4GHz
  RAM: 8GB
  ~/projects
```

---

## Quick Reference Card

**Print this and keep at your desk:**

```
┌─────────────────────────────────────────────┐
│  DOTFILES WINDOWS SETUP - QUICK REFERENCE   │
├─────────────────────────────────────────────┤
│                                             │
│  1. Download: github.com/deey001/dotfiles  │
│                                             │
│  2. Right-click setup-windows.bat          │
│     → Run as Administrator                  │
│                                             │
│  3. Follow prompts                          │
│                                             │
│  4. Restart terminal                        │
│                                             │
│  5. Connect to server - enjoy icons! 🎨     │
│                                             │
├─────────────────────────────────────────────┤
│  Manual Font:                               │
│  github.com/ryanoasis/nerd-fonts/releases  │
│  → UbuntuMono.zip                           │
├─────────────────────────────────────────────┤
│  Need help? Check WINDOWS-SETUP-GUIDE.md   │
└─────────────────────────────────────────────┘
```

---

## FAQ

**Q: Do I need to install fonts on every server?**
A: No! Fonts only need to be installed on your **Windows machine**. Once set up, they'll work for all SSH connections.

**Q: Can I use other terminals (like MobaXterm)?**
A: Yes, but you'll need to manually configure the font in that terminal's settings.

**Q: Will this affect my other saved PuTTY sessions?**
A: No, existing sessions are untouched. The script creates a new "Dotfiles-Template" session.

**Q: Can multiple colleagues use the same script?**
A: Yes! Share `setup-windows.bat`. Each person runs it on their own Windows machine.

**Q: What if I already have Nerd Fonts installed?**
A: The script detects this and skips font installation. Safe to run!

---

## Need Help?

- Check the main [README.md](README.md) for detailed documentation
- Issues? Report at: https://github.com/deey001/dotfiles/issues
- Ask your colleague who shared this repo

---

Happy terminal-ing! 🚀
