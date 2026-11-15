<div align="center">

# 🌌 Galaxy Connect Enabler
### Universal Samsung Cross-Device Ecosystem for ANY Windows 11 PC

[![GitHub Release](https://img.shields.io/github/v/release/Chiragsd13/GalaxyConnectEnabler?color=blue&label=Release&logo=github)](https://github.com/Chiragsd13/GalaxyConnectEnabler/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%2011%20(x64%20%7C%20ARM64)-0078D6.svg?logo=windows)](https://microsoft.com)
[![Hardware](https://img.shields.io/badge/Hardware-AMD%20Ryzen%20%7C%20Intel%20%7C%20Snapdragon-ED8B00.svg)](docs/COMPATIBILITY.md)
[![Wi-Fi](https://img.shields.io/badge/Wi--Fi-MediaTek%20%7C%20Realtek%20%7C%20Qualcomm%20%7C%20Intel-green.svg)](docs/COMPATIBILITY.md)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/Chiragsd13/GalaxyConnectEnabler/pulls)

**An intelligent hardware-detecting enabler that transforms any non-Samsung PC into a full Galaxy Ecosystem device — seamlessly unlocking Multi Control, Nearby Devices (Galaxy Connect), Storage Share, Second Screen, and Samsung Continuity.**

*Works as a 100% standalone tool OR in seamless companion mode with [Galaxy Book Enabler](https://github.com/Bananz0/GalaxyBookEnabler).*

[Quick Start](#-quick-start) • [How It Works](#-how-the-magic-works) • [Hardware Detection](#-hardware-detection-engine) • [GBE Interoperability](#-coexistence-with-galaxy-book-enabler) • [Features](#-features-enabled) • [Troubleshooting](#-troubleshooting--faq)

---

</div>

## 💡 Why This Project Exists

Samsung's multi-device software stack — **Multi Control** (keyboard/mouse sharing across PC, phone, and tablet), **Nearby Devices** (proximity status & connect bubble), **Storage Share** (wireless File Explorer browsing), and **Second Screen** — is artificial-hardware whitelisted:

1. **The Laptop Wi-Fi Whitelist**: If a machine identifies as a Samsung laptop, Samsung's continuity service (`WindowsMCFCore.exe`) scans the network interface and throws `Non Supporting Wi-Fi vendor`, intentionally rejecting laptops with **MediaTek** (MT7921, MT7922, AMD RZ608/RZ616), **Realtek** (RTL8852AE/BE/CE), or **Qualcomm** Wi-Fi.
2. **The OEM Identity Lock**: If unspoofed or left as Lenovo, ASUS, HP, Dell, or Acer, Samsung Multi Control refuses to connect.
3. **The User Session P2P Lock**: Even when spoofed in machine hives (`HKLM`), user-level UWP apps check `HKCU:\Software\SAMSUNG\SamsungContinuityService\FamilyMDE`. Missing this in `HKCU` or user SIDs causes instant disconnection after discovery.

**Galaxy Connect Enabler detects your exact hardware, identifies the roadblocks, and applies the targeted bypasses automatically.**

---

## 🔍 Hardware Detection Engine

When you run `Enable-GalaxyConnect.bat` or `Check-Status.bat`, the engine first audits your machine:

```
=================================================================
              GALAXY CONNECT ENABLER (v1.2.0)
    Intelligent Hardware Detection & Ecosystem Integration Engine
=================================================================

[Phase 1] Detecting System Hardware & Environment...
-----------------------------------------------------------------
  HARDWARE AUDIT REPORT:
  • Processor     : AMD Ryzen 5 7530U with Radeon Graphics (x64)
  • Wi-Fi Adapter : MediaTek Wi-Fi 6 MT7921 Wireless LAN Card [MediaTek]
  • Bluetooth     : MediaTek Bluetooth Adapter
  • OEM System    : LENOVO 82XX (Chassis: 31)
  • Motherboard   : LENOVO LNVNB161216
  • Interop Mode  : GalaxyBookEnabler Detected (Coexistence Mode)
-----------------------------------------------------------------
```

### What It Inspects:
- **CPU Architecture & Vendor**: AMD Ryzen, Intel Core, Qualcomm Snapdragon ARM64.
- **Wi-Fi Chipset**: Vendor identification (MediaTek, Realtek, Qualcomm, Intel).
- **Bluetooth Adapter**: Verifies BLE 5.0+ extended advertising capability.
- **Physical Chassis**: Laptop/Convertible (`ChassisTypes 8, 9, 10, 14, 30, 31, 32`) vs Desktop.
- **Ecosystem Check**: Checks for Galaxy Book Enabler, active services, and Samsung apps.

---

## 🔬 How "The Magic" Works

Based on the hardware audit, the engine calculates and executes the optimal strategy:

### 1. Reverse-Engineered Desktop Enclosure Bypass (`0x03`)
Decompiled `MCFCommons.Helpers.DriverHelper.DeviceSupportHelper.HasSupportedWiFi(bool isSamsung)` in `Commons.dll`:

```csharp
MachineType currentMachineType = MachineDetailsHelper.GetCurrentMachineType();
if (!isSamsung || currentMachineType == MachineType.Desktop)
{
    // "All WiFi Drivers are supported for Non-Samsung PC || Desktop PC"
    return true;
}
```
Samsung **only** restricts Wi-Fi vendors on *laptops* (`EnclosureType = 10` or `31`). On **Desktop PCs (`EnclosureType = 3`)**, Samsung Continuity **explicitly whitelists ALL Wi-Fi and Bluetooth controllers**!
The engine sets `EnclosureType = 3` so MediaTek and Realtek Wi-Fi are immediately accepted without driver errors.

### 2. Multi-Hive Cross-Device P2P Activation (`FamilyMDE = 1`)
Samsung Continuity's `OEMHelper.GetFamilyMDESettings()` checks `HKCU`, `HKLM`, and `HKEY_USERS\<UserSID>\Software\SAMSUNG\SamsungContinuityService\FamilyMDE`. The engine enforces `Settings = 1` across all hives so both system background services and user-level UWP apps maintain steady P2P streams.

### 3. WCF Port Sharing & BLE Geolocation
- Starts and enables `NetTcpPortSharing` (WCF Net.Tcp port `49200` used by Samsung Continuity IPC).
- Enables `lfsvc` (Windows Geolocation Service required for BLE proximity scans).

### 4. Location & Radio Privacy Consent
Automatically grants `Allow` in Windows 11 CapabilityAccessManager (`location`, `bluetoothSync`, `radios`) for all Samsung packages and desktop processes — permanently eliminating *"Turn on Location in Windows Settings"* banners.

### 5. Universal Multi-Profile Firewall Rules
Opens inbound UDP discovery (`1900, 3702, 5353, 5355`) and TCP streaming (`49200-49202, 8080, 8443`) on **ALL network profiles** (`Domain`, `Private`, and `Public`), ensuring cross-device features work even on public and campus Wi-Fi networks.

---

## 🤝 Coexistence with Galaxy Book Enabler

Galaxy Connect Enabler is designed to work in two modes:

1. **Standalone Mode**: If you only want Multi Control, Nearby Devices, Continuity, and Storage Share, it operates completely standalone with its own boot persistence and automatic backup.
2. **Companion Mode (with Galaxy Book Enabler)**: If you already use or want to use [Bananz0/GalaxyBookEnabler](https://github.com/Bananz0/GalaxyBookEnabler) for apps like Samsung Notes, Samsung Settings, and Quick Share:
   - Galaxy Connect Enabler detects GBE automatically.
   - It patches `GalaxyBookSpoof.bat` to preserve `EnclosureType = 0x03` and injects `FamilyMDE`.
   - This prevents GBE from reverting your enclosure to a laptop (`10`) and breaking Multi Control / MediaTek Wi-Fi.
   - Both tools work together in complete harmony!

---

## 🚀 Quick Start

### Method 1: Download Release (Recommended)
1. Download `GalaxyConnectEnabler-v1.2.0.zip` from [Releases](https://github.com/Chiragsd13/GalaxyConnectEnabler/releases).
2. Extract the archive.
3. Right-click **`Enable-GalaxyConnect.bat`** and select **Run as administrator**.

### Method 2: Git Clone
```powershell
git clone https://github.com/Chiragsd13/GalaxyConnectEnabler.git
cd GalaxyConnectEnabler
.\Enable-GalaxyConnect.bat
```

### Method 3: Hardware Detection Only (No Changes)
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\Enable-GalaxyConnect.ps1 -DetectOnly
```

---

## 📱 Features Enabled

| Feature | Description | Status |
|---|---|:---:|
| **Samsung Multi Control** | Control your Galaxy phone/tablet with your PC keyboard & mouse, with shared clipboard. | ✅ Working |
| **Galaxy Connect (Nearby Devices)** | Live device status bubble, battery levels, and instant pairing tray. | ✅ Working |
| **Storage Share** | Direct File Explorer access to files on your Galaxy phone or tablet over Wi-Fi. | ✅ Working |
| **Second Screen** | Low-latency wireless monitor extension to Galaxy Tab. | ✅ Working |
| **Quick Share** | Native wireless file transfer between Windows and Samsung devices. | ✅ Working |
| **Samsung Notes** | Direct cloud synchronization with Samsung Cloud. | ✅ Working |
| **Camera Sharing** | Use your Galaxy phone as a wireless high-res webcam. | ✅ Working |
| **Location Permission Bypass** | Automatically clears the Windows 11 location requirement. | ✅ Fixed |

---

## 💻 Hardware Compatibility

- **Processors**: AMD Ryzen (5000 / 6000 / 7000 / 8000 / AI 300 Series), Intel Core (10th to 15th Gen / Core Ultra), Qualcomm Snapdragon X Elite / Plus (ARM64).
- **Wi-Fi Controllers**: MediaTek (MT7921, MT7922, MT7925, AMD RZ608/RZ616), Realtek (RTL8852AE/BE/CE, RTL8821CE/8822CE), Qualcomm (FastConnect), Intel (AX200, AX201, AX210, AX211, BE200).

---

## 🧰 Included Tools

- **`Enable-GalaxyConnect.bat`**: Self-elevating 1-click launcher that runs hardware detection and applies all ecosystem fixes.
- **`Check-Status.bat`**: Audits hardware profile, spoof status, FamilyMDE, LocalState flags, background services, firewall rules, and paired devices.
- **`Disable-GalaxyConnect.bat`**: Clean uninstaller that restores factory BIOS values from `%LOCALAPPDATA%\GalaxyConnectEnabler\original-bios.json`.

---

## ❓ Troubleshooting & FAQ

- **Devices not detected?** Keep your phone or tablet screen unlocked and awake during pairing; Galaxy devices throttle BLE discovery beacons when in deep sleep.
- **Campus or Public Wi-Fi?** Networks like `uvic.ca` or `eduroam` enforce AP isolation. Turn on **Mobile Hotspot** on your phone/tablet and connect your laptop to it for instant low-latency connection.
- Detailed troubleshooting steps are available in [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

---

## 📄 Documentation

- 📐 [Architecture & Reverse-Engineering Technical Deep Dive](docs/ARCHITECTURE.md)
- 📊 [Complete Hardware Compatibility Matrix](docs/COMPATIBILITY.md)
- 🔧 [Troubleshooting & AP Isolation Guide](docs/TROUBLESHOOTING.md)

---

## ⚖️ License & Community

Distributed under the [MIT License](LICENSE).  
Author: **Chirag** ([@Chiragsd13](https://github.com/Chiragsd13))  
Companion & contribution to [Bananz0/GalaxyBookEnabler](https://github.com/Bananz0/GalaxyBookEnabler) (PR [#137](https://github.com/Bananz0/GalaxyBookEnabler/pull/137)).
