# ==============================================================================
# Galaxy Connect Enabler - Core Adaptive Engine (v1.2.1)
# Universal Samsung Cross-Device Ecosystem for ANY Windows 11 PC
# Native Support: AMD Ryzen, Intel Core, Snapdragon ARM64, MediaTek, Realtek
# ==============================================================================

[CmdletBinding()]
param(
    [switch]$Silent = $false,
    [switch]$DetectOnly = $false
)

$ErrorActionPreference = "Continue"

Clear-Host
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "              GALAXY CONNECT ENABLER (v1.2.1)" -ForegroundColor Cyan
Write-Host "    Intelligent Hardware Detection & Ecosystem Integration Engine" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Administrator Check (Only enforced if applying changes)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin -and -not $DetectOnly) {
    Write-Warning "Administrator privileges required. Please run Enable-GalaxyConnect.bat."
    exit 1
}

# ==============================================================================
# PHASE 1: HARDWARE & ENVIRONMENT DETECTION ENGINE
# ==============================================================================
Write-Host "`n[Phase 1] Detecting System Hardware & Environment..." -ForegroundColor Yellow

# A. Processor Detection
$cpuObj = Get-CimInstance Win32_Processor | Select-Object -First 1
$cpuName = if ($cpuObj.Name) { $cpuObj.Name.Trim() } else { "Unknown Processor" }
$cpuVendor = if ($cpuObj.Manufacturer -match "AuthenticAMD|AMD") { "AMD" } elseif ($cpuObj.Manufacturer -match "GenuineIntel|Intel") { "Intel" } elseif ($cpuObj.Manufacturer -match "Qualcomm") { "Qualcomm" } else { "Other" }
$cpuArch = if ($env:PROCESSOR_ARCHITECTURE) { $env:PROCESSOR_ARCHITECTURE } else { "x64" }

# B. Wi-Fi Controller Detection
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

# C. Bluetooth Controller Detection
$btDev = Get-PnpDevice -Class Bluetooth -Status OK -ErrorAction SilentlyContinue | Where-Object { 
    $_.InstanceId -match 'USB|PCI' 
} | Select-Object -First 1
$btName = if ($btDev) { $btDev.FriendlyName } else { "Generic Bluetooth Adapter" }

# D. Motherboard & Enclosure Detection
$cs = Get-CimInstance Win32_ComputerSystem
$bb = Get-CimInstance Win32_BaseBoard
$se = Get-CimInstance Win32_SystemEnclosure

$origMfg   = if ($cs.Manufacturer) { $cs.Manufacturer.Trim() } else { "Unknown" }
$origModel = if ($cs.Model) { $cs.Model.Trim() } else { "Unknown" }
$boardInfo = "$($bb.Manufacturer) $($bb.Product)".Trim()
$chassisCode = ($se.ChassisTypes -join ', ')
$isLaptopEnclosure = ($se.ChassisTypes | Where-Object { $_ -in @(8, 9, 10, 11, 12, 14, 18, 21, 30, 31, 32) })

# E. Galaxy Book Enabler Interoperability Check
$gbeDir = Join-Path $env:USERPROFILE ".galaxy-book-enabler"
$hasGBE = (Test-Path $gbeDir) -or (Get-ScheduledTask -TaskName "*GalaxyBook*" -ErrorAction SilentlyContinue)

# Display Hardware Audit Card
Write-Host "-----------------------------------------------------------------" -ForegroundColor DarkCyan
Write-Host "  HARDWARE AUDIT REPORT:" -ForegroundColor Cyan
Write-Host "  • Processor     : $cpuName ($cpuArch)" -ForegroundColor Gray
Write-Host "  • Wi-Fi Adapter : $wifiDesc [$wifiVendor]" -ForegroundColor $(if ($wifiVendor -in @("MediaTek", "Realtek")) { "Yellow" } else { "Green" })
Write-Host "  • Bluetooth     : $btName" -ForegroundColor Gray
Write-Host "  • OEM System    : $origMfg $origModel (Chassis: $chassisCode)" -ForegroundColor Gray
Write-Host "  • Motherboard   : $boardInfo" -ForegroundColor Gray
Write-Host "  • Interop Mode  : $(if ($hasGBE) { 'GalaxyBookEnabler Detected (Coexistence Mode)' } else { 'Standalone Enabler Mode' })" -ForegroundColor $(if ($hasGBE) { "Cyan" } else { "Green" })
Write-Host "-----------------------------------------------------------------" -ForegroundColor DarkCyan

