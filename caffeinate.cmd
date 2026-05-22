@echo off
rem caffeinate.cmd - wrapper so `caffeinate` works from cmd.exe and PowerShell.
rem Prefers PowerShell 7 (pwsh) if available, falls back to Windows PowerShell.
where pwsh >nul 2>nul
if %ERRORLEVEL%==0 (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0caffeinate.ps1" %*
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0caffeinate.ps1" %*
)
