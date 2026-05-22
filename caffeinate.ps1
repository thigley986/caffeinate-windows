<#
.SYNOPSIS
    Keep Windows awake AND looking active. A pragmatic mimic of macOS
    `caffeinate`, adapted for the realities of Windows power management.

.DESCRIPTION
    By default, caffeinate does three things:

      1. Holds ES_SYSTEM_REQUIRED + ES_DISPLAY_REQUIRED via the Win32
         SetThreadExecutionState API so the system and display will not
         sleep or blank due to idle.

      2. Sends a no-op VK_F15 keypress every 30 seconds. This resets the
         Windows user-idle timer, which is what governs the screen saver
         and most idle-based auto-lock policies. VK_F15 exists in the
         virtual-key table but no modern keyboard has the key, so no
         application reacts to it.

      3. Re-asserts the execution-state flags on every tick. Cheap,
         harmless, and noticeably improves reliability on Windows 11
         Modern Standby (S0 low-power idle) devices where a single
         initial call can be dropped after the OEM sleep window.

    On exit (Ctrl+C or the -t timer elapses) the flag is cleared in a
    `finally` block and normal power management resumes immediately.

    Limitations - things caffeinate intentionally does NOT do:
      * Override the Start menu Sleep action or `shutdown /h`
      * Defeat a closed laptop lid configured to sleep
      * Beat corporate Group Policy that auto-locks on session timeout
        (that's a separate policy from the user-idle timer)
      * Override OEM-managed Modern Standby battery behavior
      * Move the cursor or send any visible/audible input

.PARAMETER Seconds
    Run for N seconds, then release. Default: run until Ctrl+C.
    Aliased as -t to match macOS `caffeinate -t <seconds>`.

.PARAMETER Passive
    Hold the execution-state flags only - do NOT simulate input.
    Useful if you don't want any synthetic keystrokes hitting the
    foreground app.

.PARAMETER Display
    Accepted for backward compatibility; display-awake is on by default.
    Has no effect.

.EXAMPLE
    caffeinate
    Keep awake and active until Ctrl+C.

.EXAMPLE
    caffeinate -t 3600
    Keep awake and active for one hour.

.EXAMPLE
    caffeinate -Passive
    Hold the ES_SYSTEM_REQUIRED/ES_DISPLAY_REQUIRED flags only;
    no synthetic input.

.NOTES
    Project: https://github.com/thigley986/caffeinate-windows
    License: MIT
#>
[CmdletBinding()]
param(
    [Alias('t')]
    [int]$Seconds = 0,

    [Alias('p')]
    [switch]$Passive,

    [Alias('d')]
    [switch]$Display
)

$signature = @'
[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
public static extern uint SetThreadExecutionState(uint esFlags);

[DllImport("user32.dll", SetLastError = true)]
public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, System.UIntPtr dwExtraInfo);
'@

if (-not ('Win32.Power' -as [type])) {
    Add-Type -MemberDefinition $signature -Name Power -Namespace Win32
}

$ES_CONTINUOUS       = [uint32]'0x80000000'
$ES_SYSTEM_REQUIRED  = [uint32]'0x00000001'
$ES_DISPLAY_REQUIRED = [uint32]'0x00000002'

# Display is on by default. -Display is a no-op alias kept for muscle memory.
$flags = $ES_CONTINUOUS -bor $ES_SYSTEM_REQUIRED -bor $ES_DISPLAY_REQUIRED

$VK_F15          = [byte]0x7E
$KEYEVENTF_KEYUP = [uint32]0x0002

function Set-AwakeFlags {
    $r = [Win32.Power]::SetThreadExecutionState($flags)
    if ($r -eq 0) {
        $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        throw "SetThreadExecutionState failed (Win32 error $err)."
    }
}

function Send-NoOpInput {
    # VK_F15 down/up. No application binds F15; this only resets the idle timer.
    [Win32.Power]::keybd_event($VK_F15, 0, 0,                 [System.UIntPtr]::Zero)
    [Win32.Power]::keybd_event($VK_F15, 0, $KEYEVENTF_KEYUP,  [System.UIntPtr]::Zero)
}

# Initial flag set.
Set-AwakeFlags

$mode = if ($Passive) { 'system + display' } else { 'system + display + activity' }
if ($Seconds -gt 0) {
    Write-Host "caffeinate: $mode for $Seconds s. Ctrl+C to stop." -ForegroundColor Cyan
} else {
    Write-Host "caffeinate: $mode. Ctrl+C to stop." -ForegroundColor Cyan
}
Write-Host "  note: does not override lid-close, Start->Sleep, or corporate session-lock policies." -ForegroundColor DarkGray

$tick    = 30
$elapsed = 0
try {
    while ($true) {
        # Sleep one tick, but never past the requested timeout.
        $thisSleep = if ($Seconds -gt 0) {
            [Math]::Max(1, [Math]::Min($tick, $Seconds - $elapsed))
        } else {
            $tick
        }
        Start-Sleep -Seconds $thisSleep
        $elapsed += $thisSleep
        if ($Seconds -gt 0 -and $elapsed -ge $Seconds) { break }

        # Re-assert flags every tick. ES_CONTINUOUS is supposed to persist,
        # but on Modern Standby devices we've seen the request silently
        # dropped after the OEM sleep window. Reasserting is cheap.
        Set-AwakeFlags

        if (-not $Passive) { Send-NoOpInput }
    }
}
finally {
    [Win32.Power]::SetThreadExecutionState($ES_CONTINUOUS) | Out-Null
    Write-Host "caffeinate: released." -ForegroundColor Yellow
}
