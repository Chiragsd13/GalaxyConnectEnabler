@echo off
:: Self-elevating launcher for Galaxy Connect Enabler Uninstaller
title Galaxy Connect Enabler - Restore
cd /d "%~dp0"

net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo [INFO] Requesting Administrator privileges...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

if exist "%ProgramFiles%\PowerShell\7\pwsh.exe" (
    "%ProgramFiles%\PowerShell\7\pwsh.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Disable-GalaxyConnect.ps1"
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Disable-GalaxyConnect.ps1"
)

echo.
echo =================================================================
echo   Restore completed! Press any key to exit.
echo =================================================================
pause >nul
