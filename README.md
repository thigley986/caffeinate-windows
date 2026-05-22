# caffeinate-windows

A `caffeinate` command for Windows, built to feel exactly like macOS's `caffeinate`. Keeps your PC awake while it's running, then restores normal power management the moment it exits.

- No background service, no scheduled task, no registry edits
- No fake mouse jiggling or simulated keystrokes
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

Copy `caffeinate.ps1` and `caffeinate.cmd` into any directory that's already on your PATH. That's the whole install.

### Custom install location

```powershell
.\install.ps1 -InstallDir 'C:\tools\bin'
```

## Usage

| Command                  | What it does                                  |
| ------------------------ | --------------------------------------------- |
| `caffeinate`             | Keep awake until Ctrl+C                        |
| `caffeinate -t 3600`     | Keep awake for 1 hour                          |
| `caffeinate -d`          | Also keep the display on                       |
| `caffeinate -d -t 1800`  | Display on + system awake for 30 minutes       |

`-t` takes seconds (matches macOS `caffeinate -t`). `-Seconds` and `-Display` are the PowerShell-native parameter names if you'd rather spell them out.

Works identically from `cmd.exe`, Windows PowerShell, and PowerShell 7+ thanks to the `.cmd` wrapper.

## Requirements

- Windows 10 or 11 (anything with built-in Windows PowerShell 5.1, or PowerShell 7+)
- No admin rights needed — installs into your user profile

## How it works

`caffeinate.ps1` calls the Win32 [`SetThreadExecutionState`](https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-setthreadexecutionstate) API with `ES_CONTINUOUS | ES_SYSTEM_REQUIRED` (and `ES_DISPLAY_REQUIRED` when you pass `-d`). This is the official Windows mechanism for a process to declare "I'm doing work — don't sleep on me." It's what media players, backup tools, and installers use.

When the script exits — whether you hit Ctrl+C or the `-t` timer elapses — a `finally` block clears the flag, and Windows resumes normal power management immediately. There's nothing left running, nothing left to clean up, and nothing persists across reboots.

`caffeinate.cmd` is a four-line wrapper that lets you call `caffeinate` from `cmd.exe` too, since cmd doesn't auto-execute `.ps1` files. It prefers PowerShell 7 (`pwsh`) if installed, otherwise falls back to Windows PowerShell.

## Uninstall

```powershell
.\uninstall.ps1
```

To also remove the install directory from your user PATH (only does so if the dir is empty after removing the scripts):

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
