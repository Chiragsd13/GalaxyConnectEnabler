@echo off
title Galaxy Connect Enabler - Status Check
cd /d "%~dp0"

if exist "%ProgramFiles%\PowerShell\7\pwsh.exe" (
    "%ProgramFiles%\PowerShell\7\pwsh.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Check-Status.ps1"
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Check-Status.ps1"
)

echo.
pause
