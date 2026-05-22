<#
.SYNOPSIS
    Uninstall caffeinate-windows.

.DESCRIPTION
    Removes caffeinate.ps1 and caffeinate.cmd from the install directory
    (default: %USERPROFILE%\.local\bin). Optionally also removes the
    install directory from the user PATH.

.PARAMETER InstallDir
    Where caffeinate was installed. Default: $env:USERPROFILE\.local\bin

.PARAMETER RemoveFromPath
    Also remove the install directory from your user PATH.
    Only does so if the directory is now empty after removing caffeinate.

.NOTES
    Project: https://github.com/thigley986/caffeinate-windows
    License: MIT
#>
[CmdletBinding()]
param(
    [string]$InstallDir = (Join-Path $env:USERPROFILE '.local\bin'),
    [switch]$RemoveFromPath
)

$ErrorActionPreference = 'Stop'

$ps  = Join-Path $InstallDir 'caffeinate.ps1'
$cmd = Join-Path $InstallDir 'caffeinate.cmd'

foreach ($f in @($ps, $cmd)) {
    if (Test-Path $f) {
        Remove-Item $f -Force
        Write-Host "Removed $f"
    }
}

if ($RemoveFromPath) {
    if ((Test-Path $InstallDir) -and
        (Get-ChildItem $InstallDir -Force | Measure-Object).Count -gt 0) {
        Write-Host "$InstallDir is not empty; leaving it on PATH." -ForegroundColor Yellow
    } else {
        $userPath = [Environment]::GetEnvironmentVariable('PATH', 'User')
        $dirs = if ($userPath) { $userPath -split ';' | Where-Object { $_ -ne '' } } else { @() }
        $target = [System.IO.Path]::GetFullPath($InstallDir).TrimEnd('\')
        $kept = $dirs | Where-Object {
            [System.IO.Path]::GetFullPath($_).TrimEnd('\') -ine $target
        }
        if ($kept.Count -ne $dirs.Count) {
            [Environment]::SetEnvironmentVariable('PATH', ($kept -join ';'), 'User')
            Write-Host "Removed $InstallDir from your user PATH." -ForegroundColor Green
            Write-Host "Open a new terminal for the PATH change to take effect." -ForegroundColor Yellow
        }
    }
}

Write-Host "Uninstall complete."
