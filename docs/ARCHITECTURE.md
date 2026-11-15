# Architecture & Technical Deep Dive

## Overview

**Galaxy Connect Enabler** overcomes hardware whitelists imposed by Samsung's Windows 11 cross-device software stack. Specifically, it resolves restrictions that prevent **Multi Control**, **Nearby Devices (Galaxy Connect)**, and **Samsung Continuity Service** from operating on non-Samsung PCs and non-Intel/Qualcomm hardware (such as AMD Ryzen processors paired with MediaTek or Realtek Wi-Fi and Bluetooth controllers).

---

## 1. Samsung Continuity Service (`WindowsMCFCore`)

### The Architecture
Samsung Continuity runs as an AppX background service (`SAMSUNGELECTRONICSCoLtd.SamsungContinuityService`). The core engine is `WindowsMCFCore.exe`, supported by `Commons.dll`.

### The Wi-Fi Whitelist Mechanism
On startup, `WindowsMCFCore` initializes its device support subsystems through `MCFCommons.Helpers.DriverHelper.DeviceSupportHelper.HasSupportedWiFi(bool isSamsung)`.

Decompiling the MSIL bytecode reveals:
```csharp
public static bool HasSupportedWiFi(bool isSamsung)
{
    List<DriverDeviceInfo> networkDrivers = DeviceDriverInfoHelper.GetNetworkDrivers();
    if (networkDrivers.Count == 0)
    {
        Log.Write("No Wi-Fi driver found");
        return false;
    }

    MachineType currentMachineType = MachineDetailsHelper.GetCurrentMachineType();

    // Whitelist Bypass Condition:
    if (!isSamsung || currentMachineType == MachineType.Desktop)
    {
        Log.Write(string.Format("All WiFi Drivers are supported for Non-Samsung PC || Desktop PC. Device Type: {0}", currentMachineType));
        return true;
    }

    // Strict Samsung Laptop Check (Intel and Qualcomm only)
    foreach (var driver in networkDrivers)
    {
        if (driver.Vendor == ChipsetManufacturer.Intel)
        {
            // Verify driver version requirement
            if (Version.TryParse(driver.DriverVersion, out Version v) && v >= RequiredIntelVersion)
                return true;
        }
        else if (driver.Vendor == ChipsetManufacturer.Qualcomm)
        {
            return true;
        }
        else
        {
            Log.Write(string.Format("Non Supporting Wi-Fi vendor: {0}", driver.Vendor));
        }
    }

    Log.Write("No Supported Wi-Fi driver found");
    return false;
}
```

### The MachineType SMBIOS Resolution
`MachineDetailsHelper.GetCurrentMachineType()` resolves the chassis/enclosure type directly from the registry:
```csharp
public static MachineType GetCurrentMachineType()
{
    using (RegistryKey biosKey = Registry.LocalMachine.OpenSubKey(@"HARDWARE\DESCRIPTION\System\BIOS"))
    {
        if (biosKey != null)
        {
            object val = biosKey.GetValue("EnclosureType");
            if (val != null)
            {
                return (MachineType)(int)val;
            }
        }
        return MachineType.Unknown;
    }
}
```

The enum values correspond to standard SMBIOS Type 3 enclosure kinds:
- `3` = `Desktop`
- `10` = `Notebook`
- `13` = `AllInOne`
- `30` = `Tablet`
- `31` = `Convertible`
- `32` = `Detachable`

### Why Desktop Enclosure (`EnclosureType = 3`) Works
By setting `HKLM:\HARDWARE\DESCRIPTION\System\BIOS\EnclosureType` to `3` (DWORD):
1. `GetCurrentMachineType()` returns `MachineType.Desktop`.
2. `HasSupportedWiFi(isSamsung = true)` satisfies `currentMachineType == MachineType.Desktop`.
3. The engine logs `"All WiFi Drivers are supported for Non-Samsung PC || Desktop PC"` and immediately returns `true`.
4. MediaTek (MT7921, MT7922), Realtek (RTL8852), and AMD RZ-series Wi-Fi cards are fully whitelisted.
5. `SystemManufacturer` can remain `"SAMSUNG ELECTRONICS CO., LTD."` permanently.

---

## 2. Multi Control & P2P Handoff

