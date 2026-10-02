# PuTTY settings, applied to "Default Settings" and every saved session.
# Dot-sourced by install.ps1.
#
# Session logging is only switched on for sessions where it's currently off, so
# an existing log setup is never overwritten. Logs go to
# ~\logs\putty\<host>-<date>-<time>.log.

$PuttySessions = 'HKCU:\Software\SimonTatham\PuTTY\Sessions'

# Catppuccin Mocha, in PuTTY's colour order (fg, bold fg, bg, bold bg,
# cursor text, cursor, then black/red/green/yellow/blue/magenta/cyan/white,
# each followed by its bold variant). Matches WezTerm and Windows Terminal.
$PuttyColours = '205,214,244', '205,214,244', '30,30,46', '30,30,46', '30,30,46', '245,224,220',
                '69,71,90', '88,91,112', '243,139,168', '243,139,168', '166,227,161', '166,227,161',
                '249,226,175', '249,226,175', '137,180,250', '137,180,250', '245,194,231', '245,194,231',
                '148,226,213', '148,226,213', '186,194,222', '166,173,200'

function Set-PuttySession($Key) {
    $current = Get-ItemProperty $Key -ErrorAction SilentlyContinue
    $strings = @{
        Font         = 'JetBrainsMono Nerd Font'
        TerminalType = 'xterm-256color'
        LineCodePage = 'UTF-8'
    }
    $dwords = @{
        FontHeight  = 12
        FontCharSet = 0
    }
    if (-not $current.LogType) {
        $strings.LogFileName = "$HOME\logs\putty\&H-&Y&M&D-&T.log"
        $dwords.LogType = 1        # printable output
        $dwords.LogFileClash = 1   # append if the file exists
        $dwords.LogFlush = 1       # write as it happens, so logs survive a crash
    }
    for ($i = 0; $i -lt $PuttyColours.Count; $i++) { $strings["Colour$i"] = $PuttyColours[$i] }

    foreach ($k in $strings.Keys) { New-ItemProperty $Key -Name $k -Value $strings[$k] -PropertyType String -Force | Out-Null }
    foreach ($k in $dwords.Keys) { New-ItemProperty $Key -Name $k -Value $dwords[$k] -PropertyType DWord -Force | Out-Null }
}

function Set-PuttyDefaults {
    New-Item "$HOME\logs\putty" -ItemType Directory -Force | Out-Null
    New-Item "$PuttySessions\Default%20Settings" -Force -ErrorAction SilentlyContinue | Out-Null
    foreach ($session in Get-ChildItem $PuttySessions) {
        Set-PuttySession $session.PSPath
        Write-Host "  $([Uri]::UnescapeDataString($session.PSChildName))"
    }
}
