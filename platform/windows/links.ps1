# Where each tracked file is linked on Windows. Dot-sourced by install.ps1 and uninstall.ps1.
$Docs = [Environment]::GetFolderPath('MyDocuments')

$Links = [ordered]@{
    "$HOME\.gitconfig"                                     = 'home\.gitconfig'
    "$HOME\.config\git\ignore"                             = 'home\.config\git\ignore'
    "$HOME\.config\starship.toml"                          = 'home\.config\starship.toml'
    "$HOME\.config\wezterm"                                = 'home\.config\wezterm'
    "$env:LOCALAPPDATA\nvim"                               = 'home\.config\nvim'
    "$Docs\PowerShell\Microsoft.PowerShell_profile.ps1"        = 'platform\windows\profile.ps1'
    "$Docs\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" = 'platform\windows\profile.ps1'
    "$env:LOCALAPPDATA\Microsoft\Windows Terminal\Fragments\dotfiles\dotfiles.json" = 'platform\windows\terminal.json'
}

# Path inside a backup folder for a given link target, e.g. ~\.gitconfig -> <backup>\.gitconfig
function Get-BackupPath($BackupDir, $Target) {
    $rel = if ($Target.StartsWith($HOME)) { $Target.Substring($HOME.Length) } else { $Target.Replace(':', '') }
    Join-Path $BackupDir $rel.TrimStart('\')
}

# True when $Target is a symlink to $Source
function Test-Linked($Target, $Source) {
    $item = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    $item -and $item.LinkType -eq 'SymbolicLink' -and "$($item.Target)" -eq $Source
}

# Delete a file or directory symlink without touching what it points to
function Remove-Link($Path) {
    if ((Get-Item -LiteralPath $Path -Force).PSIsContainer) { [IO.Directory]::Delete($Path) } else { [IO.File]::Delete($Path) }
}