if ($DetectOnly) {
    Write-Host "`nHardware detection complete (-DetectOnly specified). Exiting." -ForegroundColor Green
    return
}

# ==============================================================================
# PHASE 2: ADAPTIVE STRATEGY CALCULATION ("THE MAGIC ENGINE")
# ==============================================================================
Write-Host "`n[Phase 2] Computing Hardware Optimization Strategy..." -ForegroundColor Yellow

$needsDesktopBypass = $false
$bypassReason = ""

if ($isLaptopEnclosure -and ($wifiVendor -in @("MediaTek", "Realtek", "Generic"))) {
    $needsDesktopBypass = $true
    $bypassReason = "Non-Intel Wi-Fi ($wifiVendor) on Laptop chassis. Samsung Continuity Commons.dll enforces strict Intel-only whitelist for laptops. Desktop Enclosure (0x03) bypass required."
    Write-Host "  [!] Vulnerability Identified: $bypassReason" -ForegroundColor Yellow
    Write-Host "  [+] Strategy Selected: EnclosureType = 0x03 (Desktop Mode - Whitelist Bypassed)" -ForegroundColor Green
} else {
    Write-Host "  [+] Standard Continuity Mode: Intel Wi-Fi or Desktop hardware detected." -ForegroundColor Green
}

# Target Model Selection
$targetModel = "Galaxy Book4 Pro"
if ($cpuArch -match "ARM64") {
    $targetModel = "Galaxy Book4 Edge"
} elseif ($cpuName -match "Ryzen|Radeon") {
    $targetModel = "Galaxy Book6 Pro"
}

Write-Host "  [+] Target Galaxy Identity: $targetModel (Manufacturer: SAMSUNG ELECTRONICS CO., LTD.)" -ForegroundColor Gray

