# ==============================================================================
# Galaxy Connect Enabler - Diagnostic & Status Checker
# ==============================================================================

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "             GALAXY CONNECT ENABLER - SYSTEM STATUS" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. BIOS Status
Write-Host "`n[1] BIOS & Hardware Spoof Status:" -ForegroundColor Yellow
$bios = Get-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -ErrorAction SilentlyContinue
$mfg = $bios.SystemManufacturer
$enc = $bios.EnclosureType
$prod = $bios.SystemProductName

if ($mfg -match "SAMSUNG") {
    Write-Host "  • System Manufacturer : $mfg [OK]" -ForegroundColor Green
} else {
    Write-Host "  • System Manufacturer : $mfg [NOT SPOOFED]" -ForegroundColor Red
}

if ($enc -eq 3) {
    Write-Host "  • Enclosure Type      : $enc (Desktop Mode - Whitelist Bypassed) [OK]" -ForegroundColor Green
} else {
    Write-Host "  • Enclosure Type      : $enc (Laptop Mode - Non-Intel Wi-Fi May Be Blocked) [WARNING]" -ForegroundColor Yellow
}
Write-Host "  • Product Model       : $prod" -ForegroundColor Gray

# 2. FamilyMDE Registry
Write-Host "`n[2] Cross-Device P2P (FamilyMDE) Status:" -ForegroundColor Yellow
$mdeHklm = (Get-ItemProperty -Path "HKLM:\Software\SAMSUNG\SamsungContinuityService\FamilyMDE" -ErrorAction SilentlyContinue).Settings
$mdeHkcu = (Get-ItemProperty -Path "HKCU:\Software\SAMSUNG\SamsungContinuityService\FamilyMDE" -ErrorAction SilentlyContinue).Settings

if ($mdeHklm -eq 1) {
    Write-Host "  • HKLM FamilyMDE      : $mdeHklm [OK]" -ForegroundColor Green
} else {
    Write-Host "  • HKLM FamilyMDE      : Missing or Disabled [FAIL]" -ForegroundColor Red
}

if ($mdeHkcu -eq 1) {
    Write-Host "  • HKCU FamilyMDE      : $mdeHkcu [OK]" -ForegroundColor Green
} else {
    Write-Host "  • HKCU FamilyMDE      : Missing or Disabled [FAIL]" -ForegroundColor Red
}

# 3. LocalState Engineering Flags
Write-Host "`n[3] Engineering Test Flags:" -ForegroundColor Yellow
$mcFlags = "$env:LOCALAPPDATA\Packages\SAMSUNGELECTRONICSCoLtd.MultiControl_wyx1vj98g3asy\LocalState"
$ndFlags = "$env:LOCALAPPDATA\Packages\SAMSUNGELECTRONICSCoLtd.SamsungMyDevices_wyx1vj98g3asy\LocalState"

foreach ($f in @("TestEnable.MC", "TestGCE.MC", "TestFamily.MC")) {
    $mcOk = Test-Path (Join-Path $mcFlags $f)
    $ndOk = Test-Path (Join-Path $ndFlags $f)
    if ($mcOk -and $ndOk) {
        Write-Host "  • Flag $f : Present in MultiControl & NearbyDevices [OK]" -ForegroundColor Green
    } else {
        Write-Host "  • Flag $f : Missing (MC: $mcOk, ND: $ndOk) [WARNING]" -ForegroundColor Yellow
    }
}

# 4. Windows Services
Write-Host "`n[4] Background Services Status:" -ForegroundColor Yellow
$services = @("SamsungContinuityWindowsService", "SamsungMultiControlService", "NetTcpPortSharing", "lfsvc")
foreach ($s in $services) {
    $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -eq "Running") {
        Write-Host "  • Service $($svc.DisplayName) ($s) : RUNNING [OK]" -ForegroundColor Green
    } else {
        Write-Host "  • Service $s : $(if ($svc) { $svc.Status } else { 'Not Found' }) [WARNING]" -ForegroundColor Yellow
    }
}

# 5. Running Processes
Write-Host "`n[5] Active Samsung Processes:" -ForegroundColor Yellow
$procs = Get-Process -Name "*Continuity*", "*MCF*", "*MultiControl*", "*NearbyDevices*" -ErrorAction SilentlyContinue
if ($procs) {
    $procs | ForEach-Object {
        Write-Host "  • PID $($_.Id.ToString().PadRight(6)) : $($_.ProcessName)" -ForegroundColor Green
    }
} else {
    Write-Host "  • No Samsung processes currently running." -ForegroundColor Yellow
}

# 6. Connected Devices
Write-Host "`n[6] Multi Control Settings Cache:" -ForegroundColor Yellow
$mcDat = "C:\ProgramData\Samsung\SamsungMultiControl\Settings\MCCoreSettings.dat"
if (Test-Path $mcDat) {
    Get-Content $mcDat | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
