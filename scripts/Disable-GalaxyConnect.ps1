# ==============================================================================
# Galaxy Connect Enabler - Uninstaller & System Restorer
# ==============================================================================

Write-Host "=================================================================" -ForegroundColor Yellow
Write-Host "             GALAXY CONNECT ENABLER - RESTORE / UNINSTALL" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Yellow

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
    Write-Warning "Administrator privileges required. Please run Disable-GalaxyConnect.bat."
    exit 1
}

# 1. Remove Scheduled Tasks & Run Keys
Write-Host "`n[1/3] Removing persistence tasks..." -ForegroundColor Green
Unregister-ScheduledTask -TaskName "GalaxyConnectEnabler-Boot" -Confirm:$false -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "GalaxyConnectEnabler" -ErrorAction SilentlyContinue
Write-Host "  -> Persistence tasks removed." -ForegroundColor Gray

# 2. Restore Original BIOS Values
Write-Host "`n[2/3] Restoring original BIOS values..." -ForegroundColor Green
$backupFile = "$env:LOCALAPPDATA\GalaxyConnectEnabler\original-bios.json"

if (Test-Path $backupFile) {
    $orig = Get-Content $backupFile | ConvertFrom-Json
    $biosPath = "HKLM:\HARDWARE\DESCRIPTION\System\BIOS"
    
    if ($orig.SystemManufacturer) { Set-ItemProperty -Path $biosPath -Name "SystemManufacturer" -Value $orig.SystemManufacturer -Force }
    if ($orig.SystemProductName) { Set-ItemProperty -Path $biosPath -Name "SystemProductName" -Value $orig.SystemProductName -Force }
    if ($orig.SystemFamily) { Set-ItemProperty -Path $biosPath -Name "SystemFamily" -Value $orig.SystemFamily -Force }
    if ($orig.BaseBoardManufacturer) { Set-ItemProperty -Path $biosPath -Name "BaseBoardManufacturer" -Value $orig.BaseBoardManufacturer -Force }
    if ($orig.EnclosureType) { Set-ItemProperty -Path $biosPath -Name "EnclosureType" -Value $orig.EnclosureType -Type DWord -Force }

    Write-Host "  -> Restored SystemManufacturer to: $($orig.SystemManufacturer)" -ForegroundColor Gray
    Write-Host "  -> Restored EnclosureType to: $($orig.EnclosureType)" -ForegroundColor Gray
} else {
    Write-Host "  -> No backup file found. Setting default genuine LENOVO values..." -ForegroundColor Yellow
    Set-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -Name "SystemManufacturer" -Value "LENOVO" -Force
    Set-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -Name "EnclosureType" -Value 10 -Type DWord -Force
}

# 3. Clean up Test Flags
Write-Host "`n[3/3] Cleaning up engineering test flags..." -ForegroundColor Green
$flags = @("TestEnable.MC", "TestGCE.MC", "TestFamily.MC")
$dirs = @(
    "$env:LOCALAPPDATA\Packages\SAMSUNGELECTRONICSCoLtd.MultiControl_wyx1vj98g3asy\LocalState",
    "$env:LOCALAPPDATA\Packages\SAMSUNGELECTRONICSCoLtd.SamsungMyDevices_wyx1vj98g3asy\LocalState"
)
foreach ($d in $dirs) {
    foreach ($f in $flags) {
        $fp = Join-Path $d $f
        if (Test-Path $fp) { Remove-Item -Path $fp -Force -ErrorAction SilentlyContinue }
    }
}
Write-Host "  -> Test flags removed." -ForegroundColor Gray

Write-Host "`n=================================================================" -ForegroundColor Green
Write-Host "  RESTORE COMPLETE! BIOS and settings restored." -ForegroundColor Green
Write-Host "=================================================================`n" -ForegroundColor Green