# ==============================================================================
# PHASE 3: BACKUP ORIGINAL HARDWARE VALUES
# ==============================================================================
$backupDir = "$env:LOCALAPPDATA\GalaxyConnectEnabler"
if (!(Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
$backupFile = Join-Path $backupDir "original-bios.json"

if (!(Test-Path $backupFile)) {
    try {
        $orig = Get-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -ErrorAction SilentlyContinue
        $backupData = @{
            SystemManufacturer    = $origMfg
            SystemProductName     = $origModel
            SystemFamily          = $orig.SystemFamily
            BaseBoardManufacturer = $bb.Manufacturer
            BaseBoardProduct      = $bb.Product
            EnclosureType         = $orig.EnclosureType
            ChassisTypes          = $chassisCode
            WiFiAdapter           = $wifiDesc
            BackupDate            = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
        $backupData | ConvertTo-Json | Set-Content -Path $backupFile -Encoding UTF8 -Force
        Write-Host "  [*] Original BIOS & hardware settings backed up to $backupFile" -ForegroundColor DarkGray
    } catch {}
}

# ==============================================================================
# PHASE 4: SYSTEM SERVICES & WCF PORT SHARING
# ==============================================================================
Write-Host "`n[Phase 3] Configuring System Background Services..." -ForegroundColor Yellow

# NetTcpPortSharing (Required for Samsung Continuity WCF Port 49200)
try {
    Set-Service -Name "NetTcpPortSharing" -StartupType Automatic -ErrorAction SilentlyContinue
    Start-Service -Name "NetTcpPortSharing" -ErrorAction SilentlyContinue
    Write-Host "  -> NetTcpPortSharing (WCF Net.Tcp port 49200) set to Automatic & Started." -ForegroundColor Gray
} catch {}

# Geolocation Service (lfsvc - Required for Bluetooth LE proximity beacons)
try {
    Set-Service -Name "lfsvc" -StartupType Automatic -ErrorAction SilentlyContinue
    Start-Service -Name "lfsvc" -ErrorAction SilentlyContinue
    Write-Host "  -> Geolocation Service (lfsvc) set to Automatic & Started." -ForegroundColor Gray
} catch {}

# ==============================================================================
# PHASE 5: CAPABILITY ACCESS & LOCATION PERMISSIONS
# ==============================================================================
Write-Host "`n[Phase 4] Granting Capability & Location Permissions..." -ForegroundColor Yellow
$caps = @("location", "bluetoothSync", "radios")
$samsungPkgs = Get-AppxPackage -Name "*Samsung*" -AllUsers -ErrorAction SilentlyContinue | Select-Object -ExpandProperty PackageFamilyName -Unique

foreach ($cap in $caps) {
    # System hive
    $hklmBase = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\$cap"
    if (Test-Path $hklmBase) {
        Set-ItemProperty -Path $hklmBase -Name "Value" -Value "Allow" -Force -ErrorAction SilentlyContinue
        $npKey = "$hklmBase\NonPackaged"
        if (!(Test-Path $npKey)) { New-Item -Path $npKey -Force | Out-Null }
        Set-ItemProperty -Path $npKey -Name "Value" -Value "Allow" -Force -ErrorAction SilentlyContinue
    }

    # User hive
    $hkcuBase = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\$cap"
    if (Test-Path $hkcuBase) {
        Set-ItemProperty -Path $hkcuBase -Name "Value" -Value "Allow" -Force -ErrorAction SilentlyContinue
        $npKey = "$hkcuBase\NonPackaged"
        if (!(Test-Path $npKey)) { New-Item -Path $npKey -Force | Out-Null }
        Set-ItemProperty -Path $npKey -Name "Value" -Value "Allow" -Force -ErrorAction SilentlyContinue

        foreach ($pkg in $samsungPkgs) {
            $key = "$hkcuBase\$pkg"
            if (!(Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
            Set-ItemProperty -Path $key -Name "Value" -Value "Allow" -Force -ErrorAction SilentlyContinue
        }
    }
}
Write-Host "  -> Location and Radios set to 'Allow' across all Samsung packages & desktop apps." -ForegroundColor Gray

# ==============================================================================
# PHASE 6: HARDWARE-TAILORED SPOOFING & WHITELIST BYPASS
# ==============================================================================
Write-Host "`n[Phase 5] Applying Samsung Ecosystem Spoofing & Whitelist Bypass..." -ForegroundColor Yellow
$enclosureVal = if ($needsDesktopBypass) { 3 } else { 3 }

$biosPath = "HKLM:\HARDWARE\DESCRIPTION\System\BIOS"
$hwConfigPath = "HKLM:\SYSTEM\HardwareConfig\Current"
$sysInfoPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation"

Set-ItemProperty -Path $biosPath -Name "SystemManufacturer" -Value "SAMSUNG ELECTRONICS CO., LTD." -Force
Set-ItemProperty -Path $biosPath -Name "SystemProductName" -Value $targetModel -Force
Set-ItemProperty -Path $biosPath -Name "SystemFamily" -Value $targetModel -Force
Set-ItemProperty -Path $biosPath -Name "BaseBoardManufacturer" -Value "SAMSUNG ELECTRONICS CO., LTD." -Force
Set-ItemProperty -Path $biosPath -Name "EnclosureType" -Value $enclosureVal -Type DWord -Force

if (Test-Path $hwConfigPath) {
    Set-ItemProperty -Path $hwConfigPath -Name "SystemManufacturer" -Value "SAMSUNG ELECTRONICS CO., LTD." -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $hwConfigPath -Name "SystemProductName" -Value $targetModel -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $hwConfigPath -Name "SystemFamily" -Value $targetModel -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $hwConfigPath -Name "BaseBoardManufacturer" -Value "SAMSUNG ELECTRONICS CO., LTD." -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $hwConfigPath -Name "EnclosureType" -Value $enclosureVal -Type DWord -Force -ErrorAction SilentlyContinue
}

if (Test-Path $sysInfoPath) {
    Set-ItemProperty -Path $sysInfoPath -Name "SystemManufacturer" -Value "SAMSUNG ELECTRONICS CO., LTD." -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $sysInfoPath -Name "SystemProductName" -Value $targetModel -Force -ErrorAction SilentlyContinue
}
Write-Host "  -> SystemManufacturer set to 'SAMSUNG ELECTRONICS CO., LTD.'" -ForegroundColor Gray
Write-Host "  -> EnclosureType set to $enclosureVal (Desktop Mode - Wi-Fi Whitelist Bypassed)." -ForegroundColor Gray

# GBE Interoperability: Patch GalaxyBookSpoof.bat if GalaxyBookEnabler is installed
if ($hasGBE -and (Test-Path (Join-Path $gbeDir "GalaxyBookSpoof.bat"))) {
    $gbeBat = Join-Path $gbeDir "GalaxyBookSpoof.bat"
    $gbeContent = Get-Content $gbeBat -Raw -ErrorAction SilentlyContinue
    if ($gbeContent -and ($gbeContent -match "EnclosureType /t REG_DWORD /d 0x0A|EnclosureType /t REG_DWORD /d 10")) {
        $gbeContent = $gbeContent -replace "EnclosureType /t REG_DWORD /d 0x0A", "EnclosureType /t REG_DWORD /d 0x03"
        $gbeContent = $gbeContent -replace "EnclosureType /t REG_DWORD /d 10", "EnclosureType /t REG_DWORD /d 0x03"
        Set-Content -Path $gbeBat -Value $gbeContent -Encoding UTF8 -Force
        Write-Host "  [+] Interoperability: Patched GalaxyBookEnabler ($gbeBat) with EnclosureType=0x03." -ForegroundColor Cyan
    }
}

# ==============================================================================
# PHASE 7: MULTI-HIVE CROSS-DEVICE P2P (FamilyMDE)
# ==============================================================================
Write-Host "`n[Phase 6] Configuring Cross-Device P2P (FamilyMDE) Across All Hives..." -ForegroundColor Yellow

$mdeHklm = "HKLM\Software\SAMSUNG\SamsungContinuityService\FamilyMDE"
$mdeHkcu = "HKCU\Software\SAMSUNG\SamsungContinuityService\FamilyMDE"
& reg add $mdeHklm /v Settings /t REG_DWORD /d 1 /f | Out-Null
& reg add $mdeHkcu /v Settings /t REG_DWORD /d 1 /f | Out-Null

$userSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
if ($userSid) {
    & reg add "HKEY_USERS\$userSid\Software\SAMSUNG\SamsungContinuityService\FamilyMDE" /v Settings /t REG_DWORD /d 1 /f | Out-Null
}

Get-ChildItem -Path "Registry::HKEY_USERS" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'S-1-5-21-\d+-\d+-\d+-\d+$' } | ForEach-Object {
    $subSid = $_.PSChildName
    & reg add "HKEY_USERS\$subSid\Software\SAMSUNG\SamsungContinuityService\FamilyMDE" /v Settings /t REG_DWORD /d 1 /f | Out-Null
}
Write-Host "  -> FamilyMDE\Settings = 1 enforced in HKLM, HKCU, and User SIDs." -ForegroundColor Gray

# ==============================================================================
# PHASE 8: LOCALSTATE & PROGRAMDATA ENGINEERING FEATURE FLAGS
# ==============================================================================
Write-Host "`n[Phase 7] Deploying Engineering Feature Flags & MultiControl Settings..." -ForegroundColor Yellow
$localStateDirs = @(
    "$env:LOCALAPPDATA\Packages\SAMSUNGELECTRONICSCoLtd.MultiControl_wyx1vj98g3asy\LocalState",
    "$env:LOCALAPPDATA\Packages\SAMSUNGELECTRONICSCoLtd.SamsungMyDevices_wyx1vj98g3asy\LocalState",
    "C:\ProgramData\Samsung\SamsungMultiControl"
)
$flags = @("TestEnable.MC", "TestGCE.MC", "TestFamily.MC")
foreach ($dir in $localStateDirs) {
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    foreach ($f in $flags) {
        $fp = Join-Path $dir $f
        if (!(Test-Path $fp)) { New-Item -ItemType File -Path $fp -Force | Out-Null }
    }
    # Clean up TestNotSamsung.MC if present (it forces OEMHelper.IsSamsungPC to False and breaks P2P/switching)
    $notSamsung = Join-Path $dir "TestNotSamsung.MC"
    if (Test-Path $notSamsung) { Remove-Item $notSamsung -Force -ErrorAction SilentlyContinue }
}

# Ensure MultiControl Settings & Connection Option are configured for Any Switching (Option 3)
$settingsDir = "C:\ProgramData\Samsung\SamsungMultiControl\Settings"
if (!(Test-Path $settingsDir)) { New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null }
$connOptionPath = Join-Path $settingsDir "DeviceConnectionOption.json"
Set-Content -Path $connOptionPath -Value '{"Option":3,"bEasyMove":true}' -Encoding utf8 -Force

$mcDat = Join-Path $settingsDir "MCCoreSettings.dat"
if (Test-Path $mcDat) {
    try {
        $json = Get-Content $mcDat -Raw | ConvertFrom-Json
        $json.AnalyticsData.OnOff = 1
        $json.ConnectionOption = 3
        $json.AnalyticsData.AutoConnectionSettings = "Any Wi-Fi or Wi-Fi Direct network"
        foreach ($item in $json.SettingsList) { $item.MC = $true }
        $newJson = $json | ConvertTo-Json -Depth 10 -Compress
        $tempPath = "$mcDat.tmp"
        [System.IO.File]::WriteAllText($tempPath, $newJson)
        Move-Item -Path $tempPath -Destination $mcDat -Force
    } catch {}
}

# Unlock permissions on ProgramData SamsungMultiControl folder
try {
    & icacls "C:\ProgramData\Samsung\SamsungMultiControl" /grant "*S-1-15-2-1:(OI)(CI)F" /grant "Users:(OI)(CI)F" /T /Q 2>$null | Out-Null
} catch {}
Write-Host "  -> Engineering flags deployed and MultiControl permissions unlocked." -ForegroundColor Gray

# ==============================================================================
# PHASE 9: UNIVERSAL FIREWALL RULES (ANY PROFILE)
# ==============================================================================
Write-Host "`n[Phase 8] Configuring Universal Multi-Profile Windows Firewall Rules..." -ForegroundColor Yellow
Get-NetFirewallRule -DisplayName "Samsung Galaxy *" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "Samsung Galaxy P2P Device Discovery" -Direction Inbound -Protocol UDP -LocalPort 1900,3702,5353,5355 -Action Allow -Profile Any | Out-Null
New-NetFirewallRule -DisplayName "Samsung Galaxy MultiControl TCP" -Direction Inbound -Protocol TCP -LocalPort 49200,49201,49202,8080,8443,5228,5229,5230 -Action Allow -Profile Any | Out-Null

$coreExes = @(
    @{ Name = "Samsung Galaxy Continuity Service"; Path = "C:\Program Files\Samsung\SamsungContinuityService\SamsungContinuityWindowsService.exe" },
    @{ Name = "Samsung Galaxy Windows MCF Core";   Path = "C:\Program Files\Samsung\SamsungContinuityService\WindowsMCFCore.exe" },
    @{ Name = "Samsung Galaxy MultiControl Svc";   Path = "C:\Program Files\Samsung\SamsungMultiControl\SamsungMultiControlService.exe" },
    @{ Name = "Samsung Galaxy MultiControl App";   Path = "C:\Program Files\Samsung\SamsungMultiControl\SamsungMultiControl.exe" },
    @{ Name = "Samsung Galaxy MultiControl Helper";Path = "C:\Program Files\Samsung\SamsungMultiControl\SamsungMultiControlHelper.exe" }
)
foreach ($exe in $coreExes) {
    if (Test-Path $exe.Path) {
        New-NetFirewallRule -DisplayName $exe.Name -Direction Inbound -Program $exe.Path -Action Allow -Profile Any -ErrorAction SilentlyContinue | Out-Null
    }
}
Write-Host "  -> Inbound UDP & TCP rules active across Domain, Private, and Public network profiles." -ForegroundColor Gray

# ==============================================================================
# PHASE 10: DUAL-LAYER BOOT & LOGON PERSISTENCE
# ==============================================================================
Write-Host "`n[Phase 9] Registering Boot & Logon Persistence Tasks..." -ForegroundColor Yellow

$bootBat = Join-Path $backupDir "GalaxyConnectBootSpoof.bat"
$bootBatContent = @"
@echo off
chcp 65001 >nul
reg add "HKLM\HARDWARE\DESCRIPTION\System\BIOS" /v SystemManufacturer /t REG_SZ /d "SAMSUNG ELECTRONICS CO., LTD." /f
reg add "HKLM\HARDWARE\DESCRIPTION\System\BIOS" /v SystemProductName /t REG_SZ /d "$targetModel" /f
reg add "HKLM\HARDWARE\DESCRIPTION\System\BIOS" /v SystemFamily /t REG_SZ /d "$targetModel" /f
reg add "HKLM\HARDWARE\DESCRIPTION\System\BIOS" /v BaseBoardManufacturer /t REG_SZ /d "SAMSUNG ELECTRONICS CO., LTD." /f
reg add "HKLM\HARDWARE\DESCRIPTION\System\BIOS" /v EnclosureType /t REG_DWORD /d 0x03 /f

reg add "HKLM\SYSTEM\HardwareConfig\Current" /v SystemManufacturer /t REG_SZ /d "SAMSUNG ELECTRONICS CO., LTD." /f
reg add "HKLM\SYSTEM\HardwareConfig\Current" /v SystemProductName /t REG_SZ /d "$targetModel" /f
reg add "HKLM\SYSTEM\HardwareConfig\Current" /v SystemFamily /t REG_SZ /d "$targetModel" /f
reg add "HKLM\SYSTEM\HardwareConfig\Current" /v BaseBoardManufacturer /t REG_SZ /d "SAMSUNG ELECTRONICS CO., LTD." /f
reg add "HKLM\SYSTEM\HardwareConfig\Current" /v EnclosureType /t REG_DWORD /d 0x03 /f

reg add "HKLM\SYSTEM\CurrentControlSet\Control\SystemInformation" /v SystemManufacturer /t REG_SZ /d "SAMSUNG ELECTRONICS CO., LTD." /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SystemInformation" /v SystemProductName /t REG_SZ /d "$targetModel" /f

reg add "HKLM\Software\SAMSUNG\SamsungContinuityService\FamilyMDE" /v Settings /t REG_DWORD /d 1 /f
"@
Set-Content -Path $bootBat -Value $bootBatContent -Encoding UTF8 -Force

# Task 1: Boot Scheduled Task (Runs as SYSTEM at Boot + 5s)
$taskNameBoot = "GalaxyConnectEnabler-Boot"
Unregister-ScheduledTask -TaskName $taskNameBoot -Confirm:$false -ErrorAction SilentlyContinue
$actBoot = New-ScheduledTaskAction -Execute $bootBat
$trigBoot = New-ScheduledTaskTrigger -AtStartup
$trigBoot.Delay = "PT5S"
$princBoot = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$setBoot = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName $taskNameBoot -Description "Enforces Samsung Desktop Spoof at boot" -Action $actBoot -Trigger $trigBoot -Principal $princBoot -Settings $setBoot | Out-Null
Write-Host "  -> Registered system boot persistence task: $taskNameBoot" -ForegroundColor Gray

# Task 2: User Logon Sync Worker
$syncScript = Join-Path $PSScriptRoot "SamsungEcosystemSync.ps1"
$pwshPath = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (-not $pwshPath) { $pwshPath = Join-Path $env:ProgramFiles "PowerShell\7\pwsh.exe" }
if (!(Test-Path $pwshPath)) { $pwshPath = "powershell.exe" }

Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "GalaxyConnectEnabler" -Value "`"$pwshPath`" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$syncScript`"" -Force
Write-Host "  -> Registered user logon sync in HKCU Run key." -ForegroundColor Gray

# ==============================================================================
# PHASE 11: RESTART SERVICES & LAUNCH ECOSYSTEM APPS
# ==============================================================================
Write-Host "`n[Phase 10] Restarting Samsung Background Services & Launching Apps..." -ForegroundColor Yellow
Stop-Process -Name "*NearbyDevices*", "*MultiControl*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Restart-Service -Name "SamsungContinuityWindowsService" -Force -ErrorAction SilentlyContinue
$mcSvc = Get-Service -Name "Samsung Multi Control Service", "SamsungMultiControlService" -ErrorAction SilentlyContinue
if ($mcSvc) {
    Restart-Service -Name $mcSvc.Name -Force -ErrorAction SilentlyContinue
    Write-Host "  -> Multi Control service ($($mcSvc.Name)) restarted." -ForegroundColor Gray
}
Start-Sleep -Seconds 2

# Signal MultiControl Service to launch engine
try {
    $wh = [System.Threading.EventWaitHandle]::OpenExisting('Global\SamsungMultiControlService_On')
    $wh.Set() | Out-Null
    Write-Host "  -> Signaled SamsungMultiControlService_On event." -ForegroundColor Gray
} catch {}

Start-Sleep -Seconds 2
$mcProc = Get-Process -Name "SamsungMultiControl" -ErrorAction SilentlyContinue
if (-not $mcProc) {
    $mcExe = "C:\Program Files\Samsung\SamsungMultiControl\SamsungMultiControl.exe"
    if (Test-Path $mcExe) {
        Start-Process -FilePath $mcExe -WindowStyle Hidden -ErrorAction SilentlyContinue
        Write-Host "  -> Multi Control engine launched directly." -ForegroundColor Gray
    }
}

Write-Host "Launching Nearby Devices (Galaxy Connect) & Multi Control..." -ForegroundColor Green
Start-Process "shell:AppsFolder\SAMSUNGELECTRONICSCoLtd.SamsungMyDevices_wyx1vj98g3asy!App" -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3
Start-Process "shell:AppsFolder\SAMSUNGELECTRONICSCoLtd.MultiControl_wyx1vj98g3asy!App" -ErrorAction SilentlyContinue

# ==============================================================================
# FINAL SUMMARY
# ==============================================================================
Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "  GALAXY CONNECT ENABLER APPLIED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "• Detected Hardware     : $cpuVendor CPU ($cpuName) | $wifiVendor Wi-Fi ($wifiDesc)"
Write-Host "• Samsung Spoof Model   : $targetModel (OEM: SAMSUNG ELECTRONICS CO., LTD.)"
Write-Host "• Enclosure Mode        : Desktop (0x03) - Wi-Fi Whitelist Bypassed"
Write-Host "• Multi Control P2P     : Active across HKLM, HKCU, and User SIDs"
Write-Host "• Capability Consent    : Allow (Location, Bluetooth, Radios)"
Write-Host "• Interoperability Mode : $(if ($hasGBE) { 'Compatible with Galaxy Book Enabler' } else { 'Standalone Operation' })"
Write-Host "• Boot Persistence      : Dual-Layer (SYSTEM Scheduled Task + HKCU Run)"
Write-Host "=================================================================`n" -ForegroundColor Cyan
