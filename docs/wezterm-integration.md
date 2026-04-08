# WezTerm Integration Guide: Auto-Logging & KeePass

This document explains how to set up automatic SSH session logging and integrate WezTerm with KeePass.

## 1. Auto-Logging SSH Sessions

WezTerm doesn't have a single settings variable to log everything, but it provides a powerful `record` command that saves everything (including colors and timing).

You can wrap the SSH command in a shell alias/function to automatically generate timestamped filenames.

### Linux / macOS (Bash / Zsh)
Add this to your `~/.bashrc` or `~/.zshrc`:
```bash
wez-ssh() {
  # Create a logs directory if it doesn't exist
  mkdir -p "$HOME/logs"
  
  local timestamp=$(date +%Y%m%d-%H%M%S)
  local logfile="$HOME/logs/ssh_${1}_${timestamp}.cast"
  
  # Start WezTerm recording the SSH session
  wezterm record -o "$logfile" -- wezterm ssh "$1"
}
```
*Usage:* Run `wez-ssh danny@10.10.1.250`. It will record to a `.cast` file. You can later watch it with `wezterm replay <file.cast>` or export plain text with `wezterm replay --cat <file.cast> > session.txt`.

### Windows (PowerShell)
Add this to your `$PROFILE`:
```powershell
function wez-ssh {
  param([string]$target)
  
  # Ensure the logs directory exists
  $logDir = "$HOME\logs"
  if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir }
  
  $time = Get-Date -Format "yyyyMMdd-HHmmss"
  $logfile = "$logDir\ssh_${target}_${time}.cast"
  
  # Start WezTerm recording the SSH session
  wezterm record -o $logfile -- wezterm ssh $target
}
```

---

## 2. Launching WezTerm via KeePass (URL Overrides)

You can pass SSH commands directly to WezTerm from external password managers like KeePass.

1. Open KeePass.
2. Go to **Tools > Options > Integration > URL Overrides**.
3. Click **Add...** to create a new scheme.
4. Set **Scheme** to `ssh`.
5. Set **URL override** to one of the following options:

### Option A: Standard SSH Connection (No Logging)
```text
cmd://wezterm ssh {USERNAME}@{URL:RMVSCM} -p {URL:PORT}
```

### Option B: Auto-Logging SSH Connection
If you want KeePass to automatically record every session it launches, you can use KeePass's built-in `{TITLE}` and date placeholders to name the log file:
```text
cmd://wezterm record -o "C:\logs\ssh_{TITLE}_{YEAR}{MONTH}{DAY}-{HOUR}{MIN}{SEC}.cast" -- wezterm ssh {USERNAME}@{URL:RMVSCM} -p {URL:PORT}
```

*(Note: If your WezTerm executable isn't in your system PATH, replace `wezterm` with the full path, e.g., `"C:\Program Files\WezTerm\wezterm.exe"`)*
