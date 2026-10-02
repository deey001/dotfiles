<#
Remove the symlinks created by install.ps1 and restore the files it backed up
on its first run. Packages and the repo itself are left alone.
#>

$Dotfiles = Split-Path (Split-Path $PSCommandPath)
. "$Dotfiles\install\windows\links.ps1"

foreach ($target in $Links.Keys) {
    if (Test-Linked $target (Join-Path $Dotfiles $Links[$target])) {
        Remove-Link $target
        Write-Host "  removed $target"
    }
}

# The oldest backup holds the files that existed before the dotfiles were installed.
$backup = Get-ChildItem "$HOME\.dotfiles-backup" -Directory -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -First 1
if ($backup) {
    foreach ($target in $Links.Keys) {
        $saved = Get-BackupPath $backup.FullName $target
        if (-not (Test-Path -LiteralPath $saved)) { continue }
        if (Test-Path -LiteralPath $target) {
            Write-Host "  kept existing $target (backup left in $($backup.FullName))"
        } else {
            New-Item -ItemType Directory (Split-Path $target) -Force | Out-Null
            Move-Item -LiteralPath $saved $target
            Write-Host "  restored $target"
        }
    }
}

# PuTTY sessions as they were before the first install. Importing overwrites the
# values install.ps1 changed; sessions created since then are left alone.
$putty = Get-ChildItem "$HOME\.dotfiles-backup" -Recurse -Filter putty-sessions.reg -ErrorAction SilentlyContinue |
    Sort-Object FullName | Select-Object -First 1
if ($putty) {
    reg import $putty.FullName 2>$null
    Write-Host '  restored PuTTY sessions'
}
