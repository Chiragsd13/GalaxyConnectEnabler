# ==============================================================================
# Galaxy Connect Enabler - User Logon Sync Worker
# Runs silently on user login to maintain FamilyMDE, test flags, and permissions
# ==============================================================================

# 1. Ensure FamilyMDE Settings in HKCU, HKLM, and all HKEY_USERS SIDs
$mdePaths = @(
    "HKCU\Software\SAMSUNG\SamsungContinuityService\FamilyMDE",
    "HKLM\Software\SAMSUNG\SamsungContinuityService\FamilyMDE"
)
foreach ($mp in $mdePaths) {
    & reg add $mp /v Settings /t REG_DWORD /d 1 /f | Out-Null
}

$userSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
if ($userSid) {
    & reg add "HKEY_USERS\$userSid\Software\SAMSUNG\SamsungContinuityService\FamilyMDE" /v Settings /t REG_DWORD /d 1 /f | Out-Null
}

Get-ChildItem -Path "Registry::HKEY_USERS" -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'S-1-5-21-\d+-\d+-\d+-\d+$' } | ForEach-Object {
    $subSid = $_.PSChildName
    & reg add "HKEY_USERS\$subSid\Software\SAMSUNG\SamsungContinuityService\FamilyMDE" /v Settings /t REG_DWORD /d 1 /f | Out-Null
}

# 2. Ensure LocalState & ProgramData Test Flags
$dirs = @(
    "$env:LOCALAPPDATA\Packages\SAMSUNGELECTRONICSCoLtd.MultiControl_wyx1vj98g3asy\LocalState",
    "$env:LOCALAPPDATA\Packages\SAMSUNGELECTRONICSCoLtd.SamsungMyDevices_wyx1vj98g3asy\LocalState",
    "C:\ProgramData\Samsung\SamsungMultiControl"
)
$testFlags = @("TestEnable.MC", "TestGCE.MC", "TestFamily.MC")
foreach ($d in $dirs) {
    if (Test-Path $d) {
        foreach ($f in $testFlags) {
            $fp = Join-Path $d $f
            if (!(Test-Path $fp)) { New-Item -ItemType File -Path $fp -Force | Out-Null }
        }
        # Clean up TestNotSamsung.MC if present (it forces OEMHelper.IsSamsungPC to False)
        $notSamsung = Join-Path $d "TestNotSamsung.MC"
        if (Test-Path $notSamsung) { Remove-Item $notSamsung -Force -ErrorAction SilentlyContinue }
    }
}

# 3. Ensure Location & Capability Permissions in HKCU
$caps = @("location", "bluetoothSync", "radios")
$pkgs = Get-AppxPackage -Name "*Samsung*" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty PackageFamilyName -Unique
foreach ($c in $caps) {
    $base = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\$c"
    if (Test-Path $base) {
        Set-ItemProperty -Path $base -Name "Value" -Value "Allow" -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "$base\NonPackaged" -Name "Value" -Value "Allow" -Force -ErrorAction SilentlyContinue
        foreach ($p in $pkgs) {
            $pk = "$base\$p"
            if (!(Test-Path $pk)) { New-Item -Path $pk -Force | Out-Null }
            Set-ItemProperty -Path $pk -Name "Value" -Value "Allow" -Force -ErrorAction SilentlyContinue
        }
    }
}

# 4. Ensure MCCoreSettings.dat has MultiControl On and Any Switching (Option 3)
$settingsDir = "C:\ProgramData\Samsung\SamsungMultiControl\Settings"
if (!(Test-Path $settingsDir)) { New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null }

$connOptionPath = Join-Path $settingsDir "DeviceConnectionOption.json"
if (!(Test-Path $connOptionPath)) {
    Set-Content -Path $connOptionPath -Value '{"Option":3,"bEasyMove":true}' -Encoding utf8 -Force
}

$mcDat = Join-Path $settingsDir "MCCoreSettings.dat"
if (Test-Path $mcDat) {
    try {
        $json = Get-Content $mcDat -Raw | ConvertFrom-Json
        $changed = $false
        if ($json.AnalyticsData.OnOff -ne 1) {
            $json.AnalyticsData.OnOff = 1
            $changed = $true
        }
        if ($json.ConnectionOption -ne 3) {
            $json.ConnectionOption = 3
            $json.AnalyticsData.AutoConnectionSettings = "Any Wi-Fi or Wi-Fi Direct network"
            $changed = $true
        }
        foreach ($item in $json.SettingsList) {
            if (-not $item.MC) {
                $item.MC = $true
                $changed = $true
            }
        }
        if ($changed) {
            $newJson = $json | ConvertTo-Json -Depth 10 -Compress
            $tempPath = "$mcDat.tmp"
            [System.IO.File]::WriteAllText($tempPath, $newJson)
            Move-Item -Path $tempPath -Destination $mcDat -Force
        }
    } catch {}
}

# 5. Verify WCF NetTcpPortSharing service
try {
    $portSharing = Get-Service -Name "NetTcpPortSharing" -ErrorAction SilentlyContinue
    if ($portSharing -and $portSharing.Status -ne "Running") {
        Start-Service -Name "NetTcpPortSharing" -ErrorAction SilentlyContinue
    }
} catch {}

# 6. Ensure Multi Control engine is running in the user session
$mcProc = Get-Process -Name "SamsungMultiControl" -ErrorAction SilentlyContinue
if (-not $mcProc) {
    try {
        $wh = [System.Threading.EventWaitHandle]::OpenExisting('Global\SamsungMultiControlService_On')
        $wh.Set() | Out-Null
    } catch {}
    
    # Fallback direct start if service doesn't spawn it within 2 seconds
    Start-Sleep -Seconds 2
    $mcProc = Get-Process -Name "SamsungMultiControl" -ErrorAction SilentlyContinue
    if (-not $mcProc) {
        $mcExe = "C:\Program Files\Samsung\SamsungMultiControl\SamsungMultiControl.exe"
        if (Test-Path $mcExe) {
            Start-Process -FilePath $mcExe -WindowStyle Hidden -ErrorAction SilentlyContinue
        }
    }
}