### OEM Validation (`OEMHelper.cs`)
Multi Control (`SamsungMultiControl.exe`) verifies the manufacturer through `EasClientDeviceInformation`:
```csharp
public static bool IsSamsungPC()
{
    string manufacturer = EasClientDeviceInformation.SystemManufacturer;
    bool isSamsung = string.Equals(manufacturer, "SAMSUNG ELECTRONICS CO., LTD.", StringComparison.OrdinalIgnoreCase)
                  || string.Equals(manufacturer, "Samsung", StringComparison.OrdinalIgnoreCase);

    if (OEMHelper.IsTestNotSamsungMode()) return false;
    if (OEMHelper.IsTestMode()) return true;
    return isSamsung;
}
```

### The `FamilyMDE` Requirement
When Multi Control searches for companion Galaxy devices, it queries `GetFamilyMDESettings()`:
```csharp
public static int GetFamilyMDESettings()
{
    int settings = RegistryHelper.GetUserDWord(@"Software\SAMSUNG\SamsungContinuityService\FamilyMDE", "Settings");
    if (settings == 0)
        settings = RegistryHelper.GetCurrentUserDWord(@"Software\SAMSUNG\SamsungContinuityService\FamilyMDE", "Settings");
    return settings;
}
```
If `FamilyMDE\Settings` is not set to `1`, Multi Control drops P2P Wi-Fi Direct and LAN pairing sessions.

### Engineering Test Flags
Samsung implements file-based test flags checked via `LocalState` paths:
- `TestEnable.MC`: Overrides `IsTestMode()` $\rightarrow$ `IsSamsungPC() = true`
- `TestGCE.MC`: Overrides `IsTestGCEMode()` $\rightarrow$ `IsSupportGCE() = true`
- `TestFamily.MC`: Overrides `IsTestFamilyMode()` $\rightarrow$ `IsSupportFamily() = true`

Deploying these files to `%LOCALAPPDATA%\Packages\SAMSUNGELECTRONICSCoLtd.MultiControl_*\LocalState\` and `SamsungMyDevices_*\LocalState\` forces the internal engine to enable cross-device features.

---

## 3. Location & Proximity Permissions

Windows 11 enforces permission controls over background Bluetooth and Wi-Fi beacon scanning through `CapabilityAccessManager`.

Samsung apps (`SamsungAccount`, `SamsungMyDevices`, `MultiControl`, `SamsungQuickShare`, `SamsungFind`) require permission under:
- `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location`
- `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\bluetoothSync`
- `HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\radios`

Setting `Value = "Allow"` for each Samsung package family and `NonPackaged` desktop applications eliminates the "Location permission is required" prompt and allows automatic BLE discovery of Galaxy phones, tablets, and buds.


---

## 4. Hardware Detection & Galaxy Book Enabler Interoperability

### Dynamic Hardware Auditing
Rather than applying a rigid one-size-fits-all spoof, Galaxy Connect Enabler inspects the host platform dynamically:
1. **CPU Identification**: Queries `Win32_Processor` for vendor (AMD Ryzen vs Intel vs Qualcomm ARM64). Selects the optimal Galaxy Book model (e.g. `Galaxy Book6 Pro` for AMD/Intel, `Galaxy Book4 Edge` for ARM64).
2. **Wi-Fi Chipset Inspection**: Identifies network controllers via `Get-NetAdapter`. If a non-Intel chipset (MediaTek, Realtek, Qualcomm, AMD RZ series) is detected on a laptop chassis, the engine automatically selects `EnclosureType = 0x03` to neutralize the Intel-only laptop check in `Commons.dll`.
3. **Physical Enclosure Inspection**: Queries `Win32_SystemEnclosure.ChassisTypes` to identify whether the machine is physically a laptop, convertible, or desktop.

### Interoperability with Galaxy Book Enabler (GBE)
Galaxy Connect Enabler operates in two flexible modes:
- **Standalone Mode**: Provides complete boot persistence (`GalaxyConnectEnabler-Boot` scheduled task) and logon maintenance (`SamsungEcosystemSync.ps1` via `HKCU Run`).
- **GBE Companion Mode**: When Galaxy Book Enabler is present (`$env:USERPROFILE\.galaxy-book-enabler`):
  - Automatically synchronizes with GBE by patching `GalaxyBookSpoof.bat` to replace `EnclosureType = 0x0A` with `0x03`.
  - Injects `FamilyMDE` into the boot routine.
  - Ensures both tools complement each other: Galaxy Book Enabler provides store app installation and spoofing for Samsung Notes/Settings, while Galaxy Connect Enabler ensures Multi Control, Nearby Devices, and MediaTek/Realtek Wi-Fi compatibility remain intact across reboots.
