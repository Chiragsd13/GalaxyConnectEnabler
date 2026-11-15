# ==============================================================================
# Galaxy Connect Enabler - Core Engine
# Enables Samsung Multi Control, Nearby Devices, Continuity & Quick Share
# on any Windows 11 PC (AMD Ryzen / Intel / MediaTek / Realtek / Qualcomm)
# ==============================================================================

[CmdletBinding()]
param(
    [switch]$Silent = $false
)

$ErrorActionPreference = "Continue"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "             GALAXY CONNECT ENABLER (v1.0.0)" -ForegroundColor Cyan
Write-Host "  Universal Samsung Cross-Device Ecosystem for Windows 11" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Administrator Check
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
    Write-Warning "Administrator privileges required. Please run Enable-GalaxyConnect.bat."
    exit 1
}

# 2. Backup Original BIOS Values (for clean uninstallation)
$backupDir = "$env:LOCALAPPDATA\GalaxyConnectEnabler"
if (!(Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
$backupFile = Join-Path $backupDir "original-bios.json"

if (!(Test-Path $backupFile)) {
    try {
        $orig = Get-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -ErrorAction SilentlyContinue
        $backupData = @{
            SystemManufacturer    = $orig.SystemManufacturer
            SystemProductName     = $orig.SystemProductName
            SystemFamily          = $orig.SystemFamily
            BaseBoardManufacturer = $orig.BaseBoardManufacturer
            BaseBoardProduct      = $orig.BaseBoardProduct
            EnclosureType         = $orig.EnclosureType
            BackupDate            = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
        $backupData | ConvertTo-Json | Set-Content -Path $backupFile -Encoding UTF8 -Force
        Write-Host "[*] Original BIOS settings backed up to $backupFile" -ForegroundColor DarkGray
    } catch {}
}

# 3. Configure Windows Services
Write-Host "`n[1/7] Configuring system background services..." -ForegroundColor Green

# WCF Net.Tcp Port Sharing (used by Samsung Continuity & MultiControl)
try {
    Set-Service -Name "NetTcpPortSharing" -StartupType Automatic -ErrorAction SilentlyContinue
    Start-Service -Name "NetTcpPortSharing" -ErrorAction SilentlyContinue
    Write-Host "  -> NetTcpPortSharing (WCF Net.Tcp) set to Automatic & Started." -ForegroundColor Gray
} catch {}

# Geolocation Service (used by Samsung proximity discovery & BLE)
try {
    Set-Service -Name "lfsvc" -StartupType Automatic -ErrorAction SilentlyContinue
    Start-Service -Name "lfsvc" -ErrorAction SilentlyContinue
    Write-Host "  -> Geolocation Service (lfsvc) set to Automatic & Started." -ForegroundColor Gray
} catch {}

# 4. Fix Windows Location & Capability Consent
Write-Host "`n[2/7] Granting Location & Radio permissions for Samsung Apps..." -ForegroundColor Green
$caps = @("location", "bluetoothSync", "radios")
$samsungPkgs = Get-AppxPackage -Name "*Samsung*" -AllUsers -ErrorAction SilentlyContinue | Select-Object -ExpandProperty PackageFamilyName -Unique

foreach ($cap in $caps) {
    $hklmBase = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\$cap"
    if (Test-Path $hklmBase) {
        Set-ItemProperty -Path $hklmBase -Name "Value" -Value "Allow" -Force -ErrorAction SilentlyContinue
        $npKey = "$hklmBase\NonPackaged"
        if (!(Test-Path $npKey)) { New-Item -Path $npKey -Force | Out-Null }
        Set-ItemProperty -Path $npKey -Name "Value" -Value "Allow" -Force -ErrorAction SilentlyContinue
    }

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
Write-Host "  -> Location and Radios set to 'Allow' across all Samsung packages." -ForegroundColor Gray

# 5. Apply Samsung Desktop BIOS Spoof (The Core Whitelist Bypass)
# EnclosureType = 3 (Desktop) instructs Samsung Continuity (Commons.dll DeviceSupportHelper.HasSupportedWiFi)
# to bypass the laptop Wi-Fi whitelist, fully enabling MediaTek, Realtek, and Qualcomm adapters!
Write-Host "`n[3/7] Applying Samsung Desktop BIOS spoofing (EnclosureType = 3)..." -ForegroundColor Green
$biosPath = "HKLM:\HARDWARE\DESCRIPTION\System\BIOS"
$hwConfigPath = "HKLM:\SYSTEM\HardwareConfig\Current"
$sysInfoPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation"

Set-ItemProperty -Path $biosPath -Name "SystemManufacturer" -Value "SAMSUNG ELECTRONICS CO., LTD." -Force
Set-ItemProperty -Path $biosPath -Name "SystemProductName" -Value "Galaxy Book4 Pro" -Force
Set-ItemProperty -Path $biosPath -Name "SystemFamily" -Value "Galaxy Book4 Pro" -Force
Set-ItemProperty -Path $biosPath -Name "BaseBoardManufacturer" -Value "SAMSUNG ELECTRONICS CO., LTD." -Force
Set-ItemProperty -Path $biosPath -Name "EnclosureType" -Value 3 -Type DWord -Force

if (Test-Path $hwConfigPath) {
    Set-ItemProperty -Path $hwConfigPath -Name "SystemManufacturer" -Value "SAMSUNG ELECTRONICS CO., LTD." -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $hwConfigPath -Name "SystemProductName" -Value "Galaxy Book4 Pro" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $hwConfigPath -Name "SystemFamily" -Value "Galaxy Book4 Pro" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $hwConfigPath -Name "BaseBoardManufacturer" -Value "SAMSUNG ELECTRONICS CO., LTD." -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $hwConfigPath -Name "EnclosureType" -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue
}

if (Test-Path $sysInfoPath) {
    Set-ItemProperty -Path $sysInfoPath -Name "SystemManufacturer" -Value "SAMSUNG ELECTRONICS CO., LTD." -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $sysInfoPath -Name "SystemProductName" -Value "Galaxy Book4 Pro" -Force -ErrorAction SilentlyContinue
}
Write-Host "  -> SystemManufacturer: 'SAMSUNG ELECTRONICS CO., LTD.'" -ForegroundColor Gray
Write-Host "  -> EnclosureType: 3 (Desktop Mode - MediaTek / Realtek / All Wi-Fi Whitelisted)" -ForegroundColor Gray

# 6. Configure FamilyMDE Cross-Device P2P Registry
Write-Host "`n[4/7] Configuring FamilyMDE Registry (Cross-Device P2P)..." -ForegroundColor Green
$mdePaths = @(
    "HKCU:\Software\SAMSUNG\SamsungContinuityService\FamilyMDE",
    "HKLM:\Software\SAMSUNG\SamsungContinuityService\FamilyMDE"
)
$userSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
if ($userSid) {
    $mdePaths += "Registry::HKEY_USERS\$userSid\Software\SAMSUNG\SamsungContinuityService\FamilyMDE"
}
Get-ChildItem -Path "Registry::HKEY_USERS" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'S-1-5-21-\d+-\d+-\d+-\d+$' } | ForEach-Object {
    $mdePaths += "$($_.PSPath)\Software\SAMSUNG\SamsungContinuityService\FamilyMDE"
}
$mdePaths = $mdePaths | Sort-Object -Unique
foreach ($p in $mdePaths) {
    try {
        if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
        Set-ItemProperty -Path $p -Name "Settings" -Value 1 -Type DWord -Force
        Write-Host "  -> FamilyMDE\Settings = 1 in $p" -ForegroundColor Gray
    } catch {}
}

# 7. Deploy LocalState Test Enablement Flags
Write-Host "`n[5/7] Deploying LocalState test flags..." -ForegroundColor Green
$localStateDirs = @(
    "$env:LOCALAPPDATA\Packages\SAMSUNGELECTRONICSCoLtd.MultiControl_wyx1vj98g3asy\LocalState",
    "$env:LOCALAPPDATA\Packages\SAMSUNGELECTRONICSCoLtd.SamsungMyDevices_wyx1vj98g3asy\LocalState"
)
$flags = @("TestEnable.MC", "TestGCE.MC", "TestFamily.MC")
foreach ($dir in $localStateDirs) {
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    foreach ($f in $flags) {
        $fp = Join-Path $dir $f
        if (!(Test-Path $fp)) { New-Item -ItemType File -Path $fp -Force | Out-Null }
    }
}
Write-Host "  -> Engineering flags (TestEnable.MC, TestGCE.MC, TestFamily.MC) active." -ForegroundColor Gray

# 8. Configure Windows Firewall Rules
Write-Host "`n[6/7] Configuring Inbound Windows Firewall rules..." -ForegroundColor Green
Get-NetFirewallRule -DisplayName "Samsung Galaxy *" -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "Samsung Galaxy P2P Device Discovery" -Direction Inbound -Protocol UDP -LocalPort 1900,3702,5353,5355 -Action Allow -Profile Any | Out-Null
New-NetFirewallRule -DisplayName "Samsung Galaxy MultiControl TCP" -Direction Inbound -Protocol TCP -LocalPort 49200,49201,49202,8080,8443,5228,5229,5230 -Action Allow -Profile Any | Out-Null

# Allow core executables across all profiles (Private, Public, Domain)
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
Write-Host "  -> Firewall rules applied for all profiles (Private, Public, Domain) and ports." -ForegroundColor Gray

try {
    $wifiConn = Get-NetConnectionProfile -InterfaceAlias "*Wi-Fi*" -ErrorAction SilentlyContinue
    if ($wifiConn -and $wifiConn.NetworkCategory -ne "Private") {
        Set-NetConnectionProfile -InterfaceAlias $wifiConn.InterfaceAlias -NetworkCategory Private -ErrorAction SilentlyContinue
        Write-Host "  -> Wi-Fi network category set to Private." -ForegroundColor Gray
    }
} catch {}

# 9. Register Startup Automation Tasks (Boot Persistence)
Write-Host "`n[7/7] Registering Startup Automation for Boot Persistence..." -ForegroundColor Green
$projectRoot = Split-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) -Parent
$bootBat = Join-Path $backupDir "GalaxyConnectBootSpoof.bat"

$bootBatContent = @"
@echo off
chcp 65001 >nul
reg add "HKLM\HARDWARE\DESCRIPTION\System\BIOS" /v SystemManufacturer /t REG_SZ /d "SAMSUNG ELECTRONICS CO., LTD." /f
reg add "HKLM\HARDWARE\DESCRIPTION\System\BIOS" /v SystemProductName /t REG_SZ /d "Galaxy Book4 Pro" /f
reg add "HKLM\HARDWARE\DESCRIPTION\System\BIOS" /v SystemFamily /t REG_SZ /d "Galaxy Book4 Pro" /f
reg add "HKLM\HARDWARE\DESCRIPTION\System\BIOS" /v BaseBoardManufacturer /t REG_SZ /d "SAMSUNG ELECTRONICS CO., LTD." /f
reg add "HKLM\HARDWARE\DESCRIPTION\System\BIOS" /v BaseBoardProduct /t REG_SZ /d "NP944XJG-KG5US" /f
reg add "HKLM\HARDWARE\DESCRIPTION\System\BIOS" /v EnclosureType /t REG_DWORD /d 0x03 /f

reg add "HKLM\SYSTEM\HardwareConfig\Current" /v SystemManufacturer /t REG_SZ /d "SAMSUNG ELECTRONICS CO., LTD." /f
reg add "HKLM\SYSTEM\HardwareConfig\Current" /v SystemProductName /t REG_SZ /d "Galaxy Book4 Pro" /f
reg add "HKLM\SYSTEM\HardwareConfig\Current" /v SystemFamily /t REG_SZ /d "Galaxy Book4 Pro" /f
reg add "HKLM\SYSTEM\HardwareConfig\Current" /v BaseBoardManufacturer /t REG_SZ /d "SAMSUNG ELECTRONICS CO., LTD." /f
reg add "HKLM\SYSTEM\HardwareConfig\Current" /v EnclosureType /t REG_DWORD /d 0x03 /f

reg add "HKLM\SYSTEM\CurrentControlSet\Control\SystemInformation" /v SystemManufacturer /t REG_SZ /d "SAMSUNG ELECTRONICS CO., LTD." /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\SystemInformation" /v SystemProductName /t REG_SZ /d "Galaxy Book4 Pro" /f

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
Write-Host "  -> Registered boot task: $taskNameBoot" -ForegroundColor Gray

# Task 2: User Logon Sync via HKCU Run Key
$syncScript = Join-Path $PSScriptRoot "SamsungEcosystemSync.ps1"
$pwshPath = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (-not $pwshPath) { $pwshPath = Join-Path $env:ProgramFiles "PowerShell\7\pwsh.exe" }
if (!(Test-Path $pwshPath)) { $pwshPath = "powershell.exe" }

Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "GalaxyConnectEnabler" -Value "`"$pwshPath`" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$syncScript`"" -Force
Write-Host "  -> Registered user logon sync in HKCU Run key." -ForegroundColor Gray

# 10. Restart Background Services & Launch Apps
Write-Host "`nRestarting Samsung background services..." -ForegroundColor Green
Stop-Process -Name "*NearbyDevices*", "*MultiControl*" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Restart-Service -Name "SamsungContinuityWindowsService" -Force -ErrorAction SilentlyContinue
$mcSvc = Get-Service -Name "Samsung Multi Control Service", "SamsungMultiControlService" -ErrorAction SilentlyContinue
if ($mcSvc) {
    Restart-Service -Name $mcSvc.Name -Force -ErrorAction SilentlyContinue
    Write-Host "  -> Multi Control service ($($mcSvc.Name)) restarted." -ForegroundColor Gray
}
Start-Sleep -Seconds 2

Write-Host "Launching Nearby Devices (Galaxy Connect) & Multi Control..." -ForegroundColor Green
Start-Process "shell:AppsFolder\SAMSUNGELECTRONICSCoLtd.SamsungMyDevices_wyx1vj98g3asy!App" -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3
Start-Process "shell:AppsFolder\SAMSUNGELECTRONICSCoLtd.MultiControl_wyx1vj98g3asy!App" -ErrorAction SilentlyContinue

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "  GALAXY CONNECT ENABLER IS ACTIVE & PERMANENT!" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "• System Manufacturer : SAMSUNG ELECTRONICS CO., LTD."
Write-Host "• Enclosure Mode       : Desktop (0x03) - All Wi-Fi / BT Whitelisted"
Write-Host "• Multi Control P2P    : Active (FamilyMDE=1, Test Flags Deployed)"
Write-Host "• Location Permissions : Allow (All Samsung Packages)"
Write-Host "• Boot Persistence     : Active (Task Scheduler + HKCU Run)"
Write-Host "=================================================================`n" -ForegroundColor Cyan
