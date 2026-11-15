<div align="center">

# 🌌 Galaxy Connect Enabler
### Universal Samsung Cross-Device Ecosystem for ANY Windows 11 PC

[![GitHub Release](https://img.shields.io/github/v/release/Chiragsd13/GalaxyConnectEnabler?color=blue&label=Release&logo=github)](https://github.com/Chiragsd13/GalaxyConnectEnabler/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%2011%20(x64%20%7C%20ARM64)-0078D6.svg?logo=windows)](https://microsoft.com)
[![Hardware](https://img.shields.io/badge/Hardware-AMD%20Ryzen%20%7C%20Intel%20%7C%20Snapdragon-ED8B00.svg)](docs/COMPATIBILITY.md)
[![Wi-Fi](https://img.shields.io/badge/Wi--Fi-MediaTek%20%7C%20Realtek%20%7C%20Qualcomm%20%7C%20Intel-green.svg)](docs/COMPATIBILITY.md)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/Chiragsd13/GalaxyConnectEnabler/pulls)

**Unlock Samsung Multi Control, Nearby Devices (Galaxy Connect), Storage Share, Second Screen, and Continuity on any non-Samsung laptop or desktop — with native support for AMD Ryzen processors and MediaTek, Realtek, or Qualcomm Wi-Fi & Bluetooth controllers.**

[Quick Start](#-quick-start) • [The Discovery](#-the-breakthrough--how-it-works) • [Supported Features](#-features-enabled) • [Compatibility](#-hardware-compatibility) • [Troubleshooting](#-troubleshooting--faq)

---

</div>

## 💡 Why This Project Exists

Samsung builds one of the best multi-device ecosystems in the world — seamless mouse and keyboard sharing (**Multi Control**), device discovery panels (**Nearby Devices / Galaxy Connect**), wireless file browsing (**Storage Share**), and tablet display expansion (**Second Screen**).

However, Samsung locks these features behind an **artificial hardware whitelist**:
1. **The Laptop Wi-Fi Whitelist**: If a PC is spoofed as a Samsung laptop, Samsung's background continuity service (`WindowsMCFCore.exe`) scans the network interface and throws `Non Supporting Wi-Fi vendor`, completely disabling features on laptops equipped with **MediaTek** (e.g. MT7921, MT7922, AMD RZ608/RZ616), **Realtek** (RTL8852AE/BE/CE), or **Qualcomm** Wi-Fi.
2. **The OEM Identity Lock**: If unspoofed or left as Lenovo/ASUS/Dell/HP/Acer, the Samsung Multi Control app refuses to establish cross-device P2P connections.
3. **The User Session P2P Lock**: Even when spoofed at the machine level (`HKLM`), UWP apps check user-level registry (`HKCU:\Software\SAMSUNG\SamsungContinuityService\FamilyMDE`). Missing this key causes immediate disconnection after discovery.

**Galaxy Connect Enabler permanently eliminates all three locks with 1-click automation.**

---

## 🔬 The Breakthrough & How It Works

By reverse-engineering Samsung Continuity's `Commons.dll` (`MCFCommons.Helpers.DriverHelper.DeviceSupportHelper.HasSupportedWiFi`), we uncovered how Samsung determines hardware eligibility:

```csharp
MachineType currentMachineType = MachineDetailsHelper.GetCurrentMachineType();
if (!isSamsung || currentMachineType == MachineType.Desktop)
{
    // "All WiFi Drivers are supported for Non-Samsung PC || Desktop PC"
    return true;
}
```

### The Mechanism:
1. **Desktop Enclosure Bypass (`EnclosureType = 0x03`)**:
   Samsung **only** restricts Wi-Fi card models on *laptops* (`EnclosureType = 10` or `31`). On **Desktop PCs (`EnclosureType = 3`)**, Samsung Continuity **explicitly whitelists ALL Wi-Fi and Bluetooth controllers** regardless of vendor!
2. **FamilyMDE Cross-Device P2P Activation (`Settings = 1`)**:
   Enables peer-to-peer device discovery in both `HKLM` and `HKCU` so user-level UWP apps can initiate and maintain connections.
3. **Engineering Telemetry Flags**:
   Deploys `TestEnable.MC`, `TestGCE.MC`, and `TestFamily.MC` into package `LocalState` stores to force-enable Multi Control UI elements.
4. **WCF Net.Tcp Port Sharing & Location Services**:
   Starts and sets `NetTcpPortSharing` (used for internal IPC on port `49200`) and `lfsvc` (Windows Geolocation Service required for BLE proximity scans) to Automatic.
5. **Universal Firewall Configuration**:
   Configures inbound Windows Firewall rules for UDP discovery (`1900, 3702, 5353, 5355`) and TCP streaming (`49200-49202, 8080, 8443`) across **ALL network profiles** (`Domain`, `Private`, and `Public`).
6. **Dual-Layer Boot Persistence**:
   - **Boot Task**: Runs at startup as `NT AUTHORITY\SYSTEM` to ensure spoofed BIOS keys persist after Windows hardware scans.
   - **User Logon Sync**: Runs via `HKCU Run` and Task Scheduler on logon to ensure `HKCU` keys, permissions, and test flags remain active.

---

## 🚀 Quick Start

### Method 1: Download Release (Recommended)
1. Download the latest `GalaxyConnectEnabler-v1.1.0.zip` from [Releases](https://github.com/Chiragsd13/GalaxyConnectEnabler/releases).
2. Extract the ZIP to any folder.
3. Right-click **`Enable-GalaxyConnect.bat`** and select **Run as administrator**.
4. That's it! Nearby Devices and Multi Control will launch automatically and persist across reboots.

### Method 2: Git Clone
```powershell
git clone https://github.com/Chiragsd13/GalaxyConnectEnabler.git
cd GalaxyConnectEnabler
.\Enable-GalaxyConnect.bat
```

### Method 3: PowerShell One-Liner (PowerShell 7 / Admin)
```powershell
irm https://raw.githubusercontent.com/Chiragsd13/GalaxyConnectEnabler/main/scripts/Enable-GalaxyConnect.ps1 | iex
```

---

## 📱 Features Enabled

| Feature | Description | Status |
|---|---|:---:|
| **Samsung Multi Control** | Seamless mouse, keyboard, and clipboard sharing between your PC, Galaxy Tablet, and Galaxy Phone. | ✅ Working |
| **Galaxy Connect (Nearby Devices)** | Real-time device discovery bubble, battery indicators, and quick connection launcher. | ✅ Working |
| **Storage Share** | Wireless File Explorer integration to browse Galaxy mobile files directly on Windows. | ✅ Working |
| **Second Screen** | High-definition wireless display extension/mirroring to Galaxy Tab. | ✅ Working |
| **Quick Share** | High-speed peer-to-peer file transfer between Windows and Samsung devices. | ✅ Working |
| **Samsung Notes** | Live cloud synchronization with Samsung Cloud. | ✅ Working |
| **Camera Sharing** | Use your Galaxy phone as a high-quality wireless webcam. | ✅ Working |
| **Location Permission Bypass** | Permanently silences the Windows 11 *"Turn on Location in Windows Settings"* banner. | ✅ Fixed |

---

## 💻 Hardware Compatibility

Tested and confirmed working on major non-Samsung laptop and desktop configurations:

### Processors:
- **AMD Ryzen**:
  - Ryzen 5000 Series (Barcelo, Cezanne, Lucienne)
  - Ryzen 6000 / 7000 Series (Rembrandt, Phoenix, Raphael)
  - Ryzen 8000 Series (Hawk Point)
  - Ryzen AI 300 Series (Strix Point)
- **Intel**: 10th Gen to 15th Gen Core / Core Ultra (Arrow Lake, Meteor Lake, Raptor Lake, Alder Lake)
- **Qualcomm Snapdragon**: Snapdragon X Elite / Plus (ARM64)

### Wi-Fi & Bluetooth Controllers:
- **MediaTek**: MT7921 (Wi-Fi 6), MT7922 (Wi-Fi 6E), MT7925 (Wi-Fi 7), AMD RZ608, AMD RZ616
- **Realtek**: RTL8852AE, RTL8852BE, RTL8852CE, RTL8821CE, RTL8822CE
- **Qualcomm**: FastConnect 6800, 6900, 7800
- **Intel**: AX200, AX201, AX210, AX211, BE200

---

## 🧰 Included Tools

- **`Enable-GalaxyConnect.bat`**: One-click installer with automatic UAC elevation.
- **`Check-Status.bat`**: Comprehensive diagnostic scanner that audits BIOS values, FamilyMDE registry, LocalState flags, background services, firewall rules, paired Bluetooth devices, and connected device caches.
- **`Disable-GalaxyConnect.bat`**: Complete uninstaller that restores your factory BIOS settings from automatic backup (`%LOCALAPPDATA%\GalaxyConnectEnabler\original-bios.json`) and removes all persistence tasks.

---

## ❓ Troubleshooting & FAQ

### 1. Devices not detected or Multi Control disconnects after 1 second
- **Keep Screen On & Unlocked**: Galaxy devices sleep their BLE proximity beacons when locked. Unlock your phone or tablet.
- **Check Mobile Settings**: Ensure **Settings > Connected devices > Multi control** and **Continue apps on other devices** are both turned **ON**.
- **Campus / Public Wi-Fi (AP Isolation)**: If connected to university Wi-Fi (e.g. `uvic.ca`, `eduroam`) or public Wi-Fi, routers block local peer-to-peer traffic.
  - **Solution**: Turn on **Mobile Hotspot** on your phone/tablet and connect your laptop to it for instantaneous direct connection!
- **Run Diagnostic**: Run `Check-Status.bat` to see exactly which component needs attention.

Detailed solutions for edge cases are documented in [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

---

## 📄 Documentation

- 📐 [Architecture & Reverse-Engineering Technical Deep Dive](docs/ARCHITECTURE.md)
- 📊 [Complete Hardware Compatibility Matrix](docs/COMPATIBILITY.md)
- 🔧 [Troubleshooting & AP Isolation Guide](docs/TROUBLESHOOTING.md)

---

## 🤝 Contributing & Community

Contributions, issue reports, and hardware compatibility confirmations are welcome!
- **Issues**: [GitHub Issues](https://github.com/Chiragsd13/GalaxyConnectEnabler/issues)
- **Discussions**: Inspired by and contributed to [Bananz0/GalaxyBookEnabler Issue #100](https://github.com/Bananz0/GalaxyBookEnabler/issues/100).

## ⚖️ License

Distributed under the [MIT License](LICENSE).
Author: **Chirag** ([@Chiragsd13](https://github.com/Chiragsd13))
