<#
.SYNOPSIS
    Keep Windows awake. A drop-in mimic of macOS `caffeinate`.

.DESCRIPTION
    Uses the Win32 SetThreadExecutionState API to tell Windows that work
    is in progress, so the machine won't sleep. When the script exits
    (Ctrl+C or the timer elapses) the state is cleared and normal power
    management resumes.

.PARAMETER Seconds
    Run for N seconds, then release. Default: run until Ctrl+C.
    Aliased as -t to match macOS `caffeinate -t <seconds>`.

.PARAMETER Display
    Also keep the display awake (prevent screen blanking).
    Aliased as -d to match macOS `caffeinate -d`.

.EXAMPLE
    caffeinate
    Keep awake until Ctrl+C.

.EXAMPLE
    caffeinate -t 3600
    Keep awake for one hour.

.EXAMPLE
    caffeinate -d
    Keep awake AND keep the display on, until Ctrl+C.

.NOTES
    Project: https://github.com/thigley986/caffeinate-windows
    License: MIT
#>
[CmdletBinding()]
param(
    [Alias('t')]
    [int]$Seconds = 0,

    [Alias('d')]
    [switch]$Display
)

$signature = @'
[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
public static extern uint SetThreadExecutionState(uint esFlags);
'@

if (-not ('Win32.Power' -as [type])) {
    Add-Type -MemberDefinition $signature -Name Power -Namespace Win32
}

$ES_CONTINUOUS       = [uint32]'0x80000000'
$ES_SYSTEM_REQUIRED  = [uint32]'0x00000001'
$ES_DISPLAY_REQUIRED = [uint32]'0x00000002'

$flags = $ES_CONTINUOUS -bor $ES_SYSTEM_REQUIRED
if ($Display) { $flags = $flags -bor $ES_DISPLAY_REQUIRED }

$prior = [Win32.Power]::SetThreadExecutionState($flags)
if ($prior -eq 0) {
    Write-Error "SetThreadExecutionState failed."
    exit 1
}

$mode = if ($Display) { 'system + display' } else { 'system' }
if ($Seconds -gt 0) {
    Write-Host "caffeinate: keeping awake ($mode) for $Seconds s. Ctrl+C to stop." -ForegroundColor Cyan
} else {
    Write-Host "caffeinate: keeping awake ($mode). Ctrl+C to stop." -ForegroundColor Cyan
}

try {
    if ($Seconds -gt 0) {
        Start-Sleep -Seconds $Seconds
    } else {
        while ($true) { Start-Sleep -Seconds 60 }
    }
}
finally {
    [Win32.Power]::SetThreadExecutionState($ES_CONTINUOUS) | Out-Null
    Write-Host "caffeinate: released." -ForegroundColor Yellow
}
