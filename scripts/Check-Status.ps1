# ==============================================================================
# Galaxy Connect Enabler - Diagnostic & Status Checker (v1.2.0)
# ==============================================================================

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "             GALAXY CONNECT ENABLER - SYSTEM STATUS" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 0. Hardware & Environment Audit
Write-Host "`n[0] Hardware & Environment Profile:" -ForegroundColor Yellow
$cpuObj = Get-CimInstance Win32_Processor | Select-Object -First 1
$cpuName = if ($cpuObj.Name) { $cpuObj.Name.Trim() } else { "Unknown Processor" }
$cpuVendor = if ($cpuObj.Manufacturer -match "AuthenticAMD|AMD") { "AMD" } elseif ($cpuObj.Manufacturer -match "GenuineIntel|Intel") { "Intel" } elseif ($cpuObj.Manufacturer -match "Qualcomm") { "Qualcomm" } else { "Other" }
$cpuArch = if ($env:PROCESSOR_ARCHITECTURE) { $env:PROCESSOR_ARCHITECTURE } else { "x64" }

$wifiAdapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { 
    $_.PhysicalMediaType -match 'Native 802.11|Wireless' -or 
    $_.InterfaceDescription -match 'Wi-Fi|Wireless|802.11|WLAN' 
}
$wifiObj = $wifiAdapters | Select-Object -First 1
$wifiDesc = if ($wifiObj) { $wifiObj.InterfaceDescription.Trim() } else { "No Wi-Fi Adapter Found" }

$wifiVendor = "Generic"
if ($wifiDesc -match "MediaTek|MT79|RZ60|RZ61") { $wifiVendor = "MediaTek" }
elseif ($wifiDesc -match "Realtek|RTL88")       { $wifiVendor = "Realtek" }
elseif ($wifiDesc -match "Qualcomm|QCA|Atheros") { $wifiVendor = "Qualcomm" }
elseif ($wifiDesc -match "Intel")               { $wifiVendor = "Intel" }

$btDev = Get-PnpDevice -Class Bluetooth -Status OK -ErrorAction SilentlyContinue | Where-Object { 
    $_.InstanceId -match 'USB|PCI' 
} | Select-Object -First 1
$btName = if ($btDev) { $btDev.FriendlyName } else { "Generic Bluetooth Adapter" }

$cs = Get-CimInstance Win32_ComputerSystem
$bb = Get-CimInstance Win32_BaseBoard
$se = Get-CimInstance Win32_SystemEnclosure
$chassisCode = ($se.ChassisTypes -join ', ')

$gbeDir = Join-Path $env:USERPROFILE ".galaxy-book-enabler"
$hasGBE = (Test-Path $gbeDir) -or (Get-ScheduledTask -TaskName "*GalaxyBook*" -ErrorAction SilentlyContinue)

Write-Host "  • Processor           : $cpuName ($cpuArch)" -ForegroundColor Gray
Write-Host "  • Wi-Fi Adapter       : $wifiDesc [$wifiVendor]" -ForegroundColor $(if ($wifiVendor -in @("MediaTek", "Realtek")) { "Yellow" } else { "Green" })
Write-Host "  • Bluetooth           : $btName" -ForegroundColor Gray
Write-Host "  • Physical System     : $($cs.Manufacturer) $($cs.Model) (Chassis: $chassisCode)" -ForegroundColor Gray
Write-Host "  • GBE Interoperability: $(if ($hasGBE) { 'Galaxy Book Enabler Active (Coexistence Mode)' } else { 'Standalone Enabler Mode' })" -ForegroundColor $(if ($hasGBE) { "Cyan" } else { "Green" })

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
$userSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$mdeHklm = (reg query "HKLM\Software\SAMSUNG\SamsungContinuityService\FamilyMDE" /v Settings 2>$null | Select-String "0x1")
$mdeHkcu = (reg query "HKCU\Software\SAMSUNG\SamsungContinuityService\FamilyMDE" /v Settings 2>$null | Select-String "0x1")
$mdeSid  = if ($userSid) { (reg query "HKEY_USERS\$userSid\Software\SAMSUNG\SamsungContinuityService\FamilyMDE" /v Settings 2>$null | Select-String "0x1") } else { $null }

if ($mdeHklm) {
    Write-Host "  • HKLM FamilyMDE      : Active (Settings=1) [OK]" -ForegroundColor Green
} else {
    Write-Host "  • HKLM FamilyMDE      : Missing or Disabled [FAIL]" -ForegroundColor Red
}

if ($mdeHkcu -or $mdeSid) {
    Write-Host "  • HKCU / User SID     : Active (Settings=1 in user session) [OK]" -ForegroundColor Green
} else {
    Write-Host "  • HKCU / User SID     : Missing or Disabled [FAIL]" -ForegroundColor Red
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
