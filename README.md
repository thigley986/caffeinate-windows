# caffeinate-windows

A `caffeinate` command for Windows. Inspired by macOS's `caffeinate`, but adapted for the realities of Windows power management — it doesn't just hold a "system required" flag, it also looks active to Windows so the screen saver and idle-based auto-lock don't kick in.

- No background service, no scheduled task, no registry edits
- No mouse jiggling — uses the Win32 `SetThreadExecutionState` API plus a single `VK_F15` keypress every 30 s (a key that exists in the virtual-key table but no modern keyboard has, so nothing reacts to it)
- Two small scripts on your PATH — that's it
- Works from `cmd.exe`, Windows PowerShell, and PowerShell 7+

## Install

### One-liner (PowerShell)

```powershell
irm https://raw.githubusercontent.com/thigley986/caffeinate-windows/main/install.ps1 | iex
```

This downloads `caffeinate.ps1` and `caffeinate.cmd` into `%USERPROFILE%\.local\bin` and adds that directory to your user PATH if it isn't already on it.

Open a new terminal afterward so the PATH change takes effect.

### From a clone

```powershell
git clone https://github.com/thigley986/caffeinate-windows.git
cd caffeinate-windows
.\install.ps1
```

### Manual

Copy `caffeinate.ps1` and `caffeinate.cmd` into any directory that's already on your PATH.

### Custom install location

```powershell
.\install.ps1 -InstallDir 'C:\tools\bin'
```

## Usage

| Command                  | What it does                                                  |
| ------------------------ | ------------------------------------------------------------- |
| `caffeinate`             | System + display awake + simulate activity, until Ctrl+C       |
| `caffeinate -t 3600`     | Same, for one hour                                             |
| `caffeinate -Passive`    | Hold ES flags only — no synthetic keypress                     |

`-t` takes seconds (matches macOS `caffeinate -t`). `-Seconds` and `-Passive` are the PowerShell-native parameter names. `-d` / `-Display` is accepted for muscle-memory compatibility but is a no-op now that display-awake is on by default.

Works identically from `cmd.exe`, Windows PowerShell, and PowerShell 7+ thanks to the `.cmd` wrapper.

## How it works

Three layers, because on Windows none of them alone is enough:

1. **`SetThreadExecutionState(ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED)`** — the official Windows mechanism for a process to declare "I'm doing work — don't sleep on me." Prevents idle sleep and display blanking due to inactivity.
2. **A `VK_F15` keypress every 30 s** — resets the user-idle timer. This is what governs the screen saver, screen-saver password prompt, and idle-based auto-lock. `ES_*` flags don't touch the user-idle timer. F15 is used because it's a real virtual key code but no application binds it.
3. **Re-assertion of the `ES_*` flags every 30 s** — `ES_CONTINUOUS` is supposed to persist until cleared, and usually it does, but on some Windows 11 Modern Standby devices the request is silently dropped after the OEM sleep window. Reasserting is cheap.

When the script exits — Ctrl+C or `-t` timer elapses — a `finally` block clears the flag and Windows resumes normal power management immediately.

The `caffeinate.cmd` wrapper exists so the command works from `cmd.exe` (cmd doesn't auto-execute `.ps1` files). It prefers PowerShell 7 (`pwsh`) and falls back to Windows PowerShell 5.1.

## What it does NOT do

Being honest about scope:

- It does not override the Start menu **Sleep** action, `shutdown /h`, or anything user-initiated
- It does not defeat a **closed laptop lid** configured to sleep
- It does not beat corporate **Group Policy session-timeout locks** — those run on a different timer than the user-idle timer and are unreachable from user space
- It does not override **OEM-managed Modern Standby** battery behavior
- It does not move the mouse cursor or send any input you'd see or hear

On a corporate-managed machine, run `powercfg /requests` from an **elevated** prompt while `caffeinate` is running to confirm Windows is honoring the request. If you see a `pwsh.exe` or `powershell.exe` entry under the `SYSTEM:` section pointing to `caffeinate.ps1`, the API call is being honored. If you're still seeing the screen lock, the cause is auto-lock policy (separate from sleep) — `caffeinate` already addresses the most common version of that with the F15 ping, but a hard-enforced GPO session timeout will still win.

## Requirements

- Windows 10 or 11 (Windows PowerShell 5.1 ships with both; PowerShell 7 used automatically if present)
- No admin rights needed — installs into your user profile

## Uninstall

```powershell
.\uninstall.ps1
```

To also remove the install directory from your user PATH (only if the dir is empty afterward):

```powershell
.\uninstall.ps1 -RemoveFromPath
```

Or just delete `caffeinate.ps1` and `caffeinate.cmd` from `%USERPROFILE%\.local\bin`.

## Repository layout

```
caffeinate-windows/
├── caffeinate.ps1   # the actual script
├── caffeinate.cmd   # wrapper for cmd.exe / convenience
├── install.ps1      # copies the two files into place, updates PATH
├── uninstall.ps1    # reverses the install
├── LICENSE          # MIT
└── README.md
```

## License

MIT — see [LICENSE](LICENSE).
