# ==============================================================================
# Galaxy Connect Enabler - Diagnostic & Status Checker (v1.1.0)
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
    Write-Host "  • System Manufacturer : $mfg [NOT SPOOFED - RUN Enable-GalaxyConnect.bat]" -ForegroundColor Red
}

if ($enc -eq 3) {
    Write-Host "  • Enclosure Type      : $enc (Desktop Mode - Wi-Fi Whitelist Bypassed) [OK]" -ForegroundColor Green
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
        Write-Host "  • Flag $f : Active in MultiControl & NearbyDevices [OK]" -ForegroundColor Green
    } else {
        Write-Host "  • Flag $f : Missing (MC: $mcOk, ND: $ndOk) [WARNING]" -ForegroundColor Yellow
    }
}

# 4. Windows Services
Write-Host "`n[4] Background Services Status:" -ForegroundColor Yellow
$servicesToCheck = @(
    @{ Name = "SamsungContinuityWindowsService"; Label = "Galaxy Connect Continuity" },
    @{ Name = "Samsung Multi Control Service";   Label = "Multi Control Service" },
    @{ Name = "NetTcpPortSharing";               Label = "WCF Net.Tcp Port Sharing" },
    @{ Name = "lfsvc";                           Label = "Geolocation Service" }
)
foreach ($s in $servicesToCheck) {
    $svc = Get-Service -Name $s.Name -ErrorAction SilentlyContinue
    if (-not $svc -and $s.Name -eq "Samsung Multi Control Service") {
        $svc = Get-Service -Name "SamsungMultiControlService" -ErrorAction SilentlyContinue
    }
    if ($svc -and $svc.Status -eq "Running") {
        Write-Host "  • $($s.Label) ($($svc.Name)) : RUNNING [OK]" -ForegroundColor Green
    } else {
        Write-Host "  • $($s.Label) ($($s.Name)) : $(if ($svc) { $svc.Status } else { 'Not Installed' }) [WARNING]" -ForegroundColor Yellow
    }
}

# 5. Network Category & Firewall
Write-Host "`n[5] Network & Firewall Status:" -ForegroundColor Yellow
try {
    $net = Get-NetConnectionProfile -InterfaceAlias "*Wi-Fi*" -ErrorAction SilentlyContinue
    if ($net) {
        Write-Host "  • Wi-Fi Network       : $($net.Name) (Category: $($net.NetworkCategory))" -ForegroundColor Gray
        if ($net.NetworkCategory -eq "Public") {
            Write-Host "    [!] Note: Campus / Public Wi-Fi may enable AP isolation. If Multi Control drops, ensure both devices are on Mobile Hotspot or Wi-Fi Direct." -ForegroundColor DarkYellow
        }
    }
} catch {}

$fw = Get-NetFirewallRule -DisplayName "Samsung Galaxy *" -ErrorAction SilentlyContinue
if ($fw) {
    Write-Host "  • Firewall Rules      : Active ($($fw.Count) inbound rules configured for Any Profile) [OK]" -ForegroundColor Green
} else {
    Write-Host "  • Firewall Rules      : Custom rules not found [WARNING - Run Enable-GalaxyConnect.bat]" -ForegroundColor Yellow
}

# 6. Bluetooth Paired Devices
Write-Host "`n[6] Bluetooth Devices:" -ForegroundColor Yellow
try {
    $bt = Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -match 'Tab|Galaxy|Buds|Phone|S2\d|S25' }
    if ($bt) {
        $bt | Select-Object -ExpandProperty FriendlyName -Unique | ForEach-Object {
            Write-Host "  • Paired Device       : $_" -ForegroundColor Green
        }
    } else {
        Write-Host "  • No Samsung Bluetooth devices found paired." -ForegroundColor DarkGray
    }
} catch {}

# 7. Running Processes
Write-Host "`n[7] Active Samsung Ecosystem Processes:" -ForegroundColor Yellow
$procs = Get-Process -Name "*Continuity*", "*MCF*", "*MultiControl*", "*NearbyDevices*" -ErrorAction SilentlyContinue
if ($procs) {
    $procs | ForEach-Object {
        Write-Host "  • PID $($_.Id.ToString().PadRight(6)) : $($_.ProcessName)" -ForegroundColor Green
    }
} else {
    Write-Host "  • No Samsung ecosystem processes currently running." -ForegroundColor Yellow
}

# 8. Connected Devices Settings
Write-Host "`n[8] Multi Control Settings Cache:" -ForegroundColor Yellow
$mcDat = "C:\ProgramData\Samsung\SamsungMultiControl\Settings\MCCoreSettings.dat"
if (Test-Path $mcDat) {
    Get-Content $mcDat | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
