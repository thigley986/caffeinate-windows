<#
.SYNOPSIS
    Install caffeinate-windows to a user directory and add it to PATH.

.DESCRIPTION
    Copies caffeinate.ps1 and caffeinate.cmd into the install directory
    (default: %USERPROFILE%\.local\bin) and adds that directory to the
    current user's PATH if it isn't already there.

    Works two ways:
      1. Local clone:  .\install.ps1
      2. Remote one-liner:
         irm https://raw.githubusercontent.com/thigley986/caffeinate-windows/main/install.ps1 | iex

.PARAMETER InstallDir
    Where to install the scripts. Default: $env:USERPROFILE\.local\bin

.PARAMETER Branch
    Branch to download from when running remotely. Default: main

.NOTES
    Project: https://github.com/thigley986/caffeinate-windows
    License: MIT
#>
[CmdletBinding()]
param(
    [string]$InstallDir = (Join-Path $env:USERPROFILE '.local\bin'),
    [string]$Branch = 'main'
)

$ErrorActionPreference = 'Stop'

# Edit these two lines before publishing to your fork.
$RepoOwner = 'thigley986'
$RepoName  = 'caffeinate-windows'

# 1. Make sure the install directory exists.
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    Write-Host "Created $InstallDir"
}

$psTarget  = Join-Path $InstallDir 'caffeinate.ps1'
$cmdTarget = Join-Path $InstallDir 'caffeinate.cmd'

# 2. Get the script source. $PSScriptRoot is empty when piped from `irm | iex`,
#    which is how we detect remote-install mode.
if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot 'caffeinate.ps1'))) {
    Write-Host "Installing from local clone: $PSScriptRoot"
    Copy-Item (Join-Path $PSScriptRoot 'caffeinate.ps1') $psTarget  -Force
    Copy-Item (Join-Path $PSScriptRoot 'caffeinate.cmd') $cmdTarget -Force
} else {
    $base = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch"
    Write-Host "Downloading from $base"
    Invoke-WebRequest "$base/caffeinate.ps1" -OutFile $psTarget  -UseBasicParsing
    Invoke-WebRequest "$base/caffeinate.cmd" -OutFile $cmdTarget -UseBasicParsing
}

Write-Host "Installed:"
Write-Host "  $psTarget"
Write-Host "  $cmdTarget"

# 3. Add the install directory to user PATH if it isn't already.
$userPath = [Environment]::GetEnvironmentVariable('PATH', 'User')
$dirs = if ($userPath) { $userPath -split ';' | Where-Object { $_ -ne '' } } else { @() }

$alreadyOnPath = $false
foreach ($d in $dirs) {
    if ([System.IO.Path]::GetFullPath($d).TrimEnd('\') -ieq
        [System.IO.Path]::GetFullPath($InstallDir).TrimEnd('\')) {
        $alreadyOnPath = $true
        break
    }
}

if ($alreadyOnPath) {
    Write-Host "$InstallDir is already on your user PATH." -ForegroundColor Green
} else {
    $newPath = (@($dirs) + $InstallDir) -join ';'
    [Environment]::SetEnvironmentVariable('PATH', $newPath, 'User')
    Write-Host "Added $InstallDir to your user PATH." -ForegroundColor Green
    Write-Host "Open a new terminal for the PATH change to take effect." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Done. Try it out (after opening a new terminal if PATH changed):" -ForegroundColor Cyan
Write-Host "  caffeinate -t 5"
