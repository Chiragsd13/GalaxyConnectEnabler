# ==============================================================================
# Galaxy Connect Enabler - User Logon Sync Worker
# Runs silently on user login to maintain FamilyMDE, test flags, and permissions
# ==============================================================================

# 1. Ensure FamilyMDE Settings in HKCU
$mde = "HKCU:\Software\SAMSUNG\SamsungContinuityService\FamilyMDE"
if (!(Test-Path $mde)) { New-Item -Path $mde -Force | Out-Null }
Set-ItemProperty -Path $mde -Name "Settings" -Value 1 -Type DWord -Force

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
