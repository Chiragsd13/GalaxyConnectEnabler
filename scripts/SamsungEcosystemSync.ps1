# ==============================================================================
# Galaxy Connect Enabler - User Logon Sync Worker
# Runs silently on user login to maintain FamilyMDE, test flags, and permissions
# ==============================================================================

# 1. Ensure FamilyMDE Settings in HKCU and HKLM
$mdeHkcu = "HKCU:\Software\SAMSUNG\SamsungContinuityService\FamilyMDE"
if (!(Test-Path $mdeHkcu)) { New-Item -Path $mdeHkcu -Force | Out-Null }
Set-ItemProperty -Path $mdeHkcu -Name "Settings" -Value 1 -Type DWord -Force

$mdeHklm = "HKLM:\Software\SAMSUNG\SamsungContinuityService\FamilyMDE"
if (!(Test-Path $mdeHklm)) { New-Item -Path $mdeHklm -Force -ErrorAction SilentlyContinue | Out-Null }
Set-ItemProperty -Path $mdeHklm -Name "Settings" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

# 2. Ensure LocalState Test Flags
$dirs = @(
    "$env:LOCALAPPDATA\Packages\SAMSUNGELECTRONICSCoLtd.MultiControl_wyx1vj98g3asy\LocalState",
    "$env:LOCALAPPDATA\Packages\SAMSUNGELECTRONICSCoLtd.SamsungMyDevices_wyx1vj98g3asy\LocalState"
)
foreach ($d in $dirs) {
    if (Test-Path $d) {
        foreach ($f in @("TestEnable.MC", "TestGCE.MC", "TestFamily.MC")) {
            $fp = Join-Path $d $f
            if (!(Test-Path $fp)) { New-Item -ItemType File -Path $fp -Force | Out-Null }
        }
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

# 4. Verify WCF NetTcpPortSharing service
try {
    $portSharing = Get-Service -Name "NetTcpPortSharing" -ErrorAction SilentlyContinue
    if ($portSharing -and $portSharing.Status -ne "Running") {
        Start-Service -Name "NetTcpPortSharing" -ErrorAction SilentlyContinue
    }
} catch {}
